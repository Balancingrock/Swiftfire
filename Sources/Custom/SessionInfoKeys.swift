// =====================================================================================================================
//
//  File:       SessionInfoKeys.swift
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


/// Keys for the Session Info dictionary. The session info directory can be found in the serviceInfo dictionary using the `sessionKey`.
///
/// Every key defined here should be documented as to the type of information and the purpose of that information.

public enum SessionInfoKey: String {
    
    // The following definitions are needed by the core Swiftfire framework
    
    
    /// The account associated with this session. It is only present if a user has logged-in.
    ///
    /// Note: It is currently only used for server-admin accounts. But will be used in the future for domain admins and user accounts as well.
    ///
    /// __Type__: Account
    ///
    /// __Set by__: Service.ServerAdmin (for server admin accounts only)
    ///
    /// __Used by__: Services.ServerAdmin (for server admin accounts only)
    
    case accountKey = "Account"
    
    
    /// The URL that was requested, but discarded because a user needed to login first. This key can be used to immediately redirect the user to the requested page after he has logged-in.
    ///
    /// Note: It is currently only used for server-admin accounts. But will be used in the future for domain admins and user accounts as well.
    ///
    /// __Type__: String
    ///
    /// __Set by__: Service.ServerAdmin (for server admin accounts only)
    ///
    /// __Used by__: Services.ServerAdmin (for server admin accounts only)

    case preLoginUrlKey = "PreLoginUrl"
    
    
    /// Time of last login attempt. This is used to enforce a minimum delay between login attempts. This helps in preventing brute force attacks.
    ///
    /// __Type__: Int64, intepreted as a javaDate, in milli seconds since 1 jan 1970.
    ///
    /// __Set by__: Service.ServerAdmin (for server admin accounts only)
    ///
    /// __Used by__: Services.ServerAdmin (for server admin accounts only)

    case lastFailedLoginAttemptKey = "LastFailedLoginAttempt"
    
    
    // =================================================================
    // Don't make any changes above this line, add new definitions below
    // =================================================================
    
    
}
