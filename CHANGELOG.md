## 3.1.3 (2018-01-08)

Bug fixes:

- Fix crash when specifying latency and batch size for subscriptions (#29)

## 3.1.2 (2018-01-05)

Bug fixes:

- Send UUID from given TOKEN when adding/updating subscription(s) (#28)

## 3.1.1 (2017-08-15)

Features:

- Adds the `rtm` command-line API wrapper (#24)
- Adds the `#monitor_subscriptions` API (#17)

Changes:

- The `Routemaster::Topic` value object class is not namespaced as
  `Routemaster::Client::Topic` (#17)

Bug fixes:

- Always send a timestamp when sending asynchronously (#20)
- Sidekiq 5 compatibility (#22)

## 3.1.0 (2017-03-28)

Features:

- Adds support for event payloads (#16)
