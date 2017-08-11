require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'routemaster/client/configuration'

module Routemaster
  module Client
    module Connection
      class << self
        extend Forwardable

        def post(path, &block)
          http(:post, path, &block)
        end

        def get(path, &block)
          http(:get, path, &block)
        end

        def delete(path, &block)
          http(:delete, path, &block)
        end

        def http(method, path, &block)
          _conn.send(method, path, &block)
        end

        def send_event(event, topic, callback, t: nil, data: nil)
          payload = { 'type' => event, 'url' => callback, 'timestamp' => t }
          payload['data'] = data unless data.nil?

          response = post("/topics/#{topic}") do |r|
            r.headers['Content-Type'] = 'application/json'
            r.body = Oj.dump(payload, mode: :strict)
          end

          raise ConnectionError, "event rejected (status: #{response.status})" unless response.success?

          # Any issues would have caused an exception to be thrown
          true
        end

        def subscribe(options)
          response = post('/subscription') do |r|
            r.headers['Content-Type'] = 'application/json'
            r.body = Oj.dump(_stringify_keys options)
          end

          raise ConnectionError, "subscribe rejected (status: #{response.status})" unless response.success?
        end

        def reset_connection
          @_conn = nil
        end

        private

        def_delegators :'Routemaster::Client::Configuration', :url, :timeout, :uuid, :verify_ssl

        def _stringify_keys(hash)
          hash.dup.tap do |h|
            h.keys.each do |k|
              h[k.to_s] = h.delete(k)
            end
          end
        end

        def _conn
          @_conn ||= Faraday.new(url, ssl: { verify: verify_ssl }) do |f|
            f.request :retry, max: 2, interval: 100e-3, backoff_factor: 2
            f.request :basic_auth, uuid, 'x'
            f.adapter :typhoeus

            f.options.timeout      = timeout
            f.options.open_timeout = timeout
          end
        end
      end
    end
  end
end
