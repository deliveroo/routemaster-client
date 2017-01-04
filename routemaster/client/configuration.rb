require 'routemaster/client/assertion_helpers'
require 'routemaster/client/errors'
require 'routemaster/client/backends/missing_asynchronous'

module Routemaster
  module Client
    class Configuration
      class << self
        include AssertionHelpers

        DEFAULT_TIMEOUT = 5
        DEFAULT_LAZY = false
        DEFAULT_VERIFY_SSL = true

        attr_accessor :url, :uuid, :timeout, :async_backend, :lazy, :verify_ssl

        def configure
          yield self
          _validate_all_options!
        end

        private

        def _validate_all_options!
          _assert_present! url: url, uuid: uuid
          _assert_valid_url!(url)
          _assert_valid_uuid!(uuid)
          timeout ? _assert_valid_timeout!(timeout) : self.timeout = DEFAULT_TIMEOUT

          lazy.nil? ?  self.lazy = DEFAULT_LAZY : _assert_boolean!(lazy: lazy)
          verify_ssl.nil? ? self.verify_ssl = DEFAULT_VERIFY_SSL : _assert_boolean!(verify_ssl: verify_ssl)
          self.async_backend ||= Backends::MissingAsynchronous
        end

        def _assert_valid_url!(url)
          assert_valid_url_throwing_error!(url, InvalidAttributeError)
        end

        def _assert_valid_uuid!(uuid)
          raise MissingAttributeError, "uuid is required" unless uuid
          unless  uuid =~ /^[a-z0-9_-]{1,64}$/
            message =  "uuid '#{uuid}' is invalid, must only contain alphanumeric characters " +
            "plus _ and - and be 1 to 64 characters"
            raise InvalidAttributeError, message
          end
        end

        def _assert_valid_timeout!(timeout)
          unless (0..3_600_000).include? timeout
            raise InvalidAttributeError, "timeout '#{timeout}' is invalid, must be an integer between 0 and 3,600,000"
          end
        end

        def _assert_boolean!(**kwargs)
          kwargs.each do |name, value|
            unless [true, false].include? value
              raise InvalidAttributeError, "#{name} '#{value}' is invalid, must be a boolean value: true or false"
            end
          end
        end

        def _assert_present!(**kwargs)
          kwargs.each do |name, value|
            raise MissingAttributeError, "#{name} is required" unless value
          end
        end
      end
    end
  end
end
