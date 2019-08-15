// =====================================================================================================================
//
//  File:       AccountInfoKeys.swift
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
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import BRBON


/// User Info key's

public class AccountInfoKey {
    
    // The Swiftfire core needs these definitions
    
    /// [Int64] The date the user was created, in msec since begin 1970.
    
    let created = NameField("Created")!
    
    
    /// [Int64] The date the user was last logged in, in mSec since begin 1970.
    
    let lastLogin = NameField("LastLogin")!
    
    
    /// [Bool] If 'true' then auto login is enabled.
    
    let autoLogin = NameField("AutoLogin")!
    
    
    /// [String] The email address of the user.
    
    let email = NameField("Email")!
    
    
    // =================================================================
    // Don't make any changes above this line, add new definitions below
    // =================================================================
    
    
    // Add non-framework definitions below
    
}
