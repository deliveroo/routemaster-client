## routemaster-client [![Version](https://badge.fury.io/rb/routemaster-client.svg)](https://rubygems.org/gems/routemaster-client) [![Build](https://travis-ci.org/deliveroo/routemaster-client.svg?branch=master)](https://travis-ci.org/deliveroo/routemaster-client) [![Code Climate](https://codeclimate.com/github/deliveroo/routemaster-client/badges/gpa.svg)](https://codeclimate.com/github/deliveroo/routemaster-client) [![Test Coverage](https://codeclimate.com/github/deliveroo/routemaster-client/badges/coverage.svg)](https://codeclimate.com/github/deliveroo/routemaster-client/coverage) [![Docs](http://img.shields.io/badge/API%20docs-rubydoc.info-blue.svg)](http://rubydoc.info/github/deliveroo/routemaster-client/frames/file/README.md)

A Ruby API and CLI for the
[Routemaster](https://github.com/deliveroo/routemaster) event bus.

[Installation](#installation) | [Library usage](#library-usage) | [CLI usage](#cli-usage)


## Installation

    gem install routemaster-client

## Library usage

Add this line to your application's Gemfile:

    gem 'routemaster-client'

**Configure** your client:

```ruby
require 'routemaster/client'
Routemaster::Client.configure do |config|
  config.url = 'https://bus.example.com'
  config.uuid = 'demo' # HTTP Basic token used to talk to the bus
  config.timeout = 2 # in seconds
end
```

If you are using Sidekiq in your project, you can specify the usage of a Sidekiq backend, where event sending will be processed asynchronously.

```ruby
Routemaster::Client.configure do |config|
  # ...
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
Routemaster::Client.created('widgets', 'https://app.example.com/widgets/1', t: 1473080555409)
```

You can also push events asynchronously if you have configured a backend that
supports this (otherwise an error will be raised):

```ruby
Routemaster::Client.updated('widgets', 'https://app.example.com/widgets/2', async: true)
```

A data payload can be sent alongside the event. It is strongly discouraged to do
this except extrame circumstances (particularly as schema migrations become very
painful):

```ruby
Routemaster::Client.created('cats', 'https://app.example.com/cats/42', data: { 'color' => 'teal' })
```

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

## CLI usage

This gem includes the `rtm` binary, which can be used to interact with a
Routemaster bus.

### Commands

    rtm token add [options] SERVICE TOKEN

Adds `TOKEN` to the list of API tokens permitted to use the bus API. `SERVICE`
is a human-readable name for this token.


    rtm token del [options] TOKEN

Removes `TOKEN` from permitted tokens if it exists.


    rtm token list [options]

Lists currently permitted API tokens.


    rtm sub add [options] -c|--callback URL -o|--topics TOPICS [--latency MS] [--max COUNT]

Adds (or updates) a subscription. Note that the `TOKEN` passed in `option` must be
that of the subscriber, not a root token.

- `URL` must be HTTPS and include an authentication username (used by the bus
  when delivering events).
- `TOPICS` is a comma-separated list of topic names.
- `MS`, if specified, is the target delivery latency for this subscriber (ie.
  how long to buffer events). 
- `COUNT`, if specified, is the maximum number of events in a delivered batch.


    rtm sub del [options] [-o|--topics TOPICS]

Updates or removes a subscription. Note that the `TOKEN` passed in `option` must
be that of the subscriber, not a root token.  If no `TOPICS` are specified, the
subscription is entirely removed.


    rtm pub [options] EVENT TOPIC URL

Publishes an event to the bus.  Note that the `TOKEN` passed in `option` must
be that of the subscriber, not a root token. `EVENT` must be one of `created`,
`updated`, `deleted`, or `noop`. `TOPIC` must be a valid topic name. `URL` must
be a valid HTTPS URL.


### Global options

    -b|--bus DOMAIN|IP|@NAME

The domain name of IP address of the bus to interact with, or a reference
(`NAME`) to global configuration.

    -t|--token TOKEN

A root API token to use when querying the bus.


`rtm` will load a configuration file in Yaml format (`.rtmrc` or `~/.rtmrc`).
Example:

    # .rtmrc
    production:
      bus:    prod.bus.example.com
      token:  2bf959d1-04fb-4912-8450-ab646888d476

With this configuration, `rtm token list -b @production` will list API tokens
for the bus at the domain specified in the config.


## Contributing

1. Fork it ( http://github.com/deliveroo/routemaster-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
