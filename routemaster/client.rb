require 'routemaster/client/backends/synchronous'
require 'routemaster/client/connection'
require 'routemaster/client/configuration'
require 'routemaster/client/version'
require 'routemaster/client/errors'
require 'routemaster/client/assertion_helpers'
require 'routemaster/topic'
require 'uri'
require 'json'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'oj'

module Routemaster
  module Client
    class << self
      extend Forwardable
      include AssertionHelpers

      def_delegator :'Routemaster::Client::Configuration', :async_backend
      def_delegator :'Routemaster::Client::Configuration', :lazy

      def configure
        self.tap do
          Configuration.configure do |c|
            yield c
          end
          _check_pulse! unless lazy
        end
      end

      def created(topic, callback, timestamp = nil, t: nil, async: false)
        _warn_timestamp_deprecation(timestamp)
        _send_event('create', topic, callback, t: t || timestamp, async: async)
      end

      def created_async(topic, callback, timestamp = nil, t: nil)
        _warn_timestamp_deprecation(timestamp)
        _warn_async_deprecation
        _send_event('create', topic, callback, t: t || timestamp, async: true)
      end

      def updated(topic, callback, timestamp = nil, t: nil, async: false)
        _warn_timestamp_deprecation(timestamp)
        _send_event('update', topic, callback, t: t || timestamp, async: async)
      end

      def updated_async(topic, callback, timestamp = nil, t: nil)
        _warn_timestamp_deprecation(timestamp)
        _warn_async_deprecation
        _send_event('update', topic, callback, t: t || timestamp, async: true)
      end

      def deleted(topic, callback, timestamp = nil, t: nil, async: false)
        _warn_timestamp_deprecation(timestamp)
        _warn_async_deprecation
        _send_event('delete', topic, callback, t: t || timestamp, async: async)
      end

      def deleted_async(topic, callback, timestamp = nil, t: nil)
        _warn_timestamp_deprecation(timestamp)
        _warn_async_deprecation
        _send_event('delete', topic, callback, t: t || timestamp, async: true)
      end

      def noop(topic, callback, timestamp = nil, t: nil, async: false)
        _warn_timestamp_deprecation(timestamp)
        _send_event('noop', topic, callback, t: t || timestamp, async: async)
      end

      def noop_async(topic, callback, timestamp = nil, t: nil)
        _warn_timestamp_deprecation(timestamp)
        _warn_async_deprecation
        _send_event('noop', topic, callback, t: t || timestamp, async: true)
      end

      def subscribe(topics:, callback:, **options)
        _assert_valid_topics!(topics)
        _assert_valid_url!(callback)
        _assert_valid_max_events! options[:max] if options[:max]
        _assert_valid_timeout! options[:timeout] if options[:timeout]

        _conn.subscribe(topics: topics, callback: callback, **options)
      end

      def unsubscribe(*topics)
        _assert_valid_topics!(topics)

        topics.each do |t|
          response = _conn.delete("/subscriber/topics/#{t}")

          unless response.success?
            raise 'unsubscribe rejected'
          end
        end
      end

      def unsubscribe_all
        response = _conn.delete('/subscriber')

        unless response.success?
          raise 'unsubscribe all rejected'
        end
      end

      def delete_topic(topic)
        _assert_valid_topic!(topic)

        response = _conn.delete("/topics/#{topic}")

        unless response.success?
          raise 'failed to delete topic'
        end
      end

      def monitor_topics
        response = _conn.get('/topics') do |r|
          r.headers['Content-Type'] = 'application/json'
        end

        unless response.success?
          raise 'failed to connect to /topics'
        end

        Oj.load(response.body).map do |raw_topic|
          Topic.new raw_topic
        end
      end

      private

      def _conn
        Connection
      end

      def _synchronous_backend
        Routemaster::Client::Backends::Synchronous
      end

      def _assert_valid_url!(url)
        assert_valid_url_throwing_error!(url, InvalidArgumentError)
      end

      def _assert_valid_max_events!(max)
        unless (1..10_000).include?(max)
          raise InvalidArgumentError, "max events '#{max}' is invalid, must be between 1 and 10,000"
        end
      end

      def _assert_valid_topics!(topics)
        unless topics.kind_of? Enumerable
          raise InvalidArgumentError, "topics must be a list"
        end

        unless topics.length > 0
          raise InvalidArgumentError "topics must contain at least one element"
        end

        topics.each { |t| _assert_valid_topic!(t) }
      end

      def _assert_valid_topic!(topic)
        unless topic =~ /^[a-z_]{1,64}$/
          raise InvalidArgumentError, 'bad topic name: must only include letters and underscores'
        end
      end

      def _assert_valid_timestamp!(timestamp)
        unless timestamp.kind_of? Integer
          raise InvalidArgumentError, "timestamp '#{timestamp}' is invalid, must be an integer"
        end
      end

      def _assert_valid_timeout!(timeout)
        unless (0..3_600_000).include? timeout
          raise InvalidArgumentError, "timeout '#{timeout}' is invalid, must be an integer between 0 and 3,600,000"
        end
      end

      def _send_event(event, topic, callback, t: nil, async: false)
        _assert_valid_url!(callback)
        _assert_valid_topic!(topic)
        _assert_valid_timestamp!(t) if t

        backend = async ? async_backend : _synchronous_backend
        backend.send_event(event, topic, callback, t: t)
      end

      def _check_pulse!
        _conn.get('/pulse').tap do |response|
          raise 'cannot connect to bus' unless response.success?
        end
      end

      def _warn_async_deprecation
        warn 'routemaster-client: The _*_async event-sending methods are deprecated. Use async: true instead.'
        warn "(in #{caller(2,1).first})"
      end

      def _warn_timestamp_deprecation(value)
        return if value.nil?
        warn 'routemaster-client: Passing timestamps as positional parameters is deprecated. Use the t: key instead.'
        warn "(in #{caller(2,1).first})"
      end

      private :async_backend, :lazy
    end
  end
end
