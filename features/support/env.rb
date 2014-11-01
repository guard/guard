require "aruba"
require "aruba/cucumber"
require "aruba/in_process"
require "aruba/spawn_process"

require "guard/aruba_adapter"

Before("@spawn") do
  Aruba::process = Aruba::SpawnProcess

  set_env "BUNDLE_GEMFILE", File.expand_path(File.join(current_dir, "Gemfile"))
  set_env "RUBY_OPT", "-W0"
end

Before("~@spawn") do
  Aruba::InProcess.main_class = Guard::ArubaAdapter
  Aruba::process = Aruba::InProcess
end

Before do
  set_env "INSIDE_ARUBA_TEST", "1"
  set_env "HOME", File.expand_path(File.join(current_dir, "home"))

  # disable annoying Ruby warnings due to cucumber using Kernel.load()
  FileUtils.mkdir_p ENV["HOME"]

  @aruba_timeout_seconds = Cucumber::JRUBY ? 35 : 15
end
