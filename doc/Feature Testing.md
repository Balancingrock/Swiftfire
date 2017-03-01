# Purpose of this document

This document contains a list of features, how they are tested and in which version of Swiftfire they were last tested.

There are three different test methods: Test, Implicit and Code Inspection.

`Test` means that the server was used as a black box that was triggered by requesting something from it and the response to that reuqets was monitored in the telemetry or subsequent behaviours.

`Implict` means that a feature can be assumed to work because otherwise the basic functionality of the server would fail.

`Code Inspection`: means that we (currently) don't have the capability or incentive to test the feature and have inspected the code for the correctness of the implementation. This will often be the case for performance and unix API uses.

# Swiftfire Server Parameters

| ID | Description | How | In  
| -: | :- | :-: | :-:
| SP 1 | Ensure that the number of the monitoring and control port can be changed. | Implicit | -
| SP 2 | Ensure that the M&C interface is closed when the inactivity timeout expires | Test | 0.9.15
| SP 3 | Ensure that the HTTP service port number can be changed | Implicit | -
| SP 4 | Ensure that the maximum number of parallel connection is configurable | Test | 0.9.15
| SP 5 | Ensure that the maximum number of pending connections is configurable | Code Inspection | 0.9.15
| SP 6 | Ensure that the maximum wait for pending connections is configurable | Code Inspection | 0.9.15
| SP 7 | Ensure that the Client Message Buffer size is configurable | Code Inspection | 0.9.15
| SP 8 | Ensure that the inactivity duration for keep alive is configurable | Test | 0.9.15
| SP 9 | Ensure that the timeout for a transfer to a client is configurable | Code Inspection | 0.9.15
| SP 10 | Ensure that the auto-start feature is configurable | Test | 0.9.15
| SP 11 | Ensure that the ASL loglevel is configurable | Test | -
| SP 12 | Ensure that the Stdout loglevel is configurable | Implicit | -
| SP 13 | Ensure that the file loglevel is configurable | Test | -
| SP 14 | Ensure that the maximum number of logfiles is configurable | Test | -
| SP 15 | Ensure that the maximum size of a logfile is configurable | test | -
| SP 16 | Ensure that the callback loglevel is configurable | Test | -
| SP 17 | Ensure that the network loglevel is configurable | Code Inspection | -
| SP 18 | Ensure that the network target address can be set | Code Inspection | -
| SP 19 | Ensure that the port of the network target can be set | Code Inspection | -
| SP 20 | Ensure that logging of the full request header at server level can be performed | Test | 0.9.15
| SP 21 | Ensure that the maximum size of the full header logfile can be configured | Code Inspection | -
| SP 22 | Ensure that the full header logfile can be flushed after each recording | Code Inspection | -
| SP 23 | Check that HTTP 1.0 access is supported | Test | -

# Swiftfire Server Telemetry

| ID | Description | How | In |
| -: | :- | :-: | :-:
| ST 1 | Verify that the service version number is correctly reported | Implicit | -
| ST 2 | Verify that the swiftfire status is correctly reported | Implicit | -
| ST 3 | Verify that the number of accept calls that had to wait is correctly reported | Code Inspection | -
| ST 4 | Verify that the total number of accepted HTTP requests is incremented correctly | Test | -
| ST 5 | Verify that the number of HTTP 400 (bad request) is incremented correctly | Test | -
| ST 6 | Verify that the number of HTTP 500 (server error) is incremented correctly | Code Inspection | -
| ST 7 | Verify that the number of HTTP 502 (bad gateway) is incremented correctly | Code Inspection | -

# Domain Parameters

| ID | Description | How | In |
| -: | :- | :-: | :-:
| DP 1 | Verify that the 'map www prefix' works as expected | Test | -
| DP 2 | Verify that the root folder can be changed | Test | -
| DP 3 | Verify that the resources folder can be configured | Test | -
| DP 4 | Test that domain forwarding works | Test | -
| DP 5 | Verify that 'enable domain' works as expected | Test | -
| DP 6 | Verify that access logging works for a domain | Test | -
| DP 7 | Verify that the 404 logging works for a domain | Test | -

# Domain Telemetry

| ID | Description | How | In |
| -: | :- | :-: | :-:
| DT 1 | Verify that the nof Requests is updated correctly | Test | -
| DT 2 | Verify that the nof blacklisted access is updated correctly | Test | -
| DT 3 | Verify that the nof HTTP 200 (OK) is incremented correctly | Test | -
| DT 4 | Verify that the nof HTTP 400 (Bad requests) is incremented correctly | Test | -
| DT 5 | Verify that the nof HTTP 403 (Forbidden) is incremented correctly | Test | -
| DT 6 | Verify that the nof HTTP 404 (Not found) is incremented correctly | Test | -
| DT 7 | Verify that the nof HTTP 500 (Server error) is incremented correctly | Test | -
| DT 8 | Verify that the nof HTTP 501 (Not implemented) is incremented correctly | Test | -
| DT 9 | Verify that the nof HTTP 505 (Http version not supported) is incremented correctly | Test | -