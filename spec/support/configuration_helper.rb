module ConfigurationHelper
  def reset_config_between_tests!
    before do
      Routemaster::Client.send(:remove_const, :Configuration)
      load 'routemaster/client/configuration.rb'
    end
  end
end

RSpec.configure { |c| c.extend ConfigurationHelper }
