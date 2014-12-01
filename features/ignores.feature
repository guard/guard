Feature: ignore files and directories

  In order to receive only relevant changes
  As a user
  I want to specify which files and directories to ignore globally

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Ignore events matching ignore regexp
    Given my Guardfile contains:
    """
    require 'guard/plugin'

    ignore /bar/

    module ::Guard
      class Myplugin < Plugin
        def run_on_additions(files)
          $stdout.puts "Files added: #{files.inspect}"
          $stdout.flush
        end
      end
    end

    guard(:myplugin) { watch(/ba/) }

    """
    Given I start `bundle exec guard -n f`
    And I create a file "baz"
    And I create a file "bar"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Files added: \["baz"\]/
