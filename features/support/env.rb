require "aruba"
require "aruba/cucumber"
require "aruba/in_process"
require "aruba/spawn_process"

require "guard/aruba_adapter"

Before("@spawn") do
  aruba.config.command_launcher = :spawn

  gemfile_path = expand_path("Gemfile")
  set_environment_variable "BUNDLE_GEMFILE", File.expand_path(gemfile_path)
  set_environment_variable "RUBY_OPT", "-W0"

  set_environment_variable(
    "GUARD_NOTIFIERS",
    "---\n"\
    "- :name: :file\n"\
    "  :options:\n"\
    "    :path: '/dev/stdout'\n"
  )
end

Before("@in-process") do
  aruba.config.command_launcher = :in_process
  aruba.config.main_class = Guard::ArubaAdapter
end

Before do
  set_environment_variable "INSIDE_ARUBA_TEST", "1"

  home = expand_path("home")
  set_environment_variable "HOME", home
  FileUtils.mkdir(home)

  @aruba_timeout_seconds = Cucumber::JRUBY ? 45 : 15
end
