Feature: using Guard API

  In order to reuse existing Guard functionality
  As a user
  I want to call Guard API without Guard

  Background: Guard is installed through bundler
    Given my Gemfile includes "gem 'rake'"
    And Guard is bundled using source

  @spawn
  Scenario: Call notifier
    Given my Rakefile contains:
    """
    require "bundler/setup"
    require "guard/notifier"
    task :default do
      Guard::Notifier.notify "foo", title: "bar"
    end

    """
    Given I run `bundle exec rake`
    Then the output should match /\[bar\] foo/
