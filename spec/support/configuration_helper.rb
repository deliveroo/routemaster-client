module ConfigurationHelper
  def reset_config_between_tests!
    after do
      Routemaster::Client.send(:remove_const, :Configuration)
      load 'routemaster/client/configuration.rb'
    end
  end

  def reset_sidekiq_config_between_tests!
    after do
      Routemaster::Client::Backends::Sidekiq.send(:remove_const, :Configuration)
      load 'routemaster/client/backends/sidekiq/configuration.rb'
    end
  end
end

RSpec.configure { |c| c.extend ConfigurationHelper }
