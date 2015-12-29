Feature: FileHandler

  Scenario: add a new file
    Given run two BitBroker with different configuration
    When add a new file
    Then the file is synchronized with another

  Scenario: modify a file (append)
    Given run two BitBroker with different configuration
    When modify a file (append)
    Then the file is synchronized with another

  Scenario: modify a file (truncate)
    Given run two BitBroker with different configuration
    When modify a file (truncate)
    Then the file is synchronized with another

  Scenario: delete a file
    Given run two BitBroker with different configuration
    When delete a file
    Then the file is removed on each environment
