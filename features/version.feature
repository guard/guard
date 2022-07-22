Feature: Guard "version" command

  In order to know if the Guard is up to date
  As a user
  I want to get the Guard version

  @in-process
  Scenario: Show Guard's version
    When I run `guard version`
    Then the output should match /^Guard version \d+.\d+.\d+(-\w+)?$/
