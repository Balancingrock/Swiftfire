// =====================================================================================================================
//
//  File:       DomainServices.Registration.swift
//  Project:    Swiftfire
//
//  Version:    1.1.0
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
// 1.1.0 - Fixed loading & storing of domain service names
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


/// The service name for the blacklist service

public let serviceName_Blacklist = "Abort if client IP is in blacklist"


/// The service name for the http1.0/1.1 filter service

public let serviceName_OnlyHttp10OrHttp11 = "Only HTTP 1.0 / 1.1 requests"


/// The service name for the GET/POST filter service

public let serviceName_OnlyGetOrPost = "Only GET / POST requests"


/// The service name to determine the resource path from the URL service

public let serviceName_GetResourcePathFromUrl = "Get resource path from request URL"


/// The service name for the file content fetch/process service.

public let serviceName_GetFileAtResourcePath = "Get file at resource path"


/// The name by which service_getSession is known.

public let serviceName_GetSession = "Get Active Session"


/// The name by which service_decodePostFormUrlEncoded is known.

public let serviceName_DecodePostFormUrlEncoded = "Decode post form urlencoded"


/// The name by which service_waitUntilBodyComplete is known.

public let serviceName_WaitUntilBodyComplete = "Wait until body is received"


/// The name by which service_transferResponse is known.

public let serviceName_TransferResponse = "Transfer Response"


/// The name by which service_restartSessionTimeout is known.

public let serviceName_RestartSessionTimeout = "Restart Session Timeout"


// =================================================
// Add to the next function to register new services
// =================================================
// Notice that the sequence itself is not important


/// Registers services.
///
/// Add any newly defined services to this operation.

public func registerServices() {
    
    services.register(name: serviceName_Blacklist, service: service_blacklist)
    services.register(name: serviceName_OnlyHttp10OrHttp11, service: service_onlyHttp10or11)
    services.register(name: serviceName_OnlyGetOrPost, service: service_onlyGetOrPost)
    services.register(name: serviceName_GetResourcePathFromUrl, service: service_getResourcePathFromUrl)
    services.register(name: serviceName_GetFileAtResourcePath, service: service_getFileAtResourcePath)
    services.register(name: serviceName_GetSession, service: service_getSession)
    services.register(name: serviceName_DecodePostFormUrlEncoded, service: service_decodePostFormUrlEncoded)
    services.register(name: serviceName_WaitUntilBodyComplete, service: service_waitUntilBodyComplete)
    services.register(name: serviceName_TransferResponse, service: service_transferResponse)
    services.register(name: serviceName_RestartSessionTimeout, service: service_restartSessionTimeout)
}

