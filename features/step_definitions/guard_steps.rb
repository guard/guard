Given(/^my Guardfile contains:$/) do |contents|
  write_file("Guardfile", contents)
end

Given(/^Guard is bundled using source$/) do
  write_file(
    "Gemfile",
    "gem 'guard', path: File.expand_path(File.join(Dir.pwd, '..', '..'))\n")

  run_simple(unescape("bundle install --quiet"), true)
end

When(/^I start `([^`]*)`$/) do |cmd|
  run_interactive(unescape(cmd))
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
  Timeout::timeout(exit_timeout) do
    loop do
      break if assert_partial_output_interactive(expected)
      sleep 0.1
    end
  end
end
