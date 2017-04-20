// =====================================================================================================================
//
//  File:       Service.GetSession.swift
//  Project:    Swiftfire
//
//  Version:    0.10.6
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
// 0.10.6 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Retrieves the session for the HTTP request (via a cookie) if it has any and if the session is still active.
// If an active session is present in the request, it will add the session-id cookie to the reponse with a timeout
// as specified for the domain.
//
// Input:
// ------
//
// request: The HTTP request. Will be tested for the existence of a cookie with a session ID.
// Session: The active session list. If a session ID cookie was found, it will be tested for an active session.
// domain.sessionTimeout: If < 1, then session support is disabled. On > 0 the max-age for the cookie with the session
//    ID will be set to this value.
//
//
// Output:
// -------
//
// info[sessionKey] = Active session.
// response: Will contain a set-cookie with the session ID and a timeout.
//
//
// Return:
// -------
//
// .next
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwiftfireCore
import SwifterSockets


/// Checks if the client IP address is in the domain.blacklist.
///
/// - Note: For a full description of all effects of this operation see the file: DomainService.GetFileAtResourcePath.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The HttpConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abort, on success .next.

func service_getSession(_ request: HttpRequest, _ connection: Connection, _ domain: Domain, _ info: inout Service.Info, _ response: inout HttpResponse) -> Service.Result {

    
    // The connection is a SFConnection
    
    guard let connection = connection as? SFConnection else {
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Failed to cast Connection as SFConnection")
        response.code = HttpResponseCode.code500_InternalServerError
        return .abort
    }

    
    // Is the session timeout valid?
    
    if domain.sessionTimeout < 1 { return .next }
    
    
    // Find all session cookies (there should be only 1)
    
    let sessionCookies = request.cookies.filter({ $0.name == Session.cookieId })
    
    Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Found: \(sessionCookies.count) session cookie(s)")

    
    // If there is more than 1, pick the first active cookie.
    
    for sessionCookie in sessionCookies {
        
        if let id = UUID(uuidString: sessionCookie.value) {
            
            var blockedCounter = 0
            
            WAIT_FOR_SESSION: while true {

                switch domain.sessions.getActiveSession(for: id, logId: connection.logId) {
            
                case .none:
                    
                    break WAIT_FOR_SESSION
            
                    
                case .blocked:
                    
                    // When this occurs, the user has send off too many requests at once.
                    // While this could happen in some scenario's, its not normal if this causes a big lag in user feedback.
                    // Hence a fixed timeout of 60 seconds is applied here to try and recover at least the server side of things.
                    
                    blockedCounter += 1
                    if blockedCounter > 60 {
                        
                        Log.atCritical?.log(id: connection.logId, source: #file.source(#function, #line), message: "Timeout while waiting for session (with id = \(id.uuidString)) to become free.")
                        response.code = HttpResponseCode.code500_InternalServerError
                        return .abort
                        
                    } else {
                        sleep(1)
                    }

                    
                case .success(let session):
                
                    Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Received active session \(session)")

                    if parameters.debugMode.value {
                
                        // Add this event to the session debug information
                
                        session.addDebugInfo(address: connection.remoteAddress, domainName: domain.name, connectionId: Int(connection.objectId), allocationCount: Int64(connection.allocationCount))
                    }
                    
                
                    // Store the session in the info object
                
                    info[.sessionKey] = session
                
                
                    // Add the cookie to the response
                
                    let timeout = HttpCookie.Timeout.maxAge(domain.sessionTimeout)
                    let cookie = HttpCookie(name: Session.cookieId, value: session.id.uuidString, timeout: timeout)
                    response.cookies.append(cookie)
                
                
                    return .next
                }
            }
        }
    }
    
    Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "No active session found")

    return .next
}
