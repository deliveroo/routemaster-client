require 'routemaster/client/connection'

module Routemaster
  module Client
    module Backends
      class Sidekiq
        class Worker
          include ::Sidekiq::Worker

          def perform(*args)
            # Sidekiq does not have transparent argument serialization.
            # This extracts the options so they can be passed on properly.
            options = args.last.kind_of?(Hash) ? _symbolize_keys(args.pop) : {}
            Routemaster::Client::Connection.send_event(*args, **options)
          end

          private 

          def _symbolize_keys(h)
            {}.tap do |result|
              h.each do |k,v|
                result[k.to_sym] = v
              end
            end
          end
        end
      end
    end
  end
end
