# Build websites in Swift.

The Swiftfire webserver can be extended with functions and services written in Swift. Making it possible to create entire websites written in nothing else but HTML, CSS and Swift. No other languages, frameworks or external services necessary.

Since the website and server-software are merged into one, you will need access to your own server-hardware. This can be any old computer as long as it is able to run MacOS 10.11 (El Capitan).

Linux compatibility is envisaged, but not yet actively supported.

Visit the Swiftfire homepage at [http://swiftfire.nl](http://swiftfire.nl).

## How it works

This is a very high level overview of how Swiftfire can use Swift code to create websites.

Every domain that is hosted under Swiftfire implements a stack of services. By default that stack implements a static website.

For each (valid and accepted) request that arrives at the server, Swiftfire finds the stack of services to execute and does so one by one.

You can add your own services to modify or extend de default behaviour. However adding services is probabely not done too often. It is nice to know that it is possible, but it is not anticipated that many users will want to do so.

It is in the custom "functions" that the real power of Swiftfire rests.

One service in the stack of services retrieves the requested resource from disk and verifies if it must be parsed.
If it must be parsed it scans the file for "functions". Any function that is found is executed, and the result of the execution is injected into the resource at the exact spot of the function. The function itself is removed.

In an example:

    <p>This page has been accessed .nofPageHits() times</p>

is translated to:

    <p>This page has been accessed 59440 times</p>

or any other number of course.

The best part is, you can define and write the functions yourself. And after registration Swiftfire takes care of the rest.

It is up to you to determine how much you want to do in Swift. For example, you could decide to have the entire landing page to be created by a function if index.html exists only of: `.buildLandingPage()`. (And of course you have implemented the function that is registered under the name `createLandingPage`)

## No GUI?

No, Swiftfire is a faceless webserver application. It does not have a GUI.

However there is anther project called [SwiftfireConsole](https://github.com/Balancingrock/SwiftfireConsole) that does have a GUI and can connect to a Swiftfire webserver.

Thus for setup or monitoring a GUI is available.

The GUI even implements a rudimentary tracking of the number of visitors to your site without needing third parties.
  
## Note

This is an early public beta release. 

However: It does work! :-)

## Features

- Allows HTML and CSS code injection from functions written in Swift
- Allows website services to be implemented in Swift 
- Out of the box support for static websites
- Handles multiple domains
- Sessions are supported
- Client forwarding (to other hosts or a different port on the same host)
- Integrated usage statistics (page visits)
- Blacklisting (refusal of service) on IP basis for Server and per domain
- Supports HTTP1.0 and HTTP1.1
- Supports HTTPS
- Custom pages for errors (for example the infamous 404 page not found)
- Logging of received headers possible
- Logging of missing pages (404)
- Console application available

## Installation
Please refer to the [installation instructions](http://swiftfire.nl/pages/manual/02_installation.html) on the [Swiftfire](http://swiftfire.nl) website.

## Version history

Note: Planned releases are for information only and almost always change.

#### 2.0.0 (Thought about)

- Session support
- Add URL redirection list

#### 1.0.0 (Planned)

- A few (1-6) months after v0.10.0 (Confidence building period)##
- Bugfixes
- Small feature improvements (if necessary)
- Code improvements

#### 0.10.7 (Planned)

- Add support for "Users"

#### 0.10.6 (Current)

- Added session support
- Code improvements
- Minor bugfixes

#### 0.10.5

- Fixed typo of blacklist in log
- Added debug output to service invokation
- Fixed memory leak from SwifterJSON

#### 0.10.4

- Bugfix: inactivity on m&c interface no longer causes a crash.

#### 0.10.3

- Bugfixes in SwifterSockets and SwiftfireCore

#### 0.10.2

- Changes in SwiftfireConsole for xcode 8.3

#### 0.10.1

- Removed warnings due to Xcode 8.3

#### 0.10.0

- Added support for functions (HTML & CSS code injections)

#### 0.9.18

- Added HTTPS support
- General update of headers

#### 0.9.17

- Use SSL for the interface to SwiftfireConsole

#### 0.9.16

- Infrastructure update (no code changes).

#### 0.9.15

- Switched to SwiftPM distribution
- Updated for new approach in SwifterSockets

#### 0.9.14

- Added IP Address block list (blacklists)
- Added custom error pages (for example the 404 error) support
- Upgrade to Xcode 8 beta 6 (Swift 3)
- Major improvements of the GUI console

#### 0.9.13

- Updated for Xcode 8 beta 3 (Swift 3)

#### 0.9.12

- Added usage charts that track the number of page visits over time
- Added enabling/disabling of visit counting for specific resources

#### 0.9.11

- Merged SwiftfireConsole into this project as an extra target
- Added usage statistics for client & domain usage.
- Updated for VJson 0.9.8

#### 0.9.10

- Added domain statistics

#### 0.9.9

- Fixed a bug in SwifterSockets that would not log correct IPv6 addresses.
- Fixed a number of bugs that messed up logging of access and 404
- Renamed FileLog to Logfile
- Replaced header logging code with usage of Logfile

#### 0.9.8

- Quick fix for bug that would prevent creation of AccessLog and Four04Log.

#### 0.9.7

- Cleaned up parameter definition setting and usage
- Added option to log all HTTP request headers
- Added option to log all access to a domain
- Added option to log all URLs that result in a 404 reply
- Few minor bug fixes (minor = will probably never occur and does not impact functionaly)

#### 0.9.6

- Header update to include new website: [swiftfire.nl](http://swiftfire.nl)
- Removed Startup, folded into Parameters
- Merged MAX_NOF_PENDING_CLIENT_MESSAGES with MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
- Save & Restore no longer preserve telemetry values
- Added transmission of "ClosingMacConnection" info upon timeout for the M&C connection
- Added ResetDomainTelemetry command

#### 0.9.5

- Fixed bug that prevented domain creation
- Added MIME type support based on the file extension

#### 0.9.4

- Switched to VJSON pipe operators
- Simplified the SwifterConsole M&C interface

#### 0.9.3

- Added domain telemetry

#### 0.9.2

- Minor changes to accomodate changes in other packages

#### 0.9.1

- Minor changes to accomodate changes in SwifterSockets/SwifterLog/SwifterJSON
- Added 'descriptionWithSeparator' to Extensions.swift
- Added release tags

#### 0.9.0

- Initial public release
