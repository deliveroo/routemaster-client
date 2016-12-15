module Routemaster
  class Client
    class Error < StandardError; end

    class ConfigurationError < Error; end
    class MissingAttributeError < ConfigurationError; end
    class InvalidAttributeError < ConfigurationError; end
  end
end
