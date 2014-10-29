Feature: Guard "init" command

  In order to quickly start a new project with Guard
  As a user
  I want Guard to create a Guardfile template for me

  Scenario: Create an empty Guardfile
    When I run `guard init -b`
    Then the output should match /Writing new Guardfile to .*Guardfile$/
    And the file "Guardfile" should contain "# A sample Guardfile"

  Scenario: Create a Guardfile using a plugin's template
    When I run `guard init ronn`
    Then the output should match /Writing new Guardfile to .*Guardfile$/
    And the file "Guardfile" should match /^guard :ronn do$/
