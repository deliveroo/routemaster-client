module Routemaster::Client::Backends
  NAMES = ["Routemaster::Client::Backends::Synchronous", "Routemaster::Client::Backends::Sidekiq"]

  autoload 'Synchronous', 'routemaster/client/backends/synchronous'
  autoload 'Sidekiq',     'routemaster/client/backends/sidekiq'
end
