require 'routemaster/cli/base'
require 'yaml'

module Routemaster
  module CLI
    module Sub
      class Add < Base
        prefix %w[sub add]
        syntax 'URL TOPIC [TOPIC...]'
        descr %{
          Adds (or updates) a subscription. Note that the `TOKEN` passed in `option` must be
          that of the subscriber, not a root token.

          `URL` must be HTTPS and include an authentication username (used by the bus
            when delivering events).

          `TOPICS` are topic names (which might not be published to yet).
        }

        options do |p|
          p.on('--latency MS', %{
            The target delivery latency for this subscriber (ie. how long to buffer events for).
          }) do |x|
            config.latency = Integer(x)
          end

          p.on('--batch-size COUNT', %{
            The maximum number of events in a delivered batch.
          }) do |x|
            config.batch_size = Integer(x)
          end
        end

        action do
          bad_argc! unless argv.length > 1

          url, *topics = argv
          params = {}
          params[:timeout] = config.latency    if config.latency
          params[:max]     = config.batch_size if config.batch_size
          params[:uuid]    = config.token
          helper.client.subscribe(callback: url, topics: topics, **params)
        end
      end

      class Del < Base
        prefix %w[sub del]
        syntax '[TOPIC...]'
        descr %{
          Updates or removes a subscription. Note that the `TOKEN` passed in `options` must
          be that of the subscriber, not a root token.  If no `TOPICS` are specified, the
          subscription is entirely removed.
        }

        action do
          if argv.length > 0
            helper.client.unsubscribe(*argv)
          else
            helper.client.unsubscribe_all
          end
        end
      end

      class List < Base
        prefix %w[sub list]
        descr %{
          List existing subscriptions.
        }

        action do
          bad_argc! if argv.length > 0

          puts YAML.dump(helper.client.monitor_subscriptions.map(&:attributes))
        end
      end
    end
  end
end

