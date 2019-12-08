// =====================================================================================================================
//
//  File:       Function.SF.DomainsMenu.swift
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


/// - Returns: A menu for the navbar containing all the domains as submenu items.

func function_sf_domainsMenu(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
        
    var html: String = """
        <div class="item-separator"><p><!-- empty but necessary! --></p></div>
        <div class="item">
            <input id="domain-checkbox" type="checkbox">
            <div class="title">
                <label class="symbol" for="domain-checkbox">
                    <p class="code"><!-- will be filled by disclosure indicator --></p>
                </label>
                <div class="text"><a href="/serveradmin/pages/domain-management.sf.html"><p>Domains</p></a></div>
            </div>
            <div class="dropdown">
                <div class="subitem-separator"><p><!-- empty but necessary! --></p></div>
                <div class="subitem">
                    <input type="checkbox" id="DomainManagement-checkbox">
                    <div class="title">
                        <label class="symbol" for="DomainManagement-checkbox">
                            <p></p>
                        </label>
                        <div class="text"><a href="/serveradmin/pages/domain-management.sf.html"><p>Manage Domains</p></a></div>
                    </div>
                </div>
    """

    for domain in domainManager {
        html += """
            <div class="subitem-separator"><p><!-- empty but necessary! --></p></div>
            <div class="subitem">
                <input type="checkbox" id="\(domain.name)-checkbox">
                <div class="title">
                    <label class="symbol" for="\(domain.name)-checkbox">
                        <p></p>
                    </label>
                    <div class="text">
                        <form class="posting-link-form" method="post" action="/serveradmin/pages/domain.sf.html">
                            <button type="submit" name="DomainName" value="\(domain.name)" class="posting-link-button">\(domain.name)</button>
                        </form>
                    </div>
                </div>
            </div>
        """
    }
    
    html += """
            </div>
        </div>
    """
    
    return html.data(using: .utf8)
}

