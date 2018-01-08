require 'spec_helper'
require 'routemaster/cli/top_level'
require 'webmock/rspec'

describe Routemaster::CLI::Sub, type: :cli do
  before { allow_bus_pulse 'bus.dev', 's3cr3t' }

  describe 'add' do
    context 'with correct arguments' do
      let(:argv) { %w[sub add https://my-service.dev cats dogs -b bus.dev -t s3cr3t --latency 500] }

      it {
        expect(client).to receive(:subscribe).with(topics: %w[cats dogs], callback: 'https://my-service.dev', uuid: 's3cr3t', timeout: 500)
        perform
      }
    end
  end

  describe 'del' do
    context 'with a list of topics' do
      let(:argv) { %w[sub del cats dogs -b bus.dev -t s3cr3t] }
      it {
        expect(client).to receive(:unsubscribe).with('cats', 'dogs')
        perform
      }
    end

    context 'without arguments' do
      let(:argv) { %w[sub del -b bus.dev -t s3cr3t] }
      it {
        expect(client).to receive(:unsubscribe_all).with(no_args)
        perform
      }
    end
  end

  describe 'list' do
    context 'with correct arguments' do
      let(:argv) { %w[sub list -b bus.dev -t s3cr3t] }
      before {
        allow(client).to receive(:monitor_subscriptions).and_return([
          Routemaster::Client::Subscription.new(
            'subscriber' => 'service--f000-b44r-b44r',
            'callback' => 'https://serviced.dev',
            'topics' => %w[cats dogs],
            'events' => {
              'queued' => 1234
            })
        ])
      }

      it {
        expect(client).to receive(:monitor_subscriptions).with(no_args)
        perform
      }
      it {
        expect { perform }.to change { stdout.string }.to a_string_matching(/service--f000-b44r-b44r/)
      }
    end
  end
end
