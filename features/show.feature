Feature: Show

  In order to know the defined groups and plugins
  As a developer using Guard
  I want to see a table of groups and plugins

  @in-process
  Scenario: Show error when no Guardfile
    When I run `guard show`
    Then the output should match /No Guardfile found, please create one with `guard init`\./
    And the exit status should not be 0

  @in-process
  Scenario: Show plugins and their configuration
    Given a file named "Guardfile" with:
    """
    guard :cucumber do
    end
    """
    When I run `guard show`
    Then the output should match /^\s+\| default \| cucumber\s+\|/
