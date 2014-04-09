require 'spec_helper'
require 'routemaster_client'
require 'webmock/rspec'

describe Routemaster::Client do
  let(:options) {{
    url:  'https://bus.example.com',
    uuid: 'john_doe'
  }}
  subject { described_class.new(options) }

  before do
    stub_request(:get, %r{^https://#{options[:uuid]}:x@bus.example.com/pulse$}).with(status: 200)
  end

  describe '#initialize' do
    it 'passes with valid arguments' do
      expect { subject }.not_to raise_error
    end

    it 'fails with a non-SSL URL' do
      options[:url].sub!(/https/, 'http')
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'fails with a bad URL' do
      options[:url].replace('foobar')
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'fails with a bad client id' do
      options[:uuid].replace('123 $%')
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'fails it it cannot connect' do
      stub_request(:any, %r{^https://#{options[:uuid]}:x@bus.example.com}).to_raise(Faraday::ConnectionFailed)
      expect { subject }.to raise_error
    end

    it 'fails if it does not get a successful heartbeat from the app'
  end

  shared_examples 'an event sender' do
    let(:callback) { 'https://app.example.com/widgets/123' }
    let(:topic) { 'widgets' }
    let(:perform) { subject.send(event, topic, callback) }
    
    before do
      @stub = stub_request(
        :post, "https://#{options[:uuid]}:x@bus.example.com/topics/widgets"
      ).with(status: 200)
    end
    
    it 'sends the event' do
      perform
      @stub.should have_been_requested
    end

    it 'fails with a bad callback URL' do
      callback.replace 'http.foo.bar'
      expect { perform }.to raise_error
    end

    it 'fails with a non-SSL URL' do
      callback.replace 'http://example.com'
      expect { perform }.to raise_error
    end

    it 'fails with a bad topic name' do
      topic.replace 'foo123$bar'
      expect { perform }.to raise_error
    end

    it 'fails when an non-success HTTP status is returned' do
      @stub.to_return(status: 500)
      expect { perform }.to raise_error(RuntimeError)
    end
  end

  describe '#created' do
    let(:event) { 'created' }
    it_behaves_like 'an event sender'
  end

  describe '#updated' do
    let(:event) { 'updated' }
    it_behaves_like 'an event sender'
  end

  describe '#deleted' do
    let(:event) { 'deleted' }
    it_behaves_like 'an event sender'
  end

  describe '#noop' do
    let(:event) { 'noop' }
    it_behaves_like 'an event sender'
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
      @stub = stub_request(
        :post, %r{^https://#{options[:uuid]}:x@bus.example.com/subscription$}
      ).with { |r|
        r.headers['Content-Type'] == 'application/json' &&
        JSON.parse(r.body).all? { |k,v| subscribe_options[k.to_sym] == v }
      }
    end

    it 'passes with correct arguments' do
      expect { perform }.not_to raise_error
      @stub.should have_been_requested
    end

    it 'fails with a bad callback' do
      subscribe_options[:callback] = 'http://example.com'
      expect { perform }.to raise_error(ArgumentError)
    end

    it 'fails with a bad timeout' do
      subscribe_options[:timeout] = -5
      expect { perform }.to raise_error(ArgumentError)
    end

    it 'fails with a bad max number of events' do
      subscribe_options[:max] = 1_000_000
      expect { perform }.to raise_error(ArgumentError)
    end

    it 'fails with a bad topic list' do
      subscribe_options[:topics] = ['widgets', 'foo123$%bar']
      expect { perform }.to raise_error(ArgumentError)
    end

    it 'fails on HTTP error' do
      @stub.to_return(status: 500)
      expect { perform }.to raise_error(RuntimeError)
    end
  end

  describe '#monitor_topics' do
    it 'passes'
  end

  describe '#monitor_scubscriptions' do
    it 'passes'
  end
end

