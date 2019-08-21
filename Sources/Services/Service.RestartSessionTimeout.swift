// =====================================================================================================================
//
//  File:       Service.RestartSessionTimeout.swift
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
// 1.0.1 - Documentation update.
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import Http
import SwifterLog
import Core


/// Creates a session cookie with a (new) timeout. Only if sessions are enabled for the domain.
///
/// _Input_:
///    - domain.sessionTimeout: A session(-timeout) is requested when this value is > 1.
///    - info[.sessionKey]: The session ID for the cookie.
///
/// _Output_:
///    - response.cookies: A cookie will be added when necessary.
///
/// _Sequence_:
///    - Should come after Service.GetSession. However it should come close to the end of all services to ensure that possible errors have had their chances to prevent continuation of a session.

func service_restartSessionTimeout(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    
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
