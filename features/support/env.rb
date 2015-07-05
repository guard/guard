require "aruba"
require "aruba/cucumber"
require "aruba/in_process"
require "aruba/spawn_process"

require "guard/aruba_adapter"

Before("@spawn") do
  Aruba::process = Aruba::Processes::SpawnProcess

  gemfile_path = File.join(current_directory, "Gemfile")
  set_env "BUNDLE_GEMFILE", File.expand_path(gemfile_path)
  set_env "RUBY_OPT", "-W0"
  set_env "GUARD_NOTIFY", nil
  set_env "GUARD_NOTIFY_PID", nil
  set_env "GUARD_NOTIFY_ACTIVE", nil
  set_env "GUARD_NOTIFIERS", "---\n- :name: :terminal_title\n  :options: {}\n"
end

Before("~@spawn") do
  Aruba.process = Aruba::Processes::InProcess
  Aruba.process.main_class = Guard::ArubaAdapter
end

Before do
  set_env "INSIDE_ARUBA_TEST", "1"
  set_env "HOME", File.expand_path(File.join(current_directory, "home"))

  # disable annoying Ruby warnings due to cucumber using Kernel.load()
  FileUtils.mkdir_p ENV["HOME"]

  @aruba_timeout_seconds = Cucumber::JRUBY ? 35 : 15
end
