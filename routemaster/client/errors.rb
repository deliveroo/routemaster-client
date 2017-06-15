module Routemaster
  module Client
    class Error < StandardError; end
    class ArgumentError < ArgumentError; end

    class InvalidArgumentError       < ArgumentError; end
    class ConfigurationError         < Error; end
    class MissingAsyncBackendError   < Error; end
    class MissingAttributeError      < ConfigurationError; end
    class InvalidAttributeError      < ConfigurationError; end
    class ConnectionError            < Error; end
  end
end
