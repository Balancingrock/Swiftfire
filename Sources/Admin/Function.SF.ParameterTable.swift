// =====================================================================================================================
//
//  File:       Function.SF.ParameterTable.swift
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
// Returns a table with all parameter values including buttons to update the parameters.
//
//
// Signature:
// ----------
//
// .sf-parameterTable()
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
// session = environment.serviceInfo[.sessionKey] // Must be a non-expired session.
// session[.accountKey] must contain an admin account
//
//
// Returns:
// --------
//
// The table with all parameters or:
// - "Session error"
// - "Account error"
// - "Illegal access"
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

func function_sf_parameterTable(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {


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

    
    // Create the table
    
    var table = Table(klass: ["parameter-table"], header: Thead(titles: "Name", "Value", "Description"))
    parameters.all.forEach() { if $0.name != parameters.adminSiteRoot.name { table.append($0.tableRow()) }}
  
    return table.html.data(using: String.Encoding.utf8)
}

fileprivate extension NamedValueProtocol {
    
    func tableRow() -> Tr {
        let nameCell = Td(self.name)

        let textField = Input.text(name: self.name, value: self.stringValue)
        let submitButton = Input.submit(title: "Update")
        let form = Form(method: .post, action: "/serveradmin/sfcommand/SetParameter", textField, submitButton)
        let valueCell = Td(form)
        
        let aboutCell = Td(self.about)
        
        return Tr(nameCell, valueCell, aboutCell)
    }
}

