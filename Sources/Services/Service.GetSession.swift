// =====================================================================================================================
//
//  File:       Service.GetSession.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Retrieves the session for the HTTP request (via a cookie) if it has any and if the session is still active. If no
// active session is found, it will create a new session.
//
//
// Input:
// ------
//
// request: The HTTP request. Will be tested for the existence of a cookie with the session ID.
// domain.sessions: The active session list. If a session ID cookie was found, it will be tested for an active session.
// domain.sessionTimeout: If < 1, then session support is disabled.
//
//
// Output:
// -------
//
// info[.sessionKey] = Active session.
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
import SwifterSockets
import Http
import Core


/// Ensures that a session exists if the sessionTimeout for the given domain is > 0.
///
/// - Note: For a full description of all effects of this operation see the file: Service.GetSession.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next.

func service_getSession(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {

    
    // Check if session support is enabled
    
    if domain.sessionTimeout < 1 { return .next }
    
    
    // Find all session cookies (there should be only 1)
    
    let sessionCookies = request.cookies.filter({ $0.name == Session.cookieId })
    
    Log.atDebug?.log("Found: \(sessionCookies.count) session cookie(s)", id: connection.logId)

    
    
    // If there is more than 1, pick the first active cookie.
    
    for sessionCookie in sessionCookies {
        
        if let id = UUID(uuidString: sessionCookie.value) {
            
            if let session = domain.sessions.getActiveSession(for: id, logId: connection.logId) {
                
                Log.atDebug?.log("Received active session with id: \(id)", id: connection.logId)
                
                if serverParameters.debugMode.value {
                    
                    // Add this event to the session debug information
                    
                    session.addActivity(address: connection.remoteAddress, domainName: domain.name, connectionId: Int(connection.objectId), allocationCount: connection.allocationCount)
                }
                
                
                // Store the session in the info object
                
                info[.sessionKey] = session
                
                return .next
                
            } else {
                
                Log.atDebug?.log("Session with id: \(id) has expired", id: connection.logId)
            }
        }
    }
    
    
    // No cookie with an active session found, create a new session
    
    if let session = domain.sessions.newSession(
        address: connection.remoteAddress,
        domainName: domain.name,
        logId: connection.logId,
        connectionId: connection.objectId,
        allocationCount: connection.allocationCount,
        timeout: domain.sessionTimeout
        ) {
    
    
        // Store the session in the info object
    
        info[.sessionKey] = session

        Log.atDebug?.log("No active session found, created new session with id: \(session.id.uuidString)", id: connection.logId)
        
    } else {
        
        // Error
        
        Log.atCritical?.log("No active session found, failed to create new session", id: connection.logId)
    }
    
    return .next
}
