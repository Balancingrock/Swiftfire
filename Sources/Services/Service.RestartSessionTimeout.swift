// =====================================================================================================================
//
//  File:       Service.RestartSessionTimeout.swift
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
// If a session is active (i.e. present in the 'info') then it will add a session cookie to restart the timeout for
// the session.
//
// This service should appear after "getSession". There should be no time consuming services after this one.
//
// Input:
// ------
//
// domain.sessionTimeout: If < 1, then session support is disabled.
// info[.sessionKey] = Active session.
//
//
// Output:
// -------
//
// response.cookies: A new cookie has been added for the session timeout.
//
//
// Return:
// -------
//
// .next
//
// =====================================================================================================================

import Foundation

import Http
import SwifterLog
import Core


/// Ensures that a session exists if the sessionTimeout for the given domain is > 0.
///
/// - Note: For a full description of all effects of this operation see the file: Service.RestartSessionTimeout.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next.

func service_restartSessionTimeout(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {
    
    
    // Check if session support is enabled
    
    guard domain.sessionTimeout >= 1 else { return .next }


    // If a session is present, set the cookie request in the response to restart the session timeout

    if let session = info[.sessionKey] as? Session {
        if session.isActiveKeepActive {
            response.cookies.append(session.cookie)
            Log.atDebug?.log("Session cookie added to response with id = \(session.id.uuidString)", id: connection.logId)
        }
    }
    
    return .next
}
