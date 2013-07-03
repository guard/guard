require 'coveralls'
Coveralls.wear!

require 'guard'
require 'rspec'

ENV["GUARD_ENV"] = 'test'

Dir["#{File.expand_path('..', __FILE__)}/support/**/*.rb"].each { |f| require f }

puts "Please do not update/create files while tests are running."

RSpec.configure do |config|
  config.color_enabled = true
  config.order = :random
  config.filter_run :focus => true
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    @fixture_path = Pathname.new(File.expand_path('../fixtures/', __FILE__))

    # Ensure debug command execution isn't used in the specs
    Guard.stub(:debug_command_execution)

    # Stub all UI methods, so no visible output appears for the UI class
    ::Guard::UI.stub(:info)
    ::Guard::UI.stub(:warning)
    ::Guard::UI.stub(:error)
    ::Guard::UI.stub(:debug)
    ::Guard::UI.stub(:deprecation)

    ::Guard.reset_groups
    ::Guard.reset_plugins
  end

  config.before(:all) do
    ::Guard::Notifier.send(:_auto_detect_notification)
    @guard_notify ||= ENV['GUARD_NOTIFY']
    @guard_notifiers ||= ::Guard::Notifier.notifiers
  end

  config.after(:each) do
    Pry.config.hooks.delete_hook(:when_started, :load_guard_rc)
    Pry.config.hooks.delete_hook(:when_started, :load_project_guard_rc)

    ::Guard.options.debug = false if ::Guard.options
  end

  config.after(:all) do
    ENV['GUARD_NOTIFY'] = @guard_notify
    ::Guard::Notifier.notifiers = @guard_notifiers
  end

end
