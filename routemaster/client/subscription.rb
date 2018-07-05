module Routemaster
  module Client
    class Subscription

      attr_reader :subscriber, :callback, :topics, :events

      def initialize(options)
        @subscriber = options.fetch('subscriber')
        @callback   = options.fetch('callback')
        @max_events = options['max_events']
        @timeout    = options['timeout']
        @topics     = options.fetch('topics')
        @events     = _symbolize_keys options.fetch('events')
      end

      def attributes
        {
          subscriber: @subscriber,
          callback:   @callback,
          max_events: @max_events,
          timeout:    @timeout,
          topics:     @topics,
          events:     @events,
        }
      end

      private

      def _symbolize_keys(h)
        {}.tap do |res|
          h.each { |k,v| res[k.to_sym] = v }
        end
      end
    end
  end
end
