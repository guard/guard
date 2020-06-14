Feature: setting logger options

  In order to customize logging output
  As a user
  I want to specify the logger options

  Background: Guard is installed through bundler
    Given Guard is bundled using source

  @spawn
  Scenario: Customize logger template
    Given my Guardfile contains:
    """
    require 'guard/plugin'

    logger(template: '[Custom - :severity - :time - :progname] :message')

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
    Given I start `bundle exec guard -n f`
    And I create a file "foo"
    And I wait for Guard to become idle
    And I stop guard
    Then the output should match /\[Custom - INFO - \d\d:\d\d:\d\d - Guard\]/

    @spawn
    Scenario: Customize logger level
      Given my Guardfile contains:
      """
      require 'guard/plugin'

      logger(level: :warn)

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
      Given I start `bundle exec guard -n f`
      And I create a file "foo"
      And I wait for Guard to become idle
      And I stop guard
      Then the output should not contain "INFO"
