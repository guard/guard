Feature: Notifiers

  In order to know what notifiers are available
  As a developer using Guard
  I want to see a table of notifiers and their options

  Scenario: Show notifiers and their configuration
    Given a file named "Guardfile" with:
    # NOTE: don't actually add notifiers, because Guard detects notifier client
    # mode - where Notifier.add() will fail
    """
    guard :ronn do
    end
    """
    When I run `guard notifiers`
    Then the output should match /^\s+\| Name \s*\| Available \s*\|/
    Then the output should match /^\s+\| terminal_title \s* \| .\s* \|/
