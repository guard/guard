Feature: handle while editing CTRL-C

  In order to cancel a command in Pry
  As a user
  I want CTRL-C to clear the Pry prompt

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Continue after a failing task
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

    guard(:myplugin) { watch('bar') }

    """
    Given an empty file named "foo"
    When I start `bundle exec guard -n f`
    And I press Ctrl-C
    And I type in "1+2"
    And I stop guard
    Then the output should match /=> 3/
