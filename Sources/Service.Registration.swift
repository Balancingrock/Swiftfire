// =====================================================================================================================
//
//  File:       DomainServices.Registration.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.7 - Added getSession to the default list of services
// 0.10.6 - Renamed services
//        - Added getSession
// 0.10.0 - Removed import of SwifterSockets
//        - Moved ChainInfo key's to SwifterCore.DomainServices
// 0.9.18 - Renamed closure to service in register call
//        - Header update
// 0.9.15 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Contains the registration of domain services and a default service list for new domains.
//
// =====================================================================================================================

import Foundation


// ==============================================
// Descriptions for the available domain services
// ==============================================

// Note: If any of these texts are changed it will be necessary to re-assign new services for existing domains.

private let blacklist = "Abort if client IP is in blacklist"
private let onlyHttp10OrHttp11 = "Only HTTP 1.0 / 1.1 requests"
private let onlyGetOrPost = "Only GET / POST requests"
private let getResourcePathFromUrl = "Get resource path from request URL"
private let getFileAtResourcePath = "Get file at resource path"
private let getSession = "Get Active Session"
private let serverAdmin = "Handle server Admin Domain"
private let decodePostFormUrlEncoded = "Decode post form urlencoded"


// =================================================
// Add to the next function to register new services
// =================================================
// Notice that the sequence itself is not important

/// Register the domain services

func registerServices() {
    
    services.register(name: blacklist, service: service_blacklist)
    services.register(name: onlyHttp10OrHttp11, service: service_onlyHttp10or11)
    services.register(name: onlyGetOrPost, service: service_onlyGetOrPost)
    services.register(name: getResourcePathFromUrl, service: service_getResourcePathFromUrl)
    services.register(name: getFileAtResourcePath, service: service_getFileAtResourcePath)
    services.register(name: getSession, service: service_getSession)
    services.register(name: serverAdmin, service: service_serverAdmin)
    services.register(name: decodePostFormUrlEncoded, service: service_decodePostFormUrlEncoded)
}


// ========================================================================
// Add to the next array to provide a default service chain for NEW domains
// ========================================================================
// Notice that the sequence is very important

/// Default services for newly created domains (implements a static webserver)

var defaultServices: Array<String> {
    return [
        blacklist,
        onlyHttp10OrHttp11,
        onlyGetOrPost,
        getSession,
        decodePostFormUrlEncoded,
        getResourcePathFromUrl,
        getFileAtResourcePath
    ]
}


/// The services for the server admin (pseudo) domain
///

var serverAdminServices: Array<String> {
    return [
        getSession,
        decodePostFormUrlEncoded,
        serverAdmin
    ]
}
