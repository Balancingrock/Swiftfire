// =====================================================================================================================
//
//  File:       Function.SF.DeleteDomain.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Replaced postInfo with request.info
//       - Removed old comments
//       - Removed inout from the function.environment signature
//       - Changed account handling
// 1.2.1 - Removed dependency on Html
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Returns the button that can be sued to delete a domain.
//
//
// Signature:
// ----------
//
// .sf-deleteDomain()
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
// request.info["DomainName"] must contain the name of an existing domain.
//
//
// Returns:
// --------
//
// The requested button code or "***Error***" in case of error.
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

import SwifterLog
import Core


/// - Returns: A button with an action to remove a domain.

func function_sf_deleteDomain(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    
    // Check that a server admin is logged in
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        Log.atError?.log("No session found", from: Source(id: -1, file: #file, function: #function, line: #line))
        return "***Error***".data(using: String.Encoding.utf8)
    }
    
    guard let account = session.info[.accountKey] as? Account else {
        Log.atError?.log("No account found", from: Source(id: -1, file: #file, function: #function, line: #line))
        return "***Error***".data(using: String.Encoding.utf8)
    }
    
    guard serverAdminDomain.accounts.contains(account.name) else {
        Log.atError?.log("Not an admin account: '\(account.name)'", from: Source(id: -1, file: #file, function: #function, line: #line))
        return "***Error***".data(using: String.Encoding.utf8)
    }
    
    
    // Check that a valid domain name was specified
    
    guard let name = environment.request.info["DomainName"] else {
            Log.atError?.log("Missing DomainName", from: Source(id: -1, file: #file, function: #function, line: #line))
            return "***Error***".data(using: String.Encoding.utf8)
    }
    
    guard domains.contains(name) else {
        Log.atError?.log("Domain with name \(name) does not exist", from: Source(id: -1, file: #file, function: #function, line: #line))
        return "***Error***".data(using: String.Encoding.utf8)
    }
    
    
    // Return the button code

    return """
        <form class="posting-button-form" method="post" action="/serveradmin/sfcommand/DeleteDomain">
            <button class="posting-button-button" type="submit" name="DomainName" value="\(name)">Delete Domain \(name)</button>
        </form>
    """.data(using: .utf8)
}
