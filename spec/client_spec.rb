require 'spec_helper'
require 'spec/support/configuration_helper'
require 'routemaster/client'
require 'routemaster/client/backends/sidekiq'
require 'routemaster/topic'
require 'webmock/rspec'
require 'sidekiq/testing'
require 'securerandom'

describe Routemaster::Client do

  reset_config_between_tests!

  let(:options) {{
    url:        'https://bus.example.com',
    uuid:       'john_doe',
    verify_ssl:  false,
  }}
  let(:pulse_response) { 204 }

  subject do
    Routemaster::Client.configure do |config|
      options.each do |key, val|
        config.send(:"#{key}=", val)
      end
    end
  end

  before do
    stub_request(:get, %r{^https://bus.example.com/pulse$}).
      with(basic_auth: [options[:uuid], 'x']).
      to_return(status: pulse_response)
  end

  describe "configure" do
    context 'when connection fails' do
      before do
        stub_request(:any, %r{^https://bus.example.com}).
          with(basic_auth: [options[:uuid], 'x']).
          to_raise(Faraday::ConnectionFailed)
      end

      it 'fails' do
        expect { subject }.to raise_error(Faraday::ConnectionFailed)
      end

      it 'passes if :lazy' do
        options[:lazy] = true
        expect { subject }.not_to raise_error
      end
    end

    context 'when the heartbeat fails' do
      let(:pulse_response) { 500 }

      it 'fails if it does not get a successful heartbeat from the app' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  shared_examples 'an unconfigured async event sender' do
    let(:callback) { 'https://app.example.com/widgets/123' }
    let(:topic)    { 'widgets' }
    let(:perform)  { subject.send(method, topic, callback, **flags) }
    let(:http_status) { nil }

    it 'raises an error' do
      expect { perform }.to raise_error(Routemaster::Client::MissingAsyncBackendError)
    end
  end

  shared_examples 'an event sender' do
    let(:callback) { 'https://app.example.com/widgets/123' }
    let(:topic)    { 'widgets' }
    let(:perform)  { subject.send(event, topic, callback, **flags) }
    let(:http_status) { nil }

    before do
      @stub = stub_request(:post, 'https://bus.example.com/topics/widgets').
        with(basic_auth: [options[:uuid], 'x'])

      @stub.to_return(status: http_status) if http_status
    end

    context 'when the bus responds 200' do
      let(:http_status) { 200 }

      it 'sends the event' do
        perform
        expect(@stub).to have_been_requested
      end

      it 'sends a JSON payload' do
        @stub.with do |req|
          expect(req.headers['Content-Type']).to eq('application/json')
        end
        perform
      end

      it 'fails with a bad callback URL' do
        callback.replace 'http.foo.bar'
        expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
      end

      it 'fails with a non-SSL URL' do
        callback.replace 'http://example.com'
        expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
      end

      it 'fails with a bad topic name' do
        topic.replace 'foo123$bar'
        expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
      end

      it 'returns true' do
        expect(perform).to eq true
      end
    end

    context 'when the bus responds 500' do
      let(:http_status) { 500 }

      it 'raises an exception' do
        expect { perform }.to raise_error(Routemaster::Client::ConnectionError, 'event rejected (status: 500)')
      end
    end

    context 'when the bus times out' do
      before { @stub.to_timeout }

      it 'fails' do
        @stub.to_timeout
        expect { perform }.to raise_error(Faraday::TimeoutError)
      end
    end

    context 'with explicit timestamp' do
      let(:timestamp) { (Time.now.to_f * 1e3).to_i }
      let(:perform)   { subject.send(event, topic, callback, t: timestamp) }

      before do
        @stub = stub_request(:post, 'https://@bus.example.com/topics/widgets').
          with(
            body: { type: anything, url: callback, timestamp: timestamp },
            basic_auth: [options[:uuid], 'x'],
          ).
          to_return(status: 200)
      end

      it 'sends the event' do
        perform
        expect(@stub).to have_been_requested
      end

      context 'with non-numeric timestamp' do
        let(:timestamp) { 'foo' }

        it 'fails' do
          expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
        end
      end

      context 'with non-integer timestamp' do
        let(:timestamp) { 123.45 }

        it 'fails' do
          expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
        end
      end
    end

    context 'with a data payload' do
      let(:timestamp) { (Time.now.to_f * 1e3).to_i }
      let(:perform)   { subject.send(event, topic, callback, data: data) }
      let(:data) {{ 'foo' => 'bar' }}

      before do
        @stub = stub_request(:post, 'https://@bus.example.com/topics/widgets').
          with(
            body: hash_including(data: data),
            basic_auth: [options[:uuid], 'x'],
          ).
          to_return(status: 200)
      end

      it 'sends the event' do
        perform
        expect(@stub).to have_been_requested
      end

      context 'with non-serializable data' do
        let(:data) { [:foo, 'bar'] }

        it 'fails' do
          expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
        end
      end
    end
  end

  context 'without a background worker specified' do
    context 'with default flags' do
      %w[created updated deleted noop].each do |m|
        describe "##{m}" do
          let(:event) { m.to_sym }
          let(:flags) { {} }
          it_behaves_like 'an event sender'
        end
      end
    end

    context 'with the :async flag' do
      %w[created updated deleted noop].each do |m|
        describe "##{m}" do
          let(:method) { m }
          let(:flags) { { async: true } }
          it_behaves_like 'an unconfigured async event sender'
        end
      end
    end

    describe 'deprecated *_async methods' do
      %w[created updated deleted noop].each do |m|
        describe "##{m}_async" do
          let(:method) { "#{m}_async" }
          let(:flags) { {} }
          it_behaves_like 'an unconfigured async event sender'
        end
      end
    end
  end

  context 'with the sidekiq async back end configured' do
    reset_sidekiq_config_between_tests!

    before do
      options[:async_backend] = Routemaster::Client::Backends::Sidekiq.configure do |config|
        config.queue = :realtime
        config.retry = true
      end
    end

    around do |example|
      Sidekiq::Testing.inline! do
        example.run
      end
    end

    context 'with default options' do
      let(:flags) { {} }

      %w[created updated deleted noop].each do |m|
        describe "##{m}" do
          let(:event) { m }
          it_behaves_like 'an event sender'
        end
      end
    end

    context 'with :async option' do
      let(:flags) { { async: true } }

      %w[created updated deleted noop].each do |m|
        describe "##{m}" do
          let(:event) { m }
          it_behaves_like 'an event sender'
        end
      end
    end

    describe 'deprecated *_async methods' do
      %w[created updated deleted noop].each do |m|
        describe "##{m}_async" do
          let(:event) { "#{m}_async" }
          let(:flags) { {} }
          it_behaves_like 'an event sender'
        end
      end
    end
  end

  describe '#subscribe' do
    let(:perform) { subject.subscribe(subscribe_options) }
    let(:subscribe_options) {{
      topics:   %w(widgets kitten),
      callback: 'https://app.example.com/events',
      timeout:  60_000,
      max:      500
    }}

    before do
      @stub = stub_request(:post, 'https://bus.example.com/subscription').
      with(basic_auth: [options[:uuid], 'x']).
      with { |r|
        r.headers['Content-Type'] == 'application/json' &&
        JSON.parse(r.body).all? { |k,v| subscribe_options[k.to_sym] == v }
      }
    end

    it 'passes with correct arguments' do
      expect { perform }.not_to raise_error
      expect(@stub).to have_been_requested
    end

    it 'fails with a bad callback' do
      subscribe_options[:callback] = 'http://example.com'
      expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
    end

    it 'fails with a bad timeout' do
      subscribe_options[:timeout] = -5
      expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
    end

    it 'fails with a bad max number of events' do
      subscribe_options[:max] = 1_000_000
      expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
    end

    it 'fails with a bad topic list' do
      subscribe_options[:topics] = ['widgets', 'foo123$%bar']
      expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
    end

    it 'fails on HTTP error' do
      @stub.to_return(status: 500)
      expect { perform }.to raise_error(Routemaster::Client::ConnectionError, 'subscribe rejected (status: 500)')
    end

    it 'accepts a uuid' do
      subscribe_options[:uuid] = 'hello'
      expect { perform }.not_to raise_error
    end
  end

  describe '#unsubscribe' do
    let(:perform) { subject.unsubscribe(*args) }
    let(:args) {[
      'widgets'
    ]}

    before do
      @stub = stub_request(:delete, %r{https://bus.example.com/subscriber/topics/widgets}).
      with(basic_auth: [options[:uuid], 'x'])
    end

    it 'passes with correct arguments' do
      expect { perform }.not_to raise_error
      expect(@stub).to have_been_requested
    end

    it 'fails with a bad topic' do
      args.replace ['foo123%bar']
      expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
    end

    it 'fails on HTTP error' do
      @stub.to_return(status: 500)
      expect { perform }.to raise_error(Routemaster::Client::ConnectionError, 'unsubscribe rejected (status: 500)')
    end
  end


  describe '#unsubscribe_all' do
    let(:perform) { subject.unsubscribe_all }

    before do
      @stub = stub_request(:delete, %r{https://bus.example.com/subscriber}).
      with(basic_auth: [options[:uuid], 'x'])
    end

    it 'passes with correct arguments' do
      expect { perform }.not_to raise_error
      expect(@stub).to have_been_requested
    end

    it 'fails on HTTP error' do
      @stub.to_return(status: 500)
      expect { perform }.to raise_error(Routemaster::Client::ConnectionError, 'unsubscribe all rejected (status: 500)')
    end
  end

  describe '#delete_topic' do
    let(:perform) { subject.delete_topic(*args) }
    let(:args) {[
      'widgets'
    ]}

    before do
      @stub = stub_request(:delete, %r{https://bus.example.com/topics/widgets}).
      with(basic_auth: [options[:uuid], 'x'])
    end

    it 'passes with correct arguments' do
      expect { perform }.not_to raise_error
      expect(@stub).to have_been_requested
    end

    it 'fails with a bad topic' do
      args.replace ['foo123%bar']
      expect { perform }.to raise_error(Routemaster::Client::InvalidArgumentError)
    end

    it 'fails on HTTP error' do
      @stub.to_return(status: 500)
      expect { perform }.to raise_error(Routemaster::Client::ConnectionError, 'failed to delete topic (status: 500)')
    end
  end


  describe '#monitor_topics' do

    let(:perform) { subject.monitor_topics }
    let(:expected_result) do
      [
        {
          name: 'widgets',
          publisher: 'demo',
          events: 12589
        }
      ]
    end

    context 'the connection to the bus is successful' do
      before do
        @stub = stub_request(:get, 'https://bus.example.com/topics').
          with(basic_auth: [options[:uuid], 'x']).
          with { |r|
          r.headers['Content-Type'] == 'application/json'
        }.to_return {
          { status: 200, body: expected_result.to_json }
        }
      end

      it 'expects a collection of topics' do
        expect(perform.map(&:attributes)).to eql(expected_result)
      end
    end

    context 'the connection to the bus errors' do
      before do
        @stub = stub_request(:get, 'https://bus.example.com/topics').
          with(basic_auth: [options[:uuid], 'x']).
          with { |r|
          r.headers['Content-Type'] == 'application/json'
        }.to_return(status: 500)
      end

      it 'expects a collection of topics' do
        expect { perform }.to raise_error(Routemaster::Client::ConnectionError, 'failed to connect to /topics (status: 500)')
      end
    end

    describe '#reset_connection' do

      context 'can reset class vars to change params' do

        let(:instance_uuid) { SecureRandom.uuid }

        let(:options) {{
          url:        'https://@bus.example.com',
          uuid:       instance_uuid,
          verify_ssl: false,
          lazy: true
        }}

        before do
          Routemaster::Client::Connection.reset_connection
          @stub = stub_request(:get, 'https://@bus.example.com/topics').with({basic_auth: [instance_uuid, 'x']})
            .to_return(status: 200, body: [{ name: "topic.name", publisher: "topic.publisher", events: "topic.get_count" }].to_json)
        end

        after do
          Routemaster::Client::Connection.reset_connection
        end

        it 'connects with new params' do
          subject.monitor_topics
          expect(@stub).to have_been_requested
        end
      end
    end
  end
end
