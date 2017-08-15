require 'routemaster/cli/base'

module Routemaster
  module CLI
    class Pub < Base
      prefix %w[pub]
      syntax 'EVENT TOPIC URL'
      descr %{
          Publishes an event to the bus.  Note that the `TOKEN` passed in `options` must
          be that of the subscriber, not a root token. `EVENT` must be one of `created`,
          `updated`, `deleted`, or `noop`. `TOPIC` must be a valid topic name. `URL` must
          be a valid HTTPS URL.
      }

      action do
        bad_argc! unless argv.length == 3

        event, topic, url = argv
        helper.client.public_send(event, topic, url)
      end
    end
  end
end
