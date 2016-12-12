require 'sidekiq'
require 'routemaster/client/backends/sidekiq/worker'

module Routemaster::Client::Backends
  class Sidekiq
    @queue = :realtime

    class << self
      def configure(options)
        new(options)
      end
    end

    def initialize(options)
      @_options = options
    end

    def send_event(event, topic, callback, timestamp = nil)
      Worker.perform_async(event, topic, callback, timestamp, @_options)
    end
  end
end
