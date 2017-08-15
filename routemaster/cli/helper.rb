require 'routemaster/client'
require 'yaml'

module Routemaster
  module CLI
    Exit = Class.new(StandardError)

    class Helper
      def initialize(config)
        @config = config
      end

      def client
        _configure_client
        Routemaster::Client
      end

      private

      def _bus_url
        case @config.bus
        when /^@(.*)/ then
          domain = _rc_file_data.dig($1, :bus)
          raise "No configuration for bus '#{$1}' found in .rtmrc" if domain.nil?
          "https://#{domain}"
        else
          "https://#{@config.bus}"
        end
      end

      def _bus_token
        case @config.bus
        when /^@(.*)/ then
          @config.token || _rc_file_data.dig($1, :token)
        else
          @config.token
        end
      end

      def _configure_client
        Routemaster::Client.configure do |c|
          c.url = _bus_url
          c.uuid = _bus_token
        end
      end

      def _rc_file_data
        data =
        if File.exist?('.rtmrc')
          YAML.load_file('.rtmrc')
        elsif File.exist?(File.expand_path '~/.rtmrc')
          YAML.load_file(File.expand_path '~/.rtmrc')
        else
          {}
        end

        Hashie::Mash.new(data)
      end
    end
  end
end
