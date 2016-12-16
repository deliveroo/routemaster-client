require 'routemaster/client/errors'

module Routemaster
  class Client
    module Backends
      class MissingAsynchronous
        class << self
          def send_event(*)
            raise MissingAsyncBackendError
          end
        end
      end
    end
  end
end
