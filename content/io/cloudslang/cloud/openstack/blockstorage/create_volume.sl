#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
#!!
#! @description: Creates an OpenStack volume.
#! @input host: OpenStack machine host
#! @input identity_port: optional - port used for OpenStack authentication - Default: '5000'
#! @input blockstorage_port: optional - port used for creating volumes on OpenStack - Default: '8776'
#! @input tenant_name: name of OpenStack project where new volume will be created
#! @input volume_name: volume name
#! @input size: size of volume to be created
#! @input username: optional - username used for URL authentication; for NTLM authentication
#!                  Format: 'domain\user'
#! @input password: optional - password used for URL authentication
#! @input proxy_host: optional - proxy server used to access OpenStack services
#! @input proxy_port: optional - proxy server port used to access OpenStack services - Default: '8080'
#! @input proxy_username: optional - username used when connecting to proxy
#! @input proxy_password: optional - proxy server password associated with <proxy_username> input value
#! @output return_result: response of operation in case of success, error message otherwise
#! @output error_message: return_result if status_code is not '202'
#! @output return_code: '0' if success, '-1' otherwise
#! @output status_code: code returned by operation
#! @output volume_id: volume ID
#! @result SUCCESS: volume was successfully created
#! @result GET_AUTHENTICATION_TOKEN_FAILURE: authentication token cannot be obtained
#!                                           from authentication call response
#! @result GET_TENANT_ID_FAILURE: tenant_id corresponding to tenant_name cannot be obtained
#!                                from authentication call response
#! @result GET_AUTHENTICATION_FAILURE: authentication call fails
#! @result CREATE_VOLUME_FAILURE: volume could not be created
#!!#
####################################################

namespace: io.cloudslang.cloud.openstack.blockstorage

imports:
  openstack: io.cloudslang.cloud.openstack
  rest: io.cloudslang.base.network.rest
  json: io.cloudslang.base.json

flow:
  name: create_volume
  inputs:
    - host
    - identity_port: '5000'
    - blockstorage_port: '8776'
    - tenant_name
    - volume_name
    - size
    - username:
        required: false
    - password:
        required: false
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false

  workflow:
    - authentication:
        do:
          openstack.get_authentication_flow:
            - host
            - identity_port
            - tenant_name
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
        publish:
          - token
          - tenant_id
          - return_result
          - error_message
        navigate:
          - SUCCESS: create_volume
          - GET_AUTHENTICATION_TOKEN_FAILURE: GET_AUTHENTICATION_TOKEN_FAILURE
          - GET_TENANT_ID_FAILURE: GET_TENANT_ID_FAILURE
          - GET_AUTHENTICATION_FAILURE: GET_AUTHENTICATION_FAILURE

    - create_volume:
        do:
          rest.http_client_post:
            - url: ${'http://' + host + ':' + blockstorage_port + '/v2/' + tenant_id + '/volumes'}
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - headers: ${'X-AUTH-TOKEN:' + token}
            - content_type: 'application/json'
            - body: ${'{"volume":{"name":"' + volume_name + '","size":"' + size + '"}}'}
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          - SUCCESS: get_volume_id
          - FAILURE: CREATE_VOLUME_FAILURE

    - get_volume_id:
        do:
          json.get_value:
            - json_input: ${return_result}
            - json_path: ['volume', 'id']
        publish:
          - volume_id: ${value}
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: GET_VOLUME_ID_FAILURE

  outputs:
    - return_result
    - error_message
    - return_code
    - status_code
    - volume_id

  results:
    - SUCCESS
    - GET_AUTHENTICATION_TOKEN_FAILURE
    - GET_TENANT_ID_FAILURE
    - GET_AUTHENTICATION_FAILURE
    - CREATE_VOLUME_FAILURE
    - GET_VOLUME_ID_FAILURE
