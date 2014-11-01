Feature: gracefully handling plugin failures

  In order to prevent restarting Guard after plugin failures
  As a user
  I want Guard to gracefully ignore plugin failures

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Continue after a failing task
    Given my Guardfile contains:
    """
    require 'guard/plugin'

    module ::Guard
      class EpicFail < Plugin
        def run_on_modifications(files)
          fail "epic fail!"
        end
      end

      class Myplugin < Plugin
        def run_on_additions(files)
          $stdout.puts "Files added: #{files.inspect}"
          $stdout.flush
        end
      end
    end

    guard(:epic_fail) { watch('foo') }
    guard(:myplugin) { watch('bar') }

    """
    Given an empty file named "foo"
    When I start `bundle exec guard`
    And I append to the file "foo"
    And I create a file "bar"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /Files added: \["bar"\]/
