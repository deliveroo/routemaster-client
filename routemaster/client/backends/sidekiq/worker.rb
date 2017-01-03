require 'routemaster/client/connection'

module Routemaster
  class Client
    module Backends
      class Sidekiq
        class Worker
          include ::Sidekiq::Worker
          extend Forwardable

          def_delegator :'Routemaster::Client::Connection', :send_event
          alias :perform :send_event

          private :send_event
        end
      end
    end
  end
end
