// =====================================================================================================================
//
//  File:       Function.SF.DomainTelemetryTable.swift
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

import Html
import Core


/// - Returns: A detail of the current domain.

func function_sf_domainTelemetryTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {

    
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
    
    
    // Create the table
    
    var table = Table(klass: "domain-telemetry-table", columnTitles: "Name", "Value", "Description")
    domain.telemetry.all.forEach() { table.append($0.tableRow()) }
    
    return table.html.data(using: String.Encoding.utf8)
}

fileprivate extension NamedValueProtocol {
    
    func tableRow() -> Tr {
        let nameCell = Td(klass: "table-column-name", self.name)
        let valueCell = Td(klass: "table-column-value", self.stringValue)
        let aboutCell = Td(klass: "table-column-description", self.about)
        return Tr(nameCell, valueCell, aboutCell)
    }
}

