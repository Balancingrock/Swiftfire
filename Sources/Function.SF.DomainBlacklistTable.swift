// =====================================================================================================================
//
//  File:       Function.SF.DomainBlacklistTable.swift
//  Project:    Swiftfire
//
//  Version:    0.10.9
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.9 - Initial release
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
// environment.serviceInfo[.postInfoKey]["DomainName"] // must contain the name of an existing domain.
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


/// Returns the value of the requested parameter item.
///
/// - Returns: The value of the requested parameter or "No access rights".

func function_sf_domainBlacklistTable(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
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
    
    
    // Check that a valid domain name was specified
    
    guard let postInfo = environment.serviceInfo[.postInfoKey] as? PostInfo,
        let name = postInfo["DomainName"] else { return "Domain name error".data(using: String.Encoding.utf8) }
    
    guard let domain = domains.domain(forName: name) else { return "No domain error".data(using: String.Encoding.utf8) }

    
    // Create the table
    
    var table: String = "<table class=\"domain-blacklist-table\"><thead><tr><th>Address</th><th>Action</th><th></th><tr></thead><tbody>"
        domain.blacklist.list.forEach { (address, action) in
        table += "<tr><td>\(address)</td><td>"
        table += "<form action=\"/serveradmin/sfcommand/UpdateDomainBlacklist\" method=\"post\"><input type=\"hidden\" name=\"DomainName\" value=\"\(domain.name)\"><input type=\"radio\" name=\"\(address)\" value=\"close\" \(action == .closeConnection ? "checked" : "")> Close Connection, <input type=\"radio\" name=\"\(address)\" value=\"503\" \(action == .send503ServiceUnavailable ? "checked" : "")> 503 Service Unavailable, <input type=\"radio\" name=\"\(address)\" value=\"401\" \(action == .send401Unauthorized ? "checked" : "")> 401 Unauthorized <input type=\"submit\" name=\"submit\" value=\"Update\"></form>"
        table += "</td><td><form action=\"/serveradmin/sfcommand/RemoveFromDomainBlacklist\" method=\"post\"><input type=\"hidden\" name=\"DomainName\" value=\"\(domain.name)\"><input type=\"submit\" name=\"\(address)\" value=\"Delete\"></form></td></tr>"
    }
    table.append("</tbody></table></br>")
    
    let newEntry = "<form class=\"domain-blacklist-create\" action=\"/serveradmin/sfcommand/AddToDomainBlacklist\" method=\"post\"><input type=\"hidden\" name=\"DomainName\" value=\"\(domain.name)\"><div>Address: <input type=\"text\" name=\"newEntry\" value=\"\"></div>Action:<div><input type=\"radio\" name=\"action\" value=\"close\" checked> Close Connection</br><input type=\"radio\" name=\"action\" value=\"503\"> 503 Service Unavailable</br><input type=\"radio\" name=\"action\" value=\"401\"> 401 Unauthorized</div><div><input type=\"submit\" name=\"submit\" value=\"Add to Blacklist\"></div></form>"
    
    return (table + newEntry).data(using: String.Encoding.utf8)
}
