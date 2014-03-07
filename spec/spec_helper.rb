require 'coveralls'
Coveralls.wear!

require 'guard'
require 'rspec'

ENV['GUARD_ENV'] = 'test'

path = "#{File.expand_path('..', __FILE__)}/support/**/*.rb"
Dir[path].each { |f| require f }

STDOUT.puts 'Please do not update/create files while tests are running.'

RSpec.configure do |config|
  config.order = :random
  config.filter_run focus: ENV['CI'] != 'true'
  config.run_all_when_everything_filtered = true
  config.raise_errors_for_deprecations!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do |example|
    @fixture_path = Pathname.new(File.expand_path('../fixtures/', __FILE__))

    # Ensure debug command execution isn't used in the specs
    allow(Guard).to receive(:_debug_command_execution)

    # Stub all UI methods, so no visible output appears for the UI class
    allow(::Guard::UI).to receive(:info)
    allow(::Guard::UI).to receive(:warning)
    allow(::Guard::UI).to receive(:error)
    allow(::Guard::UI).to receive(:debug)
    allow(::Guard::UI).to receive(:deprecation)

    # Avoid clobbering the terminal
    allow(Guard::Notifier::TerminalTitle).to receive(:puts)
    allow(Guard::Notifier::Tmux).to receive(:system) { '' }
    allow(Guard::Notifier::Tmux).to receive(:`) { '' }
    allow(Pry.output).to receive(:puts)

    unless example.metadata[:sheller_specs]
      class Guard::Sheller
        def run; self; end
        def stdout; ''; end
        def success?; true; end
      end
      # allow_any_instance_of(Guard::Sheller).to receive(:run) {}
    end

    ::Guard.reset_groups
    ::Guard.reset_plugins
  end

  config.before(:suite) do
    # Use a fake home directory so that user configurations,
    # such as their ~/.guard.rb file, won't impact the
    # tests.
    fake_home = File.expand_path('../fake-home', __FILE__)
    FileUtils.rmtree fake_home
    FileUtils.mkdir fake_home
    ENV['HOME'] = fake_home
  end

  config.before(:all) do
    @guard_notify ||= ENV['GUARD_NOTIFY']
    @guard_notifiers ||= ::Guard::Notifier.notifiers
  end

  config.after(:each) do
    Pry.config.hooks.delete_hook(:when_started, :load_guard_rc)
    Pry.config.hooks.delete_hook(:when_started, :load_project_guard_rc)

    Guard::Notifier.clear_notifiers

    ::Guard.options[:debug] = false if ::Guard.options
  end

  config.after(:all) do
    ENV['GUARD_NOTIFY'] = @guard_notify
    ::Guard::Notifier.notifiers = @guard_notifiers
  end

end
