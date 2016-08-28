# Swiftfire
A webserver in pure Swift

Swifterfire is the end product of 4 packages that make up the [Swiftfire](http://swiftfire.nl) webserver:

#####[SwifterSockets](https://github.com/Swiftrien/SwifterSockets)

General purpose socket utilities.

#####[SwifterLog](https://github.com/Swiftrien/SwifterLog)

General purpose logging utility.

#####[SwifterJSON](https://github.com/Swiftrien/SwifterJSON)

General purpose JSON framework.

There is a 5th package called [SwiftfireTester](https://github.com/Swiftrien/SwiftfireTester) that can be used to challenge a webserver (any webserver) and verify the response.

#Note
This is an early public release and I do not consider this code ready for prime time. It is experimental in nature and subject to severe rewrites as development continues.

However: It does work! :-)

__Special note__: The current version 0.9.14 compiles under Xcode 8 beta 6 only. It has not been deployed and only tested on a development machine. It is intended as an interim build for developpers only.

#Usage

Swiftfire needs the files from SwifterLog, SwifterSockets and SwifterJSON as source files.
To this end I created a workspace with 4 projects (5 actually), all of the above mentioned packages.
Then I drag & drop the group with the source files from (for example) SwifterLog and drop them in Swiftfire. In the dialogue I make sure that the files are not copied, only referenced. That is it, compile & run...

#Features

- Webserver for static websites
- Handles multiple domains
- Client forwarding (to other hosts or a different port on the same host)
- Integrated usage statistics (page visits)
- Blacklisting (refusal of service) on IP basis for Server and per domain
- Supports HTTP1.0 and HTTP1.1
- Custom pages for errors (for example the infamous 404 page not found)
- Logging of received headers possible
- Logging of missing pages (404)
- Includes a console application
- Compiles with Xcode 8 beta 6 (Swift 3)

#Version history

Note: Planned releases are for information only and subject to change without notice.

####V2.0.0 (Planned)

- Adding support for dynamic content
- Session support
- HTTPS support

####V1.0.0 (Planned)

- 1-3 Months after v0.9.14
- Bugfixes
- Small feature improvements (if necessary)
- Code improvements
- Build with final version of Swift 3

####v0.9.15 (Planned)

- Add URL redirection list

####v0.9.14 (Current)

- Added IP Address block list (blacklists)
- Added custom error pages (for example the 404 error) support
- Upgrade to Xcode 8 beta 6 (Swift 3)
- Major improvements of the GUI console

####V0.9.13

- Updated for Xcode 8 beta 3 (Swift 3)

####v0.9.12

- Added usage charts that track the number of page visits over time
- Added enabling/disabling of visit counting for specific resources

####v0.9.11

- Merged SwiftfireConsole into this project as an extra target
- Added usage statistics for client & domain usage.
- Updated for VJson 0.9.8

####v0.9.10

- Added domain statistics

####v0.9.9

- Fixed a bug in SwifterSockets that would not log correct IPv6 addresses.
- Fixed a number of bugs that messed up logging of access and 404
- Renamed FileLog to Logfile
- Replaced header logging code with usage of Logfile

####v0.9.8

- Quick fix for bug that would prevent creation of AccessLog and Four04Log.

####v0.9.7

- Cleaned up parameter definition setting and usage
- Added option to log all HTTP request headers
- Added option to log all access to a domain
- Added option to log all URLs that result in a 404 reply
- Few minor bug fixes (minor = will probably never occur and does not impact functionaly)

####v0.9.6

- Header update to include new website: [swiftfire.nl](http://swiftfire.nl)
- Removed Startup, folded into Parameters
- Merged MAX_NOF_PENDING_CLIENT_MESSAGES with MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
- Save & Restore no longer preserve telemetry values
- Added transmission of "ClosingMacConnection" info upon timeout for the M&C connection
- Added ResetDomainTelemetry command

####v0.9.5

- Fixed bug that prevented domain creation
- Added MIME type support based on the file extension

####v0.9.4

- Switched to VJSON pipe operators
- Simplified the SwifterConsole M&C interface

####v0.9.3

- Added domain telemetry

####v0.9.2

- Minor changes to accomodate changes in other packages

####v0.9.1

- Minor changes to accomodate changes in SwifterSockets/SwifterLog/SwifterJSON
- Added 'descriptionWithSeparator' to Extensions.swift
- Added release tags

####v0.9.0

- Initial public release
