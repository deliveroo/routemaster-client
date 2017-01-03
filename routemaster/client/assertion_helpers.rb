require 'uri'

module Routemaster
  class Client
    module AssertionHelpers
      def assert_valid_url_throwing_error!(url, error_class)
        begin
          uri = URI.parse(url)
          unless uri.is_a? URI::HTTPS
            raise error_class, "url '#{url}' is invalid, must be an https url"
          end
        rescue URI::InvalidURIError
          raise error_class, "url '#{url}' is invalid, must be an https url"
        end
      end
    end
  end
end
