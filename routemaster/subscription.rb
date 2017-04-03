module Routemaster
  class Subscription

    attr_reader :subscriber, :callback, :topics, :events

    def initialize(options)
      @subscriber = options.fetch('subscriber')
      @callback   = options.fetch('callback')
      @topics     = options.fetch('topics')
      @events     = options.fetch('events').symbolize_keys
    end

    def attributes
      {
        subscriber: @subscriber,
        callback:   @callback,
        topics:     @topics,
        events:     @events
      }
    end
  end
end