require 'spec_helper'
require 'spec/support/configuration_helper'
require 'routemaster/client/backends/sidekiq/configuration'

describe Routemaster::Client::Backends::Sidekiq::Configuration do
  reset_sidekiq_config_between_tests!

  describe '#configure' do

    it 'sets sidekiq_options to empty hash if nothing is specified' do
      Routemaster::Client::Backends::Sidekiq::Configuration.configure {}
      expect(sidekiq_options).to eq({})
    end

    describe 'queue' do
      it 'sets the queue with a string key, and stringifies the value' do
        Routemaster::Client::Backends::Sidekiq::Configuration.configure do |c|
          c.queue = :nice_queue
        end
        expect(sidekiq_options['queue']).to eq 'nice_queue'
      end
    end

    describe 'backtrace' do
      it 'sets the backtrace with a string key' do
        Routemaster::Client::Backends::Sidekiq::Configuration.configure do |c|
          c.backtrace = true
        end
        expect(sidekiq_options['backtrace']).to eq true
      end
    end

    describe 'retry' do
      it 'sets the retry with a string key' do
        Routemaster::Client::Backends::Sidekiq::Configuration.configure do |c|
          c.retry = true
        end
        expect(sidekiq_options['retry']).to eq true
      end
    end

    describe 'pool' do
      it 'sets the pool with a string key' do
        pool = double
        Routemaster::Client::Backends::Sidekiq::Configuration.configure do |c|
          c.pool = pool
        end
        expect(sidekiq_options['pool']).to eq pool
      end
    end

    describe 'sidekiq_options'  do
      it 'cannot be modified after configuration' do
        Routemaster::Client::Backends::Sidekiq::Configuration.configure {}
        Routemaster::Client::Backends::Sidekiq::Configuration.sidekiq_options[:key_that_dont_exist] = 'Weeee'
        expect(Routemaster::Client::Backends::Sidekiq::Configuration.sidekiq_options).to_not have_key(:key_that_dont_exist)
      end
    end
  end
end

def sidekiq_options
  Routemaster::Client::Backends::Sidekiq::Configuration.sidekiq_options
end
