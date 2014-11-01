Feature: Guard "start" command

  In order to automate my workflow
  As a user
  I want Guard to respond to file changes

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Run a task
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

    guard :myplugin do
      watch('foo')
    end

    """
    When I start `bundle exec guard -n f`
    And I create a file "foo"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Files added: \["foo"\]/
