## HEAD

Bug fixes:

- Subscription now includes max_events and timeout details so they
  get printed
- `$LOAD_PATH` is fixed so `./exe/rtm` can now be run directly

## 3.2.0 (2018-01-08)

Changes:

-  Unpin oj (#25)

Bug fixes:

- Fixes out of scope config (#30)

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
