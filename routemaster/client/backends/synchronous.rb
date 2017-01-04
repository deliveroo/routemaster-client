require 'routemaster/client/connection'

module Routemaster
  module Client
    module Backends
      class Synchronous
        class << self
          extend Forwardable
          def_delegator :'Routemaster::Client::Connection', :send_event
        end
      end
    end
  end
end
