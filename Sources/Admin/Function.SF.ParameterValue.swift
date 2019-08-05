// =====================================================================================================================
//
//  File:       Function.SF.ParameterValue.swift
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
// Returns the value of the requested parameter item.
//
//
// Signature:
// ----------
//
// .parameterValue("name")
//
//
// Parameters:
// -----------
//
// - name: The name of the parameter item.
//
//
// Other Input:
// ------------
//
// session = environment.serviceInfo[.sessionKey] // Must be a non-expired session.
// session[.accountKey] must contain an admin account
//
//
// Returns:
// --------
//
// The value of the requested parameter or one of the error messages:
// - "<name> is unknown"
// - "Illegal access"
// - "Argument type error"
// - "Nof arguments error"
// - "Session error"
// - "Account error"
//
//
// Other Output:
// -------------
//
// None.
//
//
// =====================================================================================================================

import Foundation

import Core


/// Returns the value of the requested parameter item.
///
/// - Returns: The value of the requested parameter or "No access rights".

func function_sf_parameterValue(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
    // Check access rights
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        return "Session error".data(using: String.Encoding.utf8)
    }
    
    guard let account = session.info[.accountKey] as? Account else {
        return "Account error".data(using: String.Encoding.utf8)
    }
    
    guard serverAdminDomain.accounts.contains(account.uuid) else {
        return "Illegal access".data(using: String.Encoding.utf8)
    }
    
    
    // Check parameter name
    
    guard case .array(let arr) = args else {
        return "Argument type error".data(using: String.Encoding.utf8)
    }
    
    guard arr.count == 1 else {
        return "Nof arguments error".data(using: String.Encoding.utf8)
    }
    
    let name = arr[0]
    
    var value: String?
    
    for t in serverParameters.all {
        
        if t.name.caseInsensitiveCompare(name) == ComparisonResult.orderedSame {
            value = t.stringValue
            break
        }
    }
    
    guard value != nil else {
        return "\(name) is unknown".data(using: String.Encoding.utf8)
    }
    
    
    // Return the value
    
    return value!.data(using: String.Encoding.utf8)
}
