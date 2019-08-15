// =====================================================================================================================
//
//  File:       Function.SF.DomainsTable.swift
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
// Returns a table with all domains.
//
//
// Signature:
// ----------
//
// .sf-domainsTable()
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
import Functions


/// Returns a table with all telemetry values.
///
/// - Returns: The table with all telemetry values.

func function_sf_domainsTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
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
    
    var domainsAndAliases: Dictionary<String, Array<String>> = [:]
    
    domains.domains.forEach {
        let alias = $0.key
        let name = $0.value.name
        if domainsAndAliases[name] != nil {
            domainsAndAliases[name]!.append(alias)
        } else {
            domainsAndAliases[name] = [alias]
        }
    }
    
    for key in domainsAndAliases.keys {
        let arr = domainsAndAliases[key]
        domainsAndAliases[key] = arr?.sorted(by: { $0 < $1 })
    }
    
    let list = domainsAndAliases.sorted(by: { $0.key < $1.key })
    
    
    var domainTables: Array<Html> = []
    
    list.forEach { (domainName: String, aliases: Array<String>) in
        
        var table = Table(klass: "domains-table", columnTitles: "Domain:", "\(domainName)")
        
        if aliases.count == 0 {
            table.append(Tr(Td("Aliases:"), Td(
                postingButtonedInput(target: "/serveradmin/sfcommand/CreateAlias", inputName: "Alias", inputValue: "", buttonTitle: "Create Alias", keyValuePairs: ["DomainName":domainName])
            )))
        } else {
            var firstAlias = true
            for alias in aliases {
                if alias != domainName {
                    table.append(Tr(firstAlias ? Td("Aliases:") : Td(), Td(
                        Div(
                            P(alias),
                            postingButton(target: "/serveradmin/sfcommand/DeleteAlias", title: "Delete Alias", keyValuePairs: ["Alias":alias])
                        )
                    )))
                    firstAlias = false
                }
            }
        }
        
        table.append(Tr(Td(), Td(
            postingButtonedInput(target: "/serveradmin/sfcommand/CreateAlias", inputName: "Alias", inputValue: "", buttonTitle: "Create Alias", keyValuePairs: ["DomainName":domainName])
        )))

        domainTables.append(table)
        domainTables.append(postingButton(target: "/serveradmin/pages/deletedomain.sf.html", title: "Delete Domain", keyValuePairs: ["DomainName":domainName]))
    }
    
    return Div(klass: "domains-list", domainTables.reduce("", { $0 + $1.html })).html.data(using: String.Encoding.utf8)
}


