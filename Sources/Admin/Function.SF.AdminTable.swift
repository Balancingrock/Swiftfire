// =====================================================================================================================
//
//  File:       Function.SF.AdminTable.swift
//  Project:    Swiftfire
//
//  Version:    1.2.0
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
// 1.2.0 - Initial version
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Returns a table with all admin account.
//
//
// Signature:
// ----------
//
// .sf-adminTable()
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
// The table with all admin accounts or:
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
import Functions


/// Returns a table with all telemetry values.
///
/// - Returns: The table with all telemetry values.

func function_sf_adminTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
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
    
    
    // Create a list of domains and their aliases
    
    var table = Table(klass: "default-table", columnTitles: ["Account ID", "", ""])
    for accountName in environment.domain.accounts {

        if accountName != account.name {
            table.append(Tr(
                Td(
                    P(klass: "half-margins-no-padding", accountName)
                ),
                Td(
                    postingButton(target: "/serveradmin/sfcommand/ConfirmDeleteAccount", title: "Delete", keyValuePairs: ["ID":accountName])
                ),
                Td(
                    postingButtonedInput(target: "/serveradmin/sfcommand/SetNewPassword", inputName: "Password", inputValue: "", buttonTitle: "Set New Password", keyValuePairs: ["ID": accountName])
                )
            ))
        } else {
            table.append(Tr(
                Td(
                    P(klass: "half-margins-no-padding", accountName)
                ),
                Td(),
                Td(
                    postingButtonedInput(target: "/serveradmin/sfcommand/SetNewPassword", inputName: "Password", inputValue: "", buttonTitle: "Set New Password", keyValuePairs: ["ID": accountName])
                )
            ))
        }
    }
    
    return table.html.data(using: String.Encoding.utf8)
}


