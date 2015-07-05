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

  run_simple(unescape("bundle install --quiet"), true)
end

When(/^I start `([^`]*)`$/) do |cmd|
  @interactive = run(unescape(cmd))
  step "I wait for Guard to become idle"
end

When(/^I create a file "([^"]*)"$/) do |path|
  write_file(path, "")

  # give guard time to respond to change
  type "sleep 1"
end

When(/^I append to the file "([^"]*)"$/) do |path|
  append_to_file(path, "modified")

  # give guard time to respond to change
  type "sleep 1"
end

When(/^I stop guard$/) do
  close_input
end

When(/^I wait for Guard to become idle$/) do
  expected = "guard(main)>"
  begin
    Timeout::timeout(exit_timeout) do
      loop do
        break if assert_partial_output_interactive(expected)
        sleep 0.1
      end
    end
  rescue Timeout::Error
    STDERR.puts all_stdout
    STDERR.puts all_stderr
    fail
  end
end

When(/^I type in "([^"]*)"$/) do |line|
  type line
end

When(/^I press Ctrl-C$/) do
  # Probably needs to be fixed on Windows
  Process.kill("SIGINT", @interactive.instance_variable_get(:@process).pid)
  step "I wait for Guard to become idle"
end
