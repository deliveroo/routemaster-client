require 'rack/auth/basic'
require 'base64'
require 'json'
require 'wisper'

module Routemaster
  class Receiver
    include Wisper::Publisher

    def initialize(app, options = {})
      warn 'Routemaster::Receiver is deprecated, use Routemaster::Drain::Basic instead'
      warn "(at #{caller(2,1).first})"

      @app     = app
      @path    = options[:path]
      @uuid    = options[:uuid]
      @handler = options[:handler] if options[:handler]
    end

    def call(env)
      catch :forward do
        throw :forward unless _intercept_endpoint?(env)
        return [401, {}, []] unless _has_auth?(env)
        return [403, {}, []] unless _valid_auth?(env)
        payload = _extract_payload(env)
        return [400, {}, []] unless payload

        @handler.on_events(payload) if @handler
        publish(:events_received, payload)
        return [204, {}, []]
      end
      @app.call(env)
    end

    private

    def _intercept_endpoint?(env)
      env['PATH_INFO'] == @path && env['REQUEST_METHOD'] == 'POST'
    end

    def _has_auth?(env)
      env.has_key?('HTTP_AUTHORIZATION')
    end

    def _valid_auth?(env)
      p "#{self.class} - #{@uuid}"
      p "#{self.class} - #{Base64.decode64 env['HTTP_AUTHORIZATION']}"

      Base64.
        decode64(env['HTTP_AUTHORIZATION'].gsub(/^Basic /, '')).
        split(':').first == @uuid
    end

    def _extract_payload(env)
      return unless env['CONTENT_TYPE'] == 'application/json'
      JSON.parse(env['rack.input'].read)
    end
  end
end
