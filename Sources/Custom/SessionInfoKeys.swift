// =====================================================================================================================
//
//  File:       SessionInfoKeys.swift
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

import Foundation


/// Session Info key's

public enum SessionInfoKey: String {
    
    // The following definitions are needed by the core Swiftfire framework
    
    /// [Account] The account associated with this session.
    ///
    /// Only present if a user has "logged in".
    
    case accountKey = "Account"
    
    
    /// [String] The url that was requested but discarded because a user needed to login first.
    
    case preLoginUrlKey = "PreLoginUrl"
    
    
    /// [Int64] To prevent login attempts in rapid succession use this key to enfore a minimum delay between attempts.
    
    case lastFailedLoginAttemptKey = "LastFailedLoginAttempt"
    
    
    // =================================================================
    // Don't make any changes above this line, add new definitions below
    // =================================================================
    
    
}
