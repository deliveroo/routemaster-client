require 'spec_helper'
require 'routemaster/cli/top_level'
require 'webmock/rspec'

describe Routemaster::CLI::Token, type: :cli do
  before { allow_bus_pulse 'bus.dev', 's3cr3t' }

  describe 'add' do
    context 'with correct arguments' do
      let(:argv) { %w[token add my-service -b bus.dev -t s3cr3t] }

      it { 
        expect(client).to receive(:token_add).with(name: 'my-service', token: nil)
        perform
      }

      it {
        allow(client).to receive(:token_add).and_return('my-service--dead-0000-beef')
        expect { perform }.to change { stdout.string }.to("my-service--dead-0000-beef\n")
      }
    end
  end

  describe 'del' do
    context 'with correct arguments' do
      let(:argv) { %w[token del my-service--dead-0000-beef -b bus.dev -t s3cr3t] }
      it { 
        expect(client).to receive(:token_del).with(token: 'my-service--dead-0000-beef')
        perform
      }
    end
  end

  describe 'list' do
    context 'with correct arguments' do
      let(:argv) { %w[token list -b bus.dev -t s3cr3t] }
      before {
        allow(client).to receive(:token_list).and_return({ 'service--t0ken' => 'service' })
      }

      it { 
        expect(client).to receive(:token_list).with(no_args)
        perform
      }
      it {
        expect { perform }.to change { stdout.string }.to "service--t0ken\tservice\n"
      }
    end
  end
end
