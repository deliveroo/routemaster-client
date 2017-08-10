require 'spec_helper'
require 'routemaster/cli/top_level'
require 'webmock/rspec'

describe Routemaster::CLI::Pub, type: :cli do
  before { allow_bus_pulse 'bus.dev', 's3cr3t' }

  context 'with too few arguments' do
    let(:argv) { [] }
    it { expect { perform }.to raise_error(Routemaster::CLI::Exit) }
    it { expect { perform rescue nil }.to change { stderr.string }.to a_string_matching(/Usage/) }
  end

  context 'with correct arguments' do
    let(:argv) { %w[pub created widgets https://example.com/widgets/1 -b bus.dev -t s3cr3t] }
    it { 
      expect(client).to receive(:created).with('widgets', 'https://example.com/widgets/1')
      perform
    }
  end
end
