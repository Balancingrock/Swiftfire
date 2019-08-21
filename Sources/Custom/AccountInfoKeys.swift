// =====================================================================================================================
//
//  File:       AccountInfoKeys.swift
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
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.1 - Added more comments
//       - Made all keys public static
// 1.0.0 - Removed old change log,
//
// =====================================================================================================================

import Foundation

import BRBON


/// Keys to be used in the AccountInfo [BRBON](http://swiftfire.nl/projects/brbon/brbon.html) object.
///
/// Every account has an associated AccountInfo BRBON object that contains the information that belongs to that account. While there are some predefined items, any website developper can create additional items. The keys to this information as well as the type of information (and possibly its uses) should be defined in this class.

public class AccountInfoKey {
    
    // The Swiftfire core needs the following definitions
    
    /// The date the user was created, in msec since begin 1970.
    ///
    /// Type: Int64, interpreted as a javaDate
    ///
    /// _not supported yet_
    
    public static let created = NameField("Created")!
    
    
    /// The date the user was last logged in, in mSec since begin 1970.
    ///
    /// Type: Int64, interpreted as a javaDate
    ///
    /// _not supported yet_

    public static let lastLogin = NameField("LastLogin")!
    
    
    /// If 'true' then auto login is enabled and a cookie will be used to retrieve the password. Otherwise the user will need to log in explicitly.
    ///
    /// Type: Bool
    ///
    /// _not supported yet_

    public static let autoLogin = NameField("AutoLogin")!
    
    
    /// The email address of the user.
    ///
    /// Type: String
    ///
    /// _not supported yet_

    public static let email = NameField("Email")!
    
    
    // =================================================================
    // Don't make any changes above this line, add new definitions below
    // =================================================================
    
    
    // Add non-framework definitions below
    
}
