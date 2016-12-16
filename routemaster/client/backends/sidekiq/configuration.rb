module Routemaster
  class Client
    module Backends
      class Sidekiq
        class Configuration
          class << self

            attr_reader :sidekiq_options

            def configure
              yield self
              self.sidekiq_options = _sidekiq_options.clone
            end

            def queue=(value)
              _sidekiq_options['queue'] = stringify_symbol(value)
            end

            def backtrace=(value)
              _sidekiq_options['backtrace'] = stringify_symbol(value)
            end

            def retry=(value)
              _sidekiq_options['retry'] = stringify_symbol(value)
            end

            def pool=(value)
              _sidekiq_options['pool'] = stringify_symbol(value)
            end

            private

            attr_writer :sidekiq_options

            def _sidekiq_options
              @_sidekiq_options ||= {}
            end

            def stringify_symbol(value)
              value.is_a?(Symbol) ? value.to_s : value
            end
          end
        end
      end
    end
  end
end