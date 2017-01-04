## routemaster-client [![Version](https://badge.fury.io/rb/routemaster-client.svg)](https://rubygems.org/gems/routemaster-client) [![Build](https://travis-ci.org/deliveroo/routemaster-client.svg?branch=master)](https://travis-ci.org/deliveroo/routemaster-client) [![Code Climate](https://codeclimate.com/github/deliveroo/routemaster-client/badges/gpa.svg)](https://codeclimate.com/github/deliveroo/routemaster-client) [![Test Coverage](https://codeclimate.com/github/deliveroo/routemaster-client/badges/coverage.svg)](https://codeclimate.com/github/deliveroo/routemaster-client/coverage) [![Docs](http://img.shields.io/badge/API%20docs-rubydoc.info-blue.svg)](http://rubydoc.info/github/deliveroo/routemaster-client/frames/file/README.md)

A Ruby API for the [Routemaster](https://github.com/deliveroo/routemaster) event
bus.



## Installation

Add this line to your application's Gemfile:

    gem 'routemaster-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install routemaster-client

## Usage

**Configure** your client:

```ruby
require 'routemaster/client'
Routemaster::Client.configure do |config|
  config.url = 'https://bs.example.com'
  config.uuid = 'demo'
end
```

You can also specify a timeout value in seconds if you like with the ```timeout``` option.

```ruby
Routemaster::Client.configure do |config|
  config.url = 'https://bs.example.com'
  config.uuid = 'demo'
  config.timeout = 2
end
```

If you are using Sidekiq in your project, you can specify the usage of a Sidekiq backend, where event sending will be processed asynchronously.

```ruby
Routemaster::Client.configure do |config|
  config.url = 'https://bs.example.com'
  config.uuid = 'demo'
  config.timeout = 2
  config.async_backend = Routemaster::Client::Backends::Sidekiq.configure do |sidekiq|
  	sidekiq.queue = :realtime
  	sidekiq.retry = false
  end
end
```

**Push** an event about an entity in the topic `widgets` with a callback URL:

```ruby
Routemaster::Client.created('widgets', 'https://app.example.com/widgets/1')
Routemaster::Client.updated('widgets', 'https://app.example.com/widgets/2')
Routemaster::Client.noop('widgets', 'https://app.example.com/widgets/3')
```

There are methods for the four canonical event types: `created`, `updated`,
`deleted`, and `noop`.

`noop` is typically used when a subscriber is first connected (or reset), and
the publisher floods with `noop`s for all existing entities so subscribers can
refresh their view of the domain.

A timestamp argument may be passed (it will be set by the bus automatically
otherwise); it must be an integer number of milliseconds since the UNIX Epoch:

```ruby
Routemaster::Client.created('widgets', 'https://app.example.com/widgets/1', 1473080555409)
```

**Async**
You can also push events asynchronously if you have an async backend defined, for each
event method there is a corresponding `event_async` method. eg
```ruby
   Routemaster::Client.updated_async('widgets', 'https://app.example.com/widgets/2')
```

You cannot use these methods without defining an async backend, if you try then an error will
be raised.

**Subscribe** to be notified about `widgets` and `kitten` at most 60 seconds after
events, in batches of at most 500 events, to a given callback URL:

```ruby
Routemaster::Client.subscribe(
  topics:   ['widgets', 'kitten'],
  callback: 'https://app.example.com/events',
  uuid:     'demo',
  timeout:  60_000,
  max:      500)
```


**Receive** events at path `/events` using a Rack middleware:

```ruby
require 'routemaster/receiver'

class Listener
  def on_events_received(batch)
    batch.each do |event|
      puts event['url']
    end
  end
end

Wisper.subscribe(Listener.new, :prefix => true)

use Routemaster::Receiver, {
  path:    '/events',
  uuid:    'demo'
}
```

This relies on the excellent event bus from the [wisper
gem](https://github.com/krisleech/wisper#wisper).

**Unsubscribe** from a single topic:

```ruby
Routemaster::Client.unsubscribe('widgets')
```

**Unsubscribe** from all topics:

```ruby
Routemaster::Client.unsubscribe_all
```

**Delete** a topic (only possible if you're the emitter for this topic):

```ruby
Routemaster::Client.delete_topic('widgets')
```


**Monitor** the status of topics and subscriptions:

```ruby
Routemaster::Client.monitor_topics
#=> [ #<Routemaster::Topic:XXXX @name="widgets", @publisher="demo", @events=12589>, ...]

Routemaster::Client.monitor_subscriptions
#=> [ {
#     subscriber: 'bob',
#     callback:   'https://app.example.com/events',
#     topics:     ['widgets', 'kitten'],
#     events:     { sent: 21_450, queued: 498, oldest: 59_603 }
#  } ... ]
```

## Contributing

1. Fork it ( http://github.com/deliveroo/routemaster-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
