module Routemaster
  module Client
    module Backends
      class Sidekiq
        class Configuration
          class << self

            def configure
              yield self
            end

            def queue=(value)
              _sidekiq_options['queue'] = _stringify_symbol(value)
            end

            def backtrace=(value)
              _sidekiq_options['backtrace'] = _stringify_symbol(value)
            end

            def retry=(value)
              _sidekiq_options['retry'] = _stringify_symbol(value)
            end

            def pool=(value)
              _sidekiq_options['pool'] = _stringify_symbol(value)
            end

            def sidekiq_options
              _sidekiq_options.clone
            end

            private

            attr_writer :sidekiq_options

            def _sidekiq_options
              @_sidekiq_options ||= {}
            end

            def _stringify_symbol(value)
              value.is_a?(Symbol) ? value.to_s : value
            end
          end
        end
      end
    end
  end
end
