Feature: End to End functionality
  As an digitization technician
  I want to upload bags
  So that I can verify their upload

  Background:
      Given time is frozen at "2017-05-17 18:49:08 UTC"
      And upload.upload_path is "/tmp/chipmunk/inc"
      And upload.rsync_point is "localhost:/tmp/chipmunk/inc"
      And upload.storage_path is "/tmp/chipmunk/store"

  Scenario: create request
    Given I am a valid API user with username "testuser"
    And I send and accept JSON
    When I send a POST request to "/v1/requests" with this json:
      | bag_id | a5180fb4-c64e-4a85-8a2f-abe25b0a0c79 |
      | content_type | audio                          |
      | external_id  | test_external_id_22            |
    Then the response status should be "201"
    And the response should be empty
    And the response should have the following headers:
      | Location | /v1/requests/a5180fb4-c64e-4a85-8a2f-abe25b0a0c79 |
    When I send a GET request to "/v1/requests/a5180fb4-c64e-4a85-8a2f-abe25b0a0c79"
    Then the response status should be "200"
    And the JSON response should be:
      | bag_id        | a5180fb4-c64e-4a85-8a2f-abe25b0a0c79 |
      | user          | testuser                             |
      | content_type  | audio                                |
      | external_id   | test_external_id_22                  |
      | upload_link   | localhost:/tmp/chipmunk/inc/a5180fb4-c64e-4a85-8a2f-abe25b0a0c79        |
      | created_at    | 2017-05-17 18:49:08 UTC              |
      | updated_at    | 2017-05-17 18:49:08 UTC              |

