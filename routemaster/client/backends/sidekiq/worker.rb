require 'routemaster/client/connection'

module Routemaster::Client::Backends
  class Sidekiq
    class Worker
      include ::Sidekiq::Worker

      def perform(event, topic, callback, timestamp, options)
        conn = Routemaster::Client::Connection.new(_symbolize_keys(options))
        conn.send_event(event, topic, callback, timestamp)
      end

      private

      def _symbolize_keys(hash)
        Hash[hash.map{|(k,v)| [k.to_sym,v]}]
      end
    end
  end
end
