require "coveralls"
Coveralls.wear!

require "guard"
require "rspec"

path = "#{File.expand_path("..", __FILE__)}/support/**/*.rb"
Dir[path].each { |f| require f }

# TODO: these shouldn't be necessary with proper specs

def stub_guardfile(contents = nil, &block)
  stub_file(File.expand_path("Guardfile"), contents, &block)
end

def stub_user_guardfile(contents = nil, &block)
  stub_file(File.expand_path("~/.Guardfile"), contents, &block)
end

def stub_user_guard_rb(contents = nil, &block)
  stub_file(File.expand_path("~/.guard.rb"), contents, &block)
end

def stub_user_project_guardfile(contents = nil, &block)
  stub_file(File.expand_path(".Guardfile"), contents, &block)
end

# TODO: I can't wait to replace these with IO.read + rescuing Errno:ENOENT
def stub_file(path, contents = nil, &block)
  exists = !contents.nil?
  allow(File).to receive(:exist?).with(path).and_return(exists)
  return unless exists
  if block.nil?
    allow(File).to receive(:read).with(path).and_return(contents)
  else
    allow(File).to receive(:read).with(path) do
      block.call
    end
  end
end

RSpec.configure do |config|
  config.order = :random
  config.filter_run focus: ENV["CI"] != "true"
  config.run_all_when_everything_filtered = true
  config.raise_errors_for_deprecations!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.before(:each) do |example|
    stub_const("FileUtils", class_double(FileUtils))

    %w(read write exist?).each do |meth|
      allow(File).to receive(meth.to_sym).with(anything) do |*args, &_block|
        abort "stub me! (File.#{meth}(#{args.inspect}))"
      end
    end

    Guard.send(:_reset_for_tests)

    Guard.clear_options

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

    allow(Guard::Notifier::Tmux).to receive(:system) do |*args|
      fail "stub for system() called with: #{args.inspect}"
    end

    allow(Guard::Notifier::Tmux).to receive(:`) do |*args|
      fail "stub for `(backtick) called with: #{args.inspect}"
    end

    allow(Kernel).to receive(:system) do |*args|
      fail "stub for Kernel.system() called with: #{args.inspect}"
    end

    unless example.metadata[:sheller_specs]
      allow(Guard::Sheller).to receive(:run) do |*args|
        fail "stub for Sheller.run() called with: #{args.inspect}"
      end
    end

    allow(Listen).to receive(:to) do |*args|
      fail "stub for Listen.to called with: #{args.inspect}"
    end

    ::Guard.reset_groups
    ::Guard.reset_plugins
  end

  config.before(:all) do
    @guard_notify ||= ENV["GUARD_NOTIFY"]
    @guard_notifiers ||= ::Guard::Notifier.notifiers
  end

  config.after(:each) do
    Guard::Notifier.clear_notifiers

    Guard.clear_options
  end

  config.after(:all) do
    ENV["GUARD_NOTIFY"] = @guard_notify
    ::Guard::Notifier.notifiers = @guard_notifiers
  end

end
