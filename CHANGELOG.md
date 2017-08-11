# HEAD

Changes:

- The `Routemaster::Topic` value object class is not namespaced as
  `Routemaster::Client::Topic` (#17)

Features:

- Adds the `#monitor_subscriptions` API (#17)


Bug fixes:

- Always send a timestamp when sending asynchronously (#20)
- Sidekiq 5 compatibility (#2w)

# v3.1.0 (2017-03-28) 

Features: 

- Adds support for event payloads (#16)
