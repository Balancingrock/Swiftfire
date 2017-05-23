// =====================================================================================================================
//
//  File:       Function.SF.DomainTelemetryTable.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
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
// 0.10.7 - Initial release
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
// service[.postInfoKey]["DomainName"] must contain the name of an existing domain.
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


/// - Returns: A detail of the current domain.

func function_sf_domainTelemetryTable(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {

    
    // Check that a server admin is logged in
    
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
        let name = postInfo["DomainName"] else { return "***Error***".data(using: String.Encoding.utf8) }
    
    guard let domain = domains.domain(forName: name) else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Create the table
    
    var table: String = "<table class=\"domain-telemetry-table\"><thead><tr><th>Name</th><th>Value</th><th>Description</th><tr></thead><tbody>"
    domain.telemetry.all.forEach() { table.append($0.tableRow()) }
    table.append("</tbody></table>")
    
    return table.data(using: String.Encoding.utf8)    
}

fileprivate extension NamedValueProtocol {
    
    func tableRow() -> String {
        return "<tr><td class=\"table-column-name\">\(self.name)</td><td class=\"table-column-value\">\(self.stringValue)</td><td class=\"table-column-description\">\(self.about)</td></tr>"
    }
}

