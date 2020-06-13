// =====================================================================================================================
//
//  File:       Globals.swift
//  Project:    Swiftfire
//
//  Version:    1.3.2
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019-2020 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.3.2 - Added startupTime
// 1.1.0 - Fixed loading & storing of domain service names
//       - Removed server blacklist (now located in the serveradmin domain
// 1.0.0 - Initial version
//
// =====================================================================================================================

import Foundation

import SwifterLog
import SwifterSockets
import SecureSockets


// Shortcut notation for the logger

public typealias Log = SwifterLog.Logger


// Every thread that runs for more than a few milliseconds should poll this variable and terminate itself when it finds that this flag is 'true'.

public var quitSwiftfire: Bool = false


// =======================================================================================
// These variables below are set or loaded by main.swift before the server(s) are started.
// =======================================================================================


// After the creation of the server parameters they still retain their default values.

/// The Swiftfire server parameters

public let serverParameters = ServerParameters()


// After creation the services object will be empty. Services must still be registered.

/// The available services for the domains

public let services = Services()


// After creation the functions object will be empty. Functions must still be regietered.

/// The available functions

public let functions = Functions()


// The header logger is only defined here, it should be tested for not-nill before a server is started. The application should fail when the headerLogger cannot be created.

/// The server header logger (debug purposes only)

public var headerLogger: HttpHeaderLogger!


// The domainManager are still empty after creation, they have to be loaded before starting the server(s)

/// All available domains

public let domainManager: DomainManager! = DomainManager()


// The server domain has to exist, a test for non-nil is necessary before starting the server(s)

/// The server admin account

public var serverAdminDomain: Domain!


// The connection is still empty after creation. Creating connection objects in the pool is done when (re)starting the HTTP(s) server(s).

/// The connection pool for the server

public let connectionPool = ConnectionPool()


// The server telemetry is always reset at the start of the server.

/// The server telemetry

public let serverTelemetry = ServerTelemetry()


// The HTTP server

public var httpServer: SwifterSockets.TipServer?


// The HTTPS server

public var httpsServer: SecureSockets.SslServer?


// The HTTP dispatch queue

public var httpServerAcceptQueue: DispatchQueue!


// The HTTPS dispatch queue

public var httpsServerAcceptQueue: DispatchQueue!


// The default webserver service stack

public var defaultServices: Array<String> = []


// The time the startup of the server was completed

public var startupTime: Date!


// An often used error message

public let htmlErrorMessage = "***error***".data(using: .utf8)!
