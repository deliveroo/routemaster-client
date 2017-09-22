require 'uri'

module Routemaster
  module Client
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

      def _assert_response_throwing_error!(response, error_class, message)
        return if response.success?

        reason = response.body
        info = ["status: #{response.status}"]
        info << "reason: #{reason}" if reason != '' && !reason.nil?

        raise error_class, "#{message} (#{info.join(', ')})"
      end
    end
  end
end
