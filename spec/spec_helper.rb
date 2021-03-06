require 'simplecov'
require 'webmock'
SimpleCov.start

SimpleCov.start do
  add_filter 'routemaster/client/configuration'
  add_filter 'routemaster/client/backends/sidekiq/configuration'
end

module CLIHelpers
  def self.included(by)
    by.class_eval do
      require 'stringio'

      let(:stderr) { StringIO.new }
      let(:stdout) { StringIO.new }
      let(:perform) { Routemaster::CLI::Toplevel.new(stdout: stdout, stderr: stderr).run(argv) }
      let(:client) { Routemaster::Client }
    end
  end

  def allow_bus_pulse(host, token)
    stub_request(:get, %r{^https://#{Regexp.escape host}/pulse$}).
      with(basic_auth: [token, 'x']).
      to_return(status: 204)
  end
end

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.raise_errors_for_deprecations!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.after(:suite) { WebMock.disable! }

  config.include CLIHelpers, type: :cli
  
  # Unfortunately, Client Connection and Configuration are implemented as
  # pseudo-singletons, which requires a song and dance to prevent state from
  # leaking across specs:
  config.after { Routemaster::Client::Connection.reset_connection }
  config.after { Routemaster::Client::Configuration.reset }
end

