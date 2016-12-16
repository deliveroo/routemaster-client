module Routemaster
  class Client
    class Error < StandardError; end

    class ConfigurationError    < Error; end
    class MissingAttributeError < ConfigurationError; end
    class InvalidAttributeError < ConfigurationError; end
    class InvalidArgumentError  < ConfigurationError; end
  end
end
