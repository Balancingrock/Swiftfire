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
import Html


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
    
    var table = Table(klass: ["server-blacklist-table"], columnTitles: "Address", "Action", "")
    domain.blacklist.list.forEach { (address, action) in
        
        let addressCell = Td(address)
        
        let radioButtonClose = Input.radio(name: address, value: "close", checked: (action == .closeConnection))
        let radioButton503 = Input.radio(name: address, value: "503", checked: (action == .send503ServiceUnavailable))
        let radioButton401 = Input.radio(name: address, value: "401", checked: (action == .send401Unauthorized))
        let updateButton = Input.submit(title: "Update")
        let updateHidden = Input.hidden(name: "DomainName", value: domain.name)
        let updateForm = Form(method: .post, action: "/serveradmin/sfcommand/UpdateDomainBlacklist", radioButtonClose, " Close Connection, ", radioButton503, " 503 Service Unavailable, ", radioButton401, " 401 Unauthorized ", updateHidden, updateButton)
        let updateCell = Td(updateForm)
        
        let deleteButton = Input.submit(name: address, title: "Delete")
        let deleteHidden = Input.hidden(name: "DomainName", value: domain.name)
        let deleteForm = Form(method: .post, action: "/serveradmin/sfcommand/RemoveFromDomainBlacklist", deleteHidden, deleteButton)
        let deleteCell = Td(deleteForm)
        
        table.appendRow(addressCell, updateCell, deleteCell)
    }
    
    let textField = Input.text(name: "newEntry", value: "")
    let textDiv = Div("Address: ", textField)
    
    let radioButtonClose = Input.radio(name: "action", value: "close", checked: true)
    let radioButton503 = Input.radio(name: "action", value: "503", checked: false)
    let radioButton401 = Input.radio(name: "action", value: "401", checked: false)
    let radioDiv = Div(radioButtonClose, " Close Connection", Br(),
                       radioButton503, " 503 Service Unavailable", Br(),
                       radioButton401, " 401 Unauthorized")
    
    let createHidden = Input.hidden(name: "DomainName", value: domain.name)

    let submitButton = Input.submit(title: "Add to Blacklist")
    let submitDiv = Div(submitButton)
    
    let createForm = Form(klass: ["server-blacklist-create"], method: .post, action: "/serveradmin/sfcommand/AddToDomainBlacklist", textDiv, radioDiv, createHidden, submitDiv)
    
    return (table.html + Br().html + createForm.html).data(using: String.Encoding.utf8)
}
