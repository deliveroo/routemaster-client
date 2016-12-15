require 'spec_helper'
require 'routemaster/client/configuration'

describe Routemaster::Client::Configuration do

  before do
    Routemaster::Client.send(:remove_const, :Configuration)
    load 'routemaster/client/configuration.rb'
  end

  describe '#configure' do
    describe 'url' do
      it 'raises an error if url is not defined' do
        configure = -> do
          Routemaster::Client::Configuration.configure do |config|
            config.uuid = 'I_am_a_magical_uuid'
          end
        end

        expected_message = 'url is required'
        expect(&configure).to raise_error Routemaster::Client::MissingAttributeError, expected_message
      end

      it 'raises an error if url is invalid' do
        configure = -> do
          Routemaster::Client::Configuration.configure do |config|
            config.uuid = 'I_am_a_magical_uuid'
            config.url = 'not a proper url at all'
          end
        end

        expected_message = "url 'not a proper url at all' is invalid, must be an https url"
        expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
      end

      it 'raises an error if url is not https' do
        configure = -> do
          Routemaster::Client::Configuration.configure do |config|
            config.uuid = 'I_am_a_magical_uuid'
            config.url = 'http://example.com'
          end
        end

        expected_message = "url 'http://example.com' is invalid, must be an https url"
        expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
      end
    end

    describe 'uuid' do
      it 'raises an error if uuid if not defined' do
        configure = -> do
          Routemaster::Client::Configuration.configure do |config|
            config.url = 'https://example.com'
          end
        end

        expect(&configure).to raise_error Routemaster::Client::MissingAttributeError
      end

      it 'requires an error if uuid is not alphanumeric (plus dashes and underscores)' do
        configure = -> do
          Routemaster::Client::Configuration.configure do |config|
            config.url = 'https://example.com'
            config.uuid = '$$$INVALID'
          end
        end

        expected_message =  "uuid '$$$INVALID' is invalid, must only contain alphanumeric characters " +
          'plus _ and - and be 1 to 64 characters'
        expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
      end
    end

    it "does not raise an error if both uuid and url are defined and are valid" do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://lovely.com'
          config.uuid = 'uiiiiiiidddd'
        end
      end

      expect(&configure).to_not raise_error
    end
  end

  describe 'timeout' do
    it 'raises an error if timeout is not an integer' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://example.com'
          config.uuid = "uiiiiiiidddd"
          config.timeout = 'one'
        end
      end

      expected_message =  "timeout 'one' is invalid, must be an integer between 0 and 3,600,000"
      expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
    end

    it 'raises an error if timeout is too large' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://example.com'
          config.uuid = 'uiiiiiiidddd'
          config.timeout = 1_000_000_000_000_000_000_000_000_000_000_000_000
        end
      end

      expected_message =  "timeout '1000000000000000000000000000000000000' is invalid, must be an integer between 0 and 3,600,000"
      expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
    end

    it 'does not raise an error if the timeout is valid' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://lovely.com'
          config.uuid = 'uiiiiiiidddd'
          config.timeout = 2
        end
      end

      expect(&configure).to_not raise_error
    end

    it 'will default to 5 if not supplied' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://lovely.com'
          config.uuid = 'uiiiiiiidddd'
        end
      end

      expect(&configure).to_not raise_error
      expect(Routemaster::Client::Configuration.timeout).to eq 5
    end
  end

  describe 'lazy' do
    it 'raises an error if lazy is not a boolean' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://example.com'
          config.uuid = 'uiiiiiiidddd'
          config.lazy = 'yes'
        end
      end

      expected_message =  "lazy 'yes' is invalid, must be a boolean value: true or false"
      expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
    end

    it 'does not raise an error if lazy is a boolean' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://example.com'
          config.uuid = 'uiiiiiiidddd'
          config.lazy = true
        end
      end

      expect(&configure).to_not raise_error
      expect(Routemaster::Client::Configuration.lazy).to eq true
    end

    it 'will default to false if not supplied' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://lovely.com'
          config.uuid = 'uiiiiiiidddd'
        end
      end

      expect(&configure).to_not raise_error
      expect(Routemaster::Client::Configuration.lazy).to eq false
    end
  end

  describe 'verify_ssl' do
    it 'raises an error if verify_ssl is not a boolean' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://example.com'
          config.uuid = 'uiiiiiiidddd'
          config.verify_ssl = 'yes'
        end
      end

      expected_message =  "verify_ssl 'yes' is invalid, must be a boolean value: true or false"
      expect(&configure).to raise_error Routemaster::Client::InvalidAttributeError, expected_message
    end

    it 'does not raise an error if verify_ssl is a boolean' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://example.com'
          config.uuid = 'uiiiiiiidddd'
          config.verify_ssl = false
        end
      end

      expect(&configure).to_not raise_error
      expect(Routemaster::Client::Configuration.verify_ssl).to eq false
    end

    it 'will default to true if not supplied' do
      configure = -> do
        Routemaster::Client::Configuration.configure do |config|
          config.url = 'https://lovely.com'
          config.uuid = 'uiiiiiiidddd'
        end
      end

      expect(&configure).to_not raise_error
      expect(Routemaster::Client::Configuration.verify_ssl).to eq true
    end
  end
end
