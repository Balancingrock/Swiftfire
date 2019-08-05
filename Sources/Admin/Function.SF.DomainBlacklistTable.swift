// =====================================================================================================================
//
//  File:       Function.SF.DomainBlacklistTable.swift
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
import Core


/// Returns the value of the requested parameter item.
///
/// - Returns: The value of the requested parameter or "No access rights".

func function_sf_domainBlacklistTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
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
    
    guard let domain = domains.domain(for: name) else { return "No domain error".data(using: String.Encoding.utf8) }

    
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
