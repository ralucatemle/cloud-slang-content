#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
namespace: io.cloudslang.platform_as_a_service.openshift.applications

imports:
  lists: io.cloudslang.base.lists
  json: io.cloudslang.base.json
  strings: io.cloudslang.base.strings

flow:
  name: test_list_applications

  inputs:
    - host
    - username:
        required: false
    - password:
        required: false
    - proxy_host:
        required: false
    - proxy_port:
        default: "'8080'"
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
    - domain

  workflow:
    - list_app:
        do:
          list_applications:
            - host
            - username:
                required: false
            - password:
                required: false
            - proxy_host:
                required: false
            - proxy_port:
                required: false
            - proxy_username:
                required: false
            - proxy_password:
                required: false
            - domain
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          SUCCESS: check_result
          FAILURE: LIST_APPLICATION_FAILURE

    - check_result:
        do:
          lists.compare_lists:
            - list_1: [str(error_message), int(return_code), int(status_code)]
            - list_2: ["''", 0, 200]
        navigate:
          SUCCESS: get_status
          FAILURE: CHECK_RESPONSES_FAILURE

    - get_status:
        do:
          json.get_value_from_json:
            - json_input: return_result
            - key_list:
                default: ["'status'"]
                overridable: false
        publish:
          - status: value
        navigate:
          SUCCESS: verify_status
          FAILURE: GET_STATUS_FAILURE

    - verify_status:
        do:
          strings.string_equals:
            - first_string: "'ok'"
            - second_string: str(status)
        navigate:
          SUCCESS: get_messages_text
          FAILURE: VERIFY_STATUS_FAILURE

    - get_messages_text:
        do:
          json.get_value_from_json:
            - json_input: return_result
            - key_list:
                default: ["'messages'", 0, "'text'"]
                overridable: false
        publish:
          - messages_text: value
        navigate:
          SUCCESS: get_found_text_occurrence
          FAILURE: GET_MESSAGES_TEXT_FAILURE

    - get_found_text_occurrence:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: str(messages_text)
            - string_to_find: "'Found'"
            - ignore_case: True
        publish:
          - found_text_occurrence: return_result
        navigate:
          SUCCESS: verify_found_text
          FAILURE: GET_FOUND_TEXT_OCCURRENCE_FAILURE

    - verify_found_text:
        do:
          strings.string_equals:
            - first_string: str(found_text_occurrence)
            - second_string: str(1)
        navigate:
          SUCCESS: SUCCESS
          FAILURE: VERIFY_FOUND_TEXT_FAILURE

  outputs:
    - return_result
    - error_message
    - return_code
    - status_code

  results:
    - SUCCESS
    - LIST_APPLICATION_FAILURE
    - CHECK_RESPONSES_FAILURE
    - GET_STATUS_FAILURE
    - VERIFY_STATUS_FAILURE
    - GET_MESSAGES_TEXT_FAILURE
    - GET_FOUND_TEXT_OCCURRENCE_FAILURE
    - VERIFY_FOUND_TEXT_FAILURE