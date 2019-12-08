// =====================================================================================================================
//
//  File:       Function.SF.DomainBlacklistTable.swift
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
//       - Removed inout from the function.environment signature
//       - Changed account handling
// 1.2.1 - Removed dependency on Html
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Returns a table with all blacklisted addresses for a domain.
//
//
// Signature:
// ----------
//
// .sf-domainBlacklistTable()
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
// environment.request.info["DomainName"] // must contain the name of an existing domain.
// session = environment.serviceInfo[.sessionKey] // Must be a non-expired session.
// session[.accountKey] must contain an admin account
//
//
// Returns:
// --------
//
// The table with all blacklisted addresses or:
// - "Session error"
// - "Account error"
// - "Illegal access"
// - "Domain name error"
// - "No domain error"
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

func function_sf_domainBlacklistTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    
    // Check access rights
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        return "Session error".data(using: String.Encoding.utf8)
    }
    
    guard let account = session.info.getAccount(inDomain: environment.domain) else {
        return "Account error".data(using: String.Encoding.utf8)
    }
    
    guard serverAdminDomain.accounts.contains(account.name) else {
        return "Illegal access".data(using: String.Encoding.utf8)
    }
    
    
    // Check that a valid domain name was specified
    
    guard let name = environment.request.info["domainname"] else { return "Domain name error".data(using: String.Encoding.utf8) }
    
    guard let domain = domainManager.domain(for: name) else { return "No domain error".data(using: String.Encoding.utf8) }

    
    // Create the table
    
    var html: String = """
        <table class="server-blacklist-table">
            <thead>
                <tr>
                    <th>Address</th>
                    <th>Action</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
    """
    
    let list = domain.blacklist.list.keys.sorted(by: { $0 < $1 })
    
    list.forEach { (address) in
        
        let action = domain.blacklist.action(for: address)
        
        html += """
            <tr>
                <td>\(address)</td>
                <td>
                    <form method="post" action="/serveradmin/sfcommand/UpdateDomainBlacklist">
                        <input type="hidden" name="Address" value="\(address)">
                        <input type="radio" name="Action" value="close" \(action == .closeConnection ? "checked" : "")>
                        <span> Close Connection, </span>
                        <input type="radio" name="Action" value="503" \(action == .send503ServiceUnavailable ? "checked" : "")>
                        <span> 503 Service Unavailable, </span>
                        <input type="radio" name="Action" value="401" \(action == .send401Unauthorized ? "checked" : "")>
                        <span> 401 Unauthorized </span>
                        <input type="hidden" name="DomainName" value="\(domain.name)">
                        <input type="submit" value="Update">
                    </form>
                </td>
                <td>
                    <form method="post" action="/serveradmin/sfcommand/RemoveFromDomainBlacklist">
                        <input type="hidden" name="Address" value="\(address)">
                        <input type="hidden" name="DomainName" value="\(domain.name)">
                        <input type="submit" value="Delete">
                    </form>
                </td>
            </tr>
        """
    }
    
    html += """
            </tbody>
        </table>
        <br>
        <form class="server-blacklist-create" method="post" action="/serveradmin/sfcommand/AddToDomainBlacklist">
            <input type="hidden" name="DomainName" value="\(domain.name)">
            <div>
                <span>Address: </span>
                <input type="text" name="NewEntry" value="">
            </div>
            <div>
                <input type="radio" name="Action" value="close" checked>
                <span> Close Connection, </span>
                <input type="radio" name="Action" value="503">
                <span> 503 Service Unavailable, </span>
                <input type="radio" name="Action" value="401">
                <span> 401 Unauthorized </span>
            </div>
            <div>
                <input type="submit" value="Add to Blacklist">
            </div>
        </form>
    """
        
    return html.data(using: .utf8)
}
