// =====================================================================================================================
//
//  File:       Function.GetSession.swift
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
// Signature:
// ----------
//
// .getSession()
//
//
// Parameters:
// -----------
//
// None.
//
//
// Other Input:
// ------------
//
// environment.request: The HTTP request. Will be tested for the existence of a cookie with the session ID.
// environment.domain.sessions: The active session list. If a session ID cookie was found, it will be tested for an active session.
// environment.domain.sessionTimeout: If < 1, then session support is disabled.
//
//
// Returns:
// --------
//
// nil
//
//
// Other Output:
// -------------
//
// environment.info[.sessionKey] = Session // => Active session.
//
//
// =====================================================================================================================

import Foundation

import Core


/// Ensures that a session exists.
///
/// If no session is found a new session will be created.
///
/// - Returns: Always nil.

public func function_getSession(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {

    
    // Find or create the session
    
    
    //_ = service_getSession(environment.request, environment.connection, environment.domain, &environment.serviceInfo, &environment.response)
    
    
    // No data returned
    
    return nil
}
