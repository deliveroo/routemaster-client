module Routemaster
  module Client
    class Error < StandardError; end

    class InvalidArgumentError       < Error; end
    class ConfigurationError         < Error; end
    class MissingAsyncBackendError   < Error; end
    class MissingAttributeError      < ConfigurationError; end
    class InvalidAttributeError      < ConfigurationError; end
  end
end
