// =====================================================================================================================
//
//  File:       Function.SF.DomainsTable.swift
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
// 1.3.0 - Removed inout from the function.environment signature
//       - Changed account handling
// 1.2.1 - Removed dependency on Html
// 1.0.0 - Raised to v1.0.0, Removed old change log,
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

import Core
import Functions


/// Returns a table with all telemetry values.
///
/// - Returns: The table with all telemetry values.

func function_sf_domainsTable(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    
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
    
    
    var html: String = """
        <div class="domains-list">
    """
    
    list.forEach { (domainName: String, aliases: Array<String>) in
        
        html += """
            <table class="domains-table">
                <thead><tr><th>Domain:</th><th>\(domainName)</th></tr></thead>
                <tbody>
        """
        
        if aliases.count == 0 {
            
            html += """
                <tr>
                    <td>Aliases:</td>
                    <td>
                        <form method="post" action="/serveradmin/sfcommand/CreateAlias" class="posting-buttoned-input-form">
                            <input type="hidden" name="DomainName" value="\(domainName)">
                            <input class="posting-buttoned-input-input" type="text" name="Alias" value=""</input>
                            <button type="submit" class="posting-buttoned-input-button">Create Alias</button>
                        </form>
                    </td>
                </tr>
            """
            
        } else {
            
            var firstAlias = true
            for alias in aliases {
                if alias != domainName {

                    html += """
                        <tr>
                            <td>\(firstAlias ? "Aliases:" : "")</td>
                            <td>
                                <div>
                                    <p>\(alias)</p>
                                    <form method="post" action="/serveradmin/sfcommand/DeleteAlias" class="posting-button-form">
                                        <button type="submit" name="Alias" value="\(alias)" class="posting-button-button">Delete Alias</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    """

                    firstAlias = false
                }
            }
        }
        
        html += """
                    <tr>
                        <td></td>
                        <td>
                            <form method="post" action="/serveradmin/sfcommand/CreateAlias" class="posting-buttoned-input-form">
                                <input type="hidden" name="DomainName" value="\(domainName)">
                                <input class="posting-buttoned-input-input" type="text" name="Alias" value=""</input>
                                <button type="submit" class="posting-buttoned-input-button">Create Alias</button>
                            </form>
                        </td>
                    </tr>
                </tbody>
            </table>
            <form method="post" action="/serveradmin/pages/deletedomain.sf.html" class="posting-button-form">
                <button type="submit" name="DomainName" value="\(domainName)" class="posting-button-button">Delete Domain</button>
            </form>
        """

    }
    
    html += """
        </div>
    """
    
    return html.data(using: .utf8)
}


