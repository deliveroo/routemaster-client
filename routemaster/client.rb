require 'routemaster/client/backends'
require 'routemaster/client/connection'
require 'routemaster/client/configuration'
require 'routemaster/client/version'
require 'routemaster/client/errors'
require 'routemaster/topic'
require 'uri'
require 'json'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'oj'

module Routemaster
  class Client
    class << self
      extend Forwardable

      def_delegator :'Routemaster::Client::Configuration', :async_backend
      def_delegator :'Routemaster::Client::Configuration', :lazy

      def configure
        self.tap do
          Configuration.configure do |c|
            yield c
          end
          check_pulse! unless lazy
        end
      end

      def created(topic, callback, timestamp = nil)
        send_event('create', topic, callback, timestamp)
      end

      def created_async(topic, callback, timestamp = nil)
        send_event('create', topic, callback, timestamp, async: true)
      end

      def updated(topic, callback, timestamp = nil)
        send_event('update', topic, callback, timestamp)
      end

      def updated_async(topic, callback, timestamp = nil)
        send_event('update', topic, callback, timestamp, async: true)
      end

      def deleted(topic, callback, timestamp = nil)
        send_event('delete', topic, callback, timestamp)
      end

      def deleted_async(topic, callback, timestamp = nil)
        send_event('delete', topic, callback, timestamp, async: true)
      end

      def noop(topic, callback, timestamp = nil)
        send_event('noop', topic, callback, timestamp)
      end

      def noop_async(topic, callback, timestamp = nil)
        send_event('noop', topic, callback, timestamp, async: true)
      end

      def subscribe(topics:, callback:, **options)
        assert_valid_topics!(topics)
        assert_valid_url!(callback)
        assert_valid_max_events! options[:max] if options[:max]
        assert_valid_timeout! options[:timeout] if options[:timeout]

        conn.subscribe(topics: topics, callback: callback, **options)
      end

      def unsubscribe(*topics)
        assert_valid_topics!(topics)

        topics.each do |t|
          response = conn.delete("/subscriber/topics/#{t}")

          unless response.success?
            raise 'unsubscribe rejected'
          end
        end
      end

      def unsubscribe_all
        response = conn.delete('/subscriber')

        unless response.success?
          raise 'unsubscribe all rejected'
        end
      end

      def delete_topic(topic)
        assert_valid_topic!(topic)

        response = conn.delete("/topics/#{topic}")

        unless response.success?
          raise 'failed to delete topic'
        end
      end

      def monitor_topics
        response = conn.get('/topics') do |r|
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

      def conn
        Connection
      end

      def synchronous_backend
        Routemaster::Client::Backends::Synchronous
      end

      def assert_valid_url!(url)
        begin
          uri = URI.parse(url)
          unless uri.is_a? URI::HTTPS
            raise InvalidArgumentError, "url '#{url}' is invalid, must be an https url"
          end
        rescue URI::InvalidURIError
          raise InvalidArgumentError, "url '#{url}' is invalid, must be an https url"
        end
      end

      def assert_valid_max_events!(max)
        unless (1..10_000).include?(max)
          raise InvalidArgumentError, "max events '#{max}' is invalid, must be between 1 and 10,000"
        end
      end

      def assert_valid_topics!(topics)
        unless topics.kind_of? Enumerable
          raise InvalidArgumentError, "topics must be a list"
        end

        unless topics.length > 0
          raise InvalidArgumentError "topics must contain at least one element"
        end

        topics.each { |t| assert_valid_topic!(t) }
      end

      def assert_valid_topic!(topic)
        unless topic =~ /^[a-z_]{1,64}$/
          raise InvalidArgumentError, 'bad topic name: must only include letters and underscores'
        end
      end

      def assert_valid_timestamp!(timestamp)
        unless timestamp.kind_of? Integer
          raise InvalidArgumentError, "timestamp '#{timestamp}' is invalid, must be an integer"
        end
      end

      def assert_valid_timeout!(timeout)
        unless (0..3_600_000).include? timeout
          raise InvalidArgumentError, "timeout '#{timeout}' is invalid, must be an integer between 0 and 3,600,000"
        end
      end

      def send_event(event, topic, callback, timestamp = nil, async: false)
        assert_valid_url!(callback)
        assert_valid_topic!(topic)
        assert_valid_timestamp!(timestamp) if timestamp

        backend = async ? async_backend : synchronous_backend
        backend.send_event(event, topic, callback, timestamp)
      end

      def check_pulse!
        conn.get('/pulse').tap do |response|
          raise 'cannot connect to bus' unless response.success?
        end
      end
    end
  end
end
