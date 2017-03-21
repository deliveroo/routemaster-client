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
            options = args.last.kind_of?(Hash) ? args.pop.symbolize_keys : {}
            Routemaster::Client::Connection.send_event(*args, **options)
          end
        end
      end
    end
  end
end
