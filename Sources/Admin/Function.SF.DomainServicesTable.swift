// =====================================================================================================================
//
//  File:       Function.SF.DomainServicesTable.swift
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
// Returns a the html code containing the service table of the current domain.
//
//
// Signature:
// ----------
//
// .sf-domainServicesTable()
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
// - The table has class 'domain-services-table'
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

import Html
import Core


/// - Returns: A detail of the current domain.

func function_sf_domainServicesTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
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
    
    guard let domain = domains.domain(for: name) else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Prepare the table data
    
    struct TableRow {
        let rowIndex: Int
        let name: String
        let usedByDomain: Bool
    }
    
    var tableRows: Array<TableRow> = []
    
    var index: Int = 0
    for service in domain.serviceNames {
        tableRows.append(TableRow(rowIndex: index, name: service, usedByDomain: true))
        index += 1
    }
    
    OUTER: for service in services.registered {
        for row in tableRows {
            if row.name == service.key { continue OUTER }
        }
        tableRows.append(TableRow(rowIndex: tableRows.count, name: service.key, usedByDomain: false))
    }
    
    
    // Create the table
    
    let hidden = Input.hidden(name: "DomainName", value: domain.name)
    var table = Table(klass: ["domain-service-table"], columnTitles: "Index", "Seq.", "Service Name", "Used")

    for row in tableRows {
        
        let seqName = "seqName\(row.rowIndex)"
        let nameName = "nameName\(row.rowIndex)"
        let usedName = "usedName\(row.rowIndex)"
        
        let serviceNameHidden = Input.hidden(name: nameName, value: row.name)
        let sequenceEntry = Input.text(klass: ["seq-column"], name: seqName, value: row.rowIndex.description)
        var serviceName = Input.text(klass: ["name-column"], name: nameName, value: row.name)
        serviceName.disabled = true
        let usedCheckbox = Input.checkbox(klass: ["used-column"], name: usedName, value: usedName, checked: row.usedByDomain)
        
        table.appendRow(Td(row.rowIndex.description), Td(sequenceEntry), Td(serviceName, serviceNameHidden), Td(usedCheckbox))
    }
    
    let submitButton = Input.submit(klass: "service-submit-form", name: "Submit", title: "Update Services")
    let form = Form(method: .post, action: "/serveradmin/sfcommand/UpdateDomainServices", hidden, table, submitButton)
    
    return form.html.data(using: String.Encoding.utf8)
}


