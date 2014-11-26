Feature: watch directories

  In order to receive only relevant changes
  As a user
  I want to specify which directories Guard should monitor

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Watch current directory by default
    Given my Guardfile contains:
    """
    require 'guard/plugin'

    module ::Guard
      class Myplugin < Plugin
        def run_on_additions(files)
          $stdout.puts "Files added: #{files.inspect}"
          $stdout.flush
        end
      end
    end

    guard(:myplugin) { watch(/foo/) }

    """
    Given I start `bundle exec guard -n f`
    And I create a file "foo"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Files added: \["foo"\]/

  @spawn
  Scenario: Watch only given directory
    Given my Guardfile contains:
    """
    $stdout.sync = true
    require 'guard/plugin'

    module ::Guard
      class Myplugin < Plugin
        def run_on_additions(files)
          $stdout.puts "Files added: #{files.inspect}"
          $stdout.flush
        end
      end
    end

    guard(:myplugin) { watch(/.*/) }
    """
    Given a directory named "not_watched"
    And a directory named "watched"
    And I start `bundle exec guard -n f -w watched`
    And I create a file "watched/foo"
    And I create a file "not_watch/foo"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Files added: \["watched.foo"\]/

  @spawn
  Scenario: Watch directories provided in Guardfile
    Given my Guardfile contains:
    """
    $stdout.sync = true
    $stderr.sync = true
    require 'guard/plugin'

    directories ['watched']

    module ::Guard
      class Myplugin < Plugin
        def run_on_additions(files)
          $stdout.puts "Files added: #{files.inspect}"
          $stdout.flush
        end
      end
    end

    guard(:myplugin) { watch(/.*/) }
    """
    Given a directory named "not_watched"
    And a directory named "watched"
    And I start `bundle exec guard -n f`
    And I create a file "watched/foo"
    And I create a file "not_watch/foo"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Files added: \["watched.foo"\]/
