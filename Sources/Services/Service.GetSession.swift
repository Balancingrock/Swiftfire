// =====================================================================================================================
//
//  File:       Service.GetSession.swift
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
import SwifterLog
import SwifterSockets
import Http
import Core


/// Retrieves or creates a session for this request. The session will be extracted from a cookie, or if there is no cookie a new session will be created.
///
/// _Input_:
///    - request.cookies: Will be checked for an existing session cookie.
///    - domain.sessions: Will be checked for an existing session, or a new session.
///    - domain.sessionTimeout: If the timeout < 1, then no session will be created.
///
/// _Output_:
///    - info[.sessionKey]: Session, if a session is needed. Nil if no session is needed.
///
/// _Sequence_:
///   - Can be one of the first services, does not need any predecessors.

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
