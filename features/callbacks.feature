Feature: callbacks

  In order to run custom actions before and after tasks
  As a user
  I want to add callback hooks

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Add a callback hook
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

    guard(:myplugin) do
      watch(/foo/)
      callback(:run_on_additions_end) do
        $stdout.puts "Callback called!"
        $stdout.flush
      end
    end

    """
    Given I start `bundle exec guard -n f`
    And I create a file "foo"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Callback called!/
