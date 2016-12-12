require 'routemaster/client/version'
require 'routemaster/topic'
require 'uri'
require 'json'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'oj'

module Routemaster
  class Client
    
    def initialize(options = {})
      if options.has_key?(:uuid)
        warn "Routemaster::Client :uuid is deprecated - please use :client_token"
        options[:client_token] = options.delete(:uuid)
      end

      @_url = _assert_valid_url(options[:url])
      @_client_token = options[:client_token]
      @_timeout = options.fetch(:timeout, 1)
      @_verify_ssl = options.fetch(:verify_ssl, true)

      _assert (options[:client_token] =~ /^[a-z0-9_-]{1,64}$/), 'client_token should be alpha'
      _assert_valid_timeout(@_timeout)

      unless options[:lazy]
        _conn.get('/pulse').tap do |response|
          raise 'cannot connect to bus' unless response.success?
        end
      end
    end

    def created(topic, callback, timestamp = nil)
      _send_event('create', topic, callback, timestamp)
    end

    def updated(topic, callback, timestamp = nil)
      _send_event('update', topic, callback, timestamp)
    end

    def deleted(topic, callback, timestamp = nil)
      _send_event('delete', topic, callback, timestamp)
    end

    def noop(topic, callback, timestamp = nil)
      _send_event('noop', topic, callback, timestamp)
    end

    def subscribe(options = {})
      if (options.keys - [:topics, :callback, :timeout, :max, :uuid, :callback_token]).any?
        raise ArgumentError.new('bad options')
      end

      if options.has_key?(:uuid)
        warn ":uuid is deprecated - please use :callback_token"
        options[:callback_token] = options.delete(:uuid)
      end

      _assert options[:topics].kind_of?(Enumerable), 'topics required'
      _assert options[:callback], 'callback required'
      _assert_valid_timeout options[:timeout] if options[:timeout]
      _assert_valid_max_events options[:max] if options[:max]

      options[:topics].each { |t| _assert_valid_topic(t) }
      _assert_valid_url(options[:callback])

      response = _post('/subscription') do |r|
        r.headers['Content-Type'] = 'application/json'
        r.body = Oj.dump(_stringify_keys options)
      end

      unless response.success?
        raise 'subscribe rejected'
      end
    end

    def unsubscribe(*topics)
      topics.each { |t| _assert_valid_topic(t) }

      topics.each do |t|
        response = _delete("/subscriber/topics/#{t}")

        unless response.success?
          raise 'unsubscribe rejected'
        end
      end
    end

    def unsubscribe_all
      response = _delete('/subscriber')

      unless response.success?
        raise 'unsubscribe all rejected'
      end
    end

    def delete_topic(topic)
      _assert_valid_topic(topic)

      response = _delete("/topics/#{topic}")

      unless response.success?
        raise 'failed to delete topic'
      end
    end

    def monitor_topics
      response = _get('/topics') do |r|
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

    def _stringify_keys(hash)
      hash.dup.tap do |h|
        h.keys.each do |k|
          h[k.to_s] = h.delete(k)
        end
      end
    end

    def _assert_valid_timeout(timeout)
      _assert (0..3_600_000).include?(timeout), 'bad timeout'
    end

    def _assert_valid_max_events(max)
      _assert (0..10_000).include?(max), 'bad max # events'
    end

    def _assert_valid_url(url)
      uri = URI.parse(url)
      _assert (uri.scheme == 'https'), 'HTTPS required'
      return url
    end

    def _assert_valid_topic(topic)
      _assert (topic =~ /^[a-z_]{1,64}$/), 'bad topic name: must only include letters and underscores'
    end

    def _assert_valid_timestamp(timestamp)
      _assert timestamp.kind_of?(Integer), 'not an integer'
    end

    def _send_event(event, topic, callback, timestamp = nil)
      _assert_valid_url(callback)
      _assert_valid_topic(topic)
      _assert_valid_timestamp(timestamp) if timestamp

      data = { type: event, url: callback, timestamp: timestamp }

      response = _post("/topics/#{topic}") do |r|
        r.headers['Content-Type'] = 'application/json'
        r.body = Oj.dump(_stringify_keys data)
      end
      fail "event rejected (#{response.status})" unless response.success?
    end

    def _assert(condition, message)
      condition or raise ArgumentError.new(message)
    end

    def _http(method, path, &block)
      _conn.send(method, path, &block)
    end

    def _post(path, &block)
      _http(:post, path, &block)
    end

    def _get(path, &block)
      _http(:get, path, &block)
    end

    def _delete(path, &block)
      _http(:delete, path, &block)
    end

    def _conn
      @_conn ||= Faraday.new(@_url, ssl: { verify: @_verify_ssl }) do |f|
        f.request :retry, max: 2, interval: 100e-3, backoff_factor: 2
        f.request :basic_auth, @_client_token, 'x'
        f.adapter :typhoeus

        f.options.timeout      = @_timeout
        f.options.open_timeout = @_timeout
      end
    end
  end
end
