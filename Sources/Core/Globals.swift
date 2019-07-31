// =====================================================================================================================
//
//  File:       Globals.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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


// ===========================================
// These variables below are set by main.swift
// ===========================================

// The Swiftfire server parameters

public let parameters = ServerParameters()


// The server level blacklist

public let serverBlacklist = Blacklist()


// The available services for the domains

public let services = Service()


// The available functions

public let functions = Function()


// The server header logger (debug purposes only)

public var headerLogger: HttpHeaderLogger!


// All available domains

public let domains = Domains()


// The server admin account

public var serverAdminDomain: Domain!


// The connection pool for the server

public let connectionPool = ConnectionPool()


// The server telemetry

public let telemetry = ServerTelemetry()


// The HTTP server

public var httpServer: SwifterSockets.TipServer?


// The HTTPS server

public var httpsServer: SecureSockets.SslServer?


// The HTTP dispatch queue

public var httpServerAcceptQueue: DispatchQueue!


// The HTTPS dispatch queue

public var httpsServerAcceptQueue: DispatchQueue!
