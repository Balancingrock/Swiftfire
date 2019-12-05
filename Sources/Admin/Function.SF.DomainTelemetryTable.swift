// =====================================================================================================================
//
//  File:       Function.SF.DomainTelemetryTable.swift
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
//  License:    Use or redistribute this code any way you like with the following two provisions:
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
// Returns a the html code containing the telemetry table of the current domain.
//
//
// Signature:
// ----------
//
// .sf-domainTelemetryTable()
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
// CSS classes:
// - The table has class 'domain-telemetry-table'
//
//
// Returns:
// --------
//
// The requested table or "***Error" in case of error.
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


/// - Returns: A detail of the current domain.

func function_sf_domainTelemetryTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {

    
    // Check that a server admin is logged in
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        Log.atError?.log("Cannot get session")
        return htmlErrorMessage
    }
    
    guard let account = session.info.getAccount(inDomain: environment.domain) else {
        Log.atError?.log("Cannot get account")
        return htmlErrorMessage
    }
    
    guard serverAdminDomain.accounts.contains(account.name) else {
        Log.atError?.log("No admin logged in")
        return htmlErrorMessage
    }
    
    
    // Check that a valid domain name was specified
    
    guard let name = environment.request.info["domainname"] else { return htmlErrorMessage }
    
    guard let domain = domains.domain(for: name) else { return htmlErrorMessage }
    
    
    // Create the table
    
    var html: String = """
        <table class="domain-telemetry-table">
            <thead>
                <tr>
                    <th>Name</th><th>Value</th><th>Description</th>
                </tr>
            </thead>
            <tbody>
    """
    
    domain.telemetry.all.forEach { (row) in
        html += """
            <tr>
                <td class="table-column-name">\(row.name)</td>
                <td class="table-column-value">\(row.stringValue)</td>
                <td class="table-column-description">\(row.about)</td>
            <tr>
        """
    }
    
    html += """
            </tbody>
        </table>
    """
    
    return html.data(using: .utf8)
}

