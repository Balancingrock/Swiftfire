# Build websites in Swift.

___Note: The Swiftfire [homepage](http://swiftfire.nl) usually lags the developments in HEAD.___

_We have bit the bullet, and handed out the tag 1.0.0._

_Our initial testing shows that Swiftfire does work, but the combinations ot be tested are near endless. Hence we have decided to up the version to 1.0.0, and handle any issues that might arise later asap._

The Swiftfire webserver can be extended with functions and services written in Swift. This makes it possible to create entire websites written in nothing else but HTML, CSS and Swift. No other languages, frameworks or external services necessary, with a minor exception for openSSL.

To use Swiftfire as an end-user you need a MacOS computer capable of running at least MacOS 10.12.

To develop Swiftfire extensions you need Xcode as well.

Linux compatibility is envisaged, but not yet actively supported.

Visit the Swiftfire homepage at [http://swiftfire.nl](http://swiftfire.nl).

## How it works

This is a very high level overview of how Swiftfire can use Swift code to create websites.

Every domain that is hosted under Swiftfire implements a stack of services. By default that stack implements a static website.

For each (valid and accepted) request that arrives at the server, Swiftfire finds the stack of services to execute and does so one service after the other.

You can add your own services to modify or extend de default behaviour.

However it is much more likely that you will want to create your own functions.

Functions can be used to inject HTML code into otherwise "static" web pages. Giving them dynamic qualities.

One of the services in the stack retrieves the requested page from disk and verifies if it must be parsed. If it must be parsed it scans the page for 'functions'. Any function that is found is executed, and the result of the execution is injected into the page at the exact spot of the function. The function itself is removed.

An example:

    <p>This page has been accessed .nofPageHits() times</p>

is translated to:

    <p>This page has been accessed 59440 times</p>

or any other number of course.

The best part is, you can define and write the functions yourself.

It is up to you to determine how much you want to do in Swift. For example, you could decide to have the entire landing page to be created by a function. To do that let index.sf.html exists only of: `.buildLandingPage()`. And of course you have to implement the function that is registered under the name `buildLandingPage`.

It is fast. Depending of course on the amount and complexity of the services and functions, Swiftfire as presented here is very fast. On our server (a mac mini) the static pages are usually served in less than 2mS. Adding functions and services may increase this number of course. Still since the function calls and services refer to compiled code instead of interpreted code the speed of Swiftfire can be expected to be higher than interpreter solutions.

Oh, and it does PHP as well...

## GUI

Swiftfire is a faceless webserver application. However it comes with a website that can be used for administration purposes. On initial start of the server, any request on the port on which the server listens will result in a landing page that asks the user to create an admin account and the directory in which the administration site is installed.

Once set up, any access to the port that has as its URL: '/serveradmin' will end up on the login page of the server administrator website. Note that the login is only as secure as the protocol. Use HTTP only when accessing from within a private LAN.
  
## Note

This is an early public beta release. 

However: It does work! :-)

## Features

- Allows code injection (HTML and CSS) from functions written in Swift
- Allows website services to be implemented in Swift 
- Out of the box support for static websites
- Handles multiple domains
- Sessions are supported
- Accounts are supported
- Client forwarding (to other hosts or a different port on the same host)
- Integrated usage statistics (page visits)
- Blacklisting (refusal of service) on IP basis for Server and per domain
- Supports HTTP1.0 and HTTP1.1
- Supports HTTPS
- Web based interface for Swiftfire Administrator
- Custom pages for errors (for example the infamous 404 page not found)
- Logging of received headers possible
- Logging of missing pages (404)
- Supports PHP

## Installation

### Using SPM

Download the project using git clone:

    $ git clone https://github.com/Balancingrock/Swiftfire.git

Then switch to the directory containg the project:

    $ cd Swiftfire

The build the project, but first make the build script executable:

    $ chmod +x sf-build.sh
    $ ./sf-build

This should build the project without errors.

However... the project needs openSSL. And while a compiled version of openSSL is provided with the project, you should not trust this. Make sure to download and install openSSL from the original sources at [openSSL.org](https://openssl.org)

The follow the directions as mentioned under the subproject [SecureSockets](https:github.com/balancingrock/SecureSockets).

You will likely enounter some issues with the target release when you have not compiled openSSL for MacOS 10.12, these are however easily fixed by using build options.

### Using Xcode

First follow the steps as per directions above. Perform exactly the same steps, but this time there is no need to build the project. Instead generate the xcode project:

    $ swift package generate-xcodeproj

Opening the generated Xcode project update the build settings `Search Paths` for the targets:
- SecureSockets, Core: Add to the build setting `Search Paths -> Header Search Paths` the value `$(SRCROOT)/openssl/v1_1_0-macos_10_12/include`.
- SecureSockets, Core & Swiftfire: Add to the build setting `Search Paths -> Library Search Paths` the value `$(SRCROOT)/openssl/v1_1_0-macos_10_12/lib`.

Of course if you have a different paths for the openSSL include and lib paths then modify accordingly.

## Configuring

When Swiftfire is started for the first time, some configuration must be done. You may want to prepare for this by moving the `sfadmin` directory included in the repository to a different location, though it can remain inside the project too.

In the default configuration Swiftfire will listen on port 6678 for incoming connections. Any connection attempt without domains being present will result in the return of a primitive page where the administrator ID and password msut be set in addition to the location of the `sfadmin` directory.

Once that is done, Swiftfire can be customized by logging in as admin and using the admin pages.

Note that Swiftfire will store and expect information in the `~/Library/Application Support/Swiftfire` location after it was first started. Some of the logs are in *.txt format, settings are in *.json format (for which we recommend our [proJSON](https://apps.apple.com/app/id1444778157) app) and the visitor statistics are in the *.brbon format. For which there is currently no app available. The BRBON spec however can be found on github including a [BRBON API](https://github.com/Balancingrock/BRBON.git). How to make the visitor statistics available is a subject of discussion.

## Making changes

You can of course change whatever you want, but the current source code layout was choosen for a reason. While this layout is rather new (and thus may need to change) we hope that you will only need to add to the `Custom`, `Functions` and `Services` targets. Though you should leave their current contents unaffected since the correct functioning of the admin server account depends on them.

## Version history

Note: Planned releases are for information only and almost always change.

#### 1.1.0 (Open)

- Add URL redirection list

#### 1.0.0 (Current)

- Upped to 1.0.0

_Removed older history entries_
