Feature: New Button
  The 'New' button should make good guesses about what a user is most likely to want to add
  based on where they are currently.

  Background:
    Given I am logged in as a Content Editor

  Scenario: On a page
    When I am editing at page
    And I press the 'New' menu button
    Then it should add a page in the same section I as the page I was editing

  Scenario: On the sitemap
    When I am at /cms/sitemap
    And I press the 'New' menu button
    Then it should add a page in the root section

  Scenario: On Content Library
    When I am working with a content type
    And I press the 'New' menu button
    Then it should add a new item of that type

  Scenario: On Administration Tab
    When I am managing users
    And I press the 'New' menu button
    Then it should add a new user







