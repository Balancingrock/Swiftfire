// =====================================================================================================================
//
//  File:       DomainServices.Registration.swift
//  Project:    Swiftfire
//
//  Version:    1.0.1
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.0.1 - Documentation update
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import Core


// ==============================================
// Descriptions for the available domain services
// ==============================================

// Note: If any of these texts are changed it will be necessary to re-assign new services for existing domains.

private let blacklist = "Abort if client IP is in blacklist"
private let onlyHttp10OrHttp11 = "Only HTTP 1.0 / 1.1 requests"
private let onlyGetOrPost = "Only GET / POST requests"
private let getResourcePathFromUrl = "Get resource path from request URL"
private let getFileAtResourcePath = "Get file at resource path"


/// The name by which service_getSession is known.

public let getSession = "Get Active Session"


/// The name by which service_decodePostFormUrlEncoded is known.

public let decodePostFormUrlEncoded = "Decode post form urlencoded"


/// The name by which service_waitUntilBodyComplete is known.

public let waitUntilBodyComplete = "Wait until body is received"


/// The name by which service_transferResponse is known.

public let transferResponse = "Transfer Response"


/// The name by which service_restartSessionTimeout is known.

public let restartSessionTimeout = "Restart Session Timeout"


// =================================================
// Add to the next function to register new services
// =================================================
// Notice that the sequence itself is not important


/// Registers services.
///
/// Add any newly defined services to this operation.

public func registerServices() {
    
    services.register(name: blacklist, service: service_blacklist)
    services.register(name: onlyHttp10OrHttp11, service: service_onlyHttp10or11)
    services.register(name: onlyGetOrPost, service: service_onlyGetOrPost)
    services.register(name: getResourcePathFromUrl, service: service_getResourcePathFromUrl)
    services.register(name: getFileAtResourcePath, service: service_getFileAtResourcePath)
    services.register(name: getSession, service: service_getSession)
    services.register(name: decodePostFormUrlEncoded, service: service_decodePostFormUrlEncoded)
    services.register(name: waitUntilBodyComplete, service: service_waitUntilBodyComplete)
    services.register(name: transferResponse, service: service_transferResponse)
    services.register(name: restartSessionTimeout, service: service_restartSessionTimeout)
}


// ========================================================================
// Add to the next array to provide a default service chain for NEW domains
// ========================================================================
// Notice that the sequence is very important


/// Default services for newly created domains.
///
/// This service stack implements a default webserver.

public var defaultServices: Array<String> {
    return [
        blacklist,
        onlyHttp10OrHttp11,
        onlyGetOrPost,
        getSession,
        waitUntilBodyComplete,
        decodePostFormUrlEncoded,
        getResourcePathFromUrl,
        getFileAtResourcePath,
        restartSessionTimeout,
        transferResponse
    ]
}
