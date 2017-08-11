# HEAD

Features:

- Adds the `rtm` command-line API wrapper (#24)
- Adds the `#monitor_subscriptions` API (#17)

Changes:

- The `Routemaster::Topic` value object class is not namespaced as
  `Routemaster::Client::Topic` (#17)

Bug fixes:

- Always send a timestamp when sending asynchronously (#20)
- Sidekiq 5 compatibility (#22)

# v3.1.0 (2017-03-28) 

Features: 

- Adds support for event payloads (#16)
