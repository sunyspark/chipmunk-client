Feature: End to End functionality
  As an digitization technician
  I want to upload bags
  So that I can verify their upload

  Background:
    Given time is frozen at "2017-05-17 18:49:08 UTC"
    And I am a valid API user with username testuser
    And I send and accept JSON
    And upload.upload_path is "/tmp/chipmunk/inc"
    And upload.rsync_point is "localhost:/tmp/chipmunk/inc"
    And upload.storage_path is "/tmp/chipmunk/store"
    And validation.audio is "/bin/true"

  Scenario Outline: Create initial request and verify
    Given "/tmp/chipmunk/inc/<username>" exists and is empty
    And "/tmp/chipmunk/store" exists and is empty

    When I send a POST request to "/v1/requests" with this json:
      | bag_id | <bag_id>             |
      | content_type | audio          |
      | external_id  | <external_id>  |
    Then the response status should be "201"
    And the response should be empty
    And the response should have the following headers:
      | Location | /v1/requests/<bag_id> |
    When I send a GET request to "/v1/requests/<bag_id>"
    Then the response status should be "200"
    And the JSON response should be:
      | bag_id        | <bag_id>                             |
      | user          | <username>                           |
      | content_type  | audio                                |
      | external_id   | <external_id>                        |
      | upload_link   | localhost:/tmp/chipmunk/inc/<bag_id> |
      | created_at    | 2017-05-17 18:49:08 UTC              |
      | updated_at    | 2017-05-17 18:49:08 UTC              |
    # simulates action of correctly-configured rsync (out of scope of the application)
    When I copy a test bag to "/tmp/chipmunk/inc/<username>/<bag_id>"
    Then copy finishes successfully
    When I send an empty POST request to "/v1/requests/<bag_id>/complete"
    Then the response status should be "201"
    And the response should be empty
    And the response should have the following headers:
      | Location | /v1/queue/1 |
    When I send a GET request to "/v1/queue/1"
    Then the response status should be "200"
    And the JSON response should be:
      | id            |   1                                  |
      | request       | /v1/requests/<bag_id>                |
      | status        | DONE                                 |
      | bag           | /v1/bags/<bag_id>                    |
      | created_at    | 2017-05-17 18:49:08 UTC              |
      | updated_at    | 2017-05-17 18:49:08 UTC              |
    When I send a GET request to "/v1/bags/<bag_id>"
    Then the response status should be "200"
    And the JSON response should be:
      | bag_id        | <bag_id>                             |
      | user          | <username>                           |
      | content_type  | audio                                |
      | external_id   | <external_id>                        |
      | created_at    | 2017-05-17 18:49:08 UTC              |
      | updated_at    | 2017-05-17 18:49:08 UTC              |
      # see PFDR-66 (this fails after the request/bag merger)
      #    When I send a GET request to /v1/requests/<bag_id>"      |
      #    Then the response status should be "303"
      #    And the response should be empty
      #    And the response should have the following headers:
      #      | Location | /v1/bags/<bag_id> |

  Examples:
    | bag_id                                | external_id   | username |
    | a5180fb4-c64e-4a85-8a2f-abe25b0a0c79  | test_ex_id_22 | testuser |
