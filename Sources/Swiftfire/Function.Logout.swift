// =====================================================================================================================
//
//  File:       Function.Logout.swift
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
// Removes the account from the session.
//
//
// Signature:
// ----------
//
// .logout()
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


/// Ensures that a session does not have an account associated with it.
///
/// Has no effect if no account is present.
///
/// - Returns: Always nil.

func function_logout(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
    // Find the session
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else { return nil }
    
    
    // Remove the account
    
    session.info.remove(key: .accountKey)
    
    
    // No data returned
    
    return nil
}
