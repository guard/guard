# frozen_string_literal: true

Given(/^my Guardfile contains:$/) do |contents|
  write_file("Guardfile", contents)
end

Given(/^my Rakefile contains:$/) do |contents|
  write_file("Rakefile", contents)
end

Given(/^my Gemfile includes "([^"]*)"$/) do |gem|
  (@gems ||= []) << gem
end

Given(/^Guard is bundled using source$/) do
  gems = @gems || []
  gems << "gem 'guard', path: File.expand_path(File.join(Dir.pwd, '..', '..'))"

  write_file("Gemfile", "#{gems.join("\n")}\n")
  run_command_and_stop("bundle install --quiet", fail_on_error: true)
end

When(/^I start `([^`]*)`$/) do |cmd|
  skip_this_scenario if defined?(JRUBY_VERSION)
  @interactive = run_command(cmd)
  step "I wait for Guard to become idle"
end

When(/^I create a file "([^"]*)"$/) do |path|
  write_file(path, "")

  # give guard time to respond to change
  type(+"sleep 1")
end

When(/^I append to the file "([^"]*)"$/) do |path|
  append_to_file(path, "modified")

  # give guard time to respond to change
  type(+"sleep 1")
end

When(/^I stop guard$/) do
  close_input
end

When(/^I wait for Guard to become idle$/) do
  expected = "guard(main)>"
  begin
    Timeout.timeout(aruba.config.exit_timeout) do
      loop do
        break if last_command_started.stdout.include?(expected)

        sleep 0.1
      end
    end
  rescue Timeout::Error
    warn all_commands.map(&:stdout).join("\n")
    warn all_commands.map(&:stderr).join("\n")
    fail
  end
end

When(/^I type in "([^"]*)"$/) do |line|
  type line
end

When(/^I press Ctrl-C$/) do
  skip_this_scenario if Nenv.ci?
  # Probably needs to be fixed on Windows
  obj = @interactive.instance_variable_get(:@delegate_sd_obj)
  pid = obj.instance_variable_get(:@process).pid
  Process.kill("SIGINT", pid)
  step "I wait for Guard to become idle"
end
