// =====================================================================================================================
//
//  File:       Function.SF.DomainsMenu.swift
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


/// - Returns: A menu for the navbar containing all the domains as submenu items.

func function_sf_domainsMenu(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
    // Build the menu for the domains
    
    var menu: String = ""
    +   "<input type=\"checkbox\" id=\"domains-checkbox\">"
    +   "<label for=\"domains-checkbox\">"
    +       "<div class=\"menu-item-separator\"><p><!-- empty but necessary --></p></div>"
    +       "<div class=\"menu-item\">"
    +           "<div class=\"menu-item-symbol\"><p><!-- empty but necessary! --></p></div>"
    +           "<div class=\"menu-item-title\"><p>Domains</p></div>"
    +       "</div>"
    +   "</label>"
    +   "<ul>"
    +       "<li>"
    +           "<div class=\"menu-subitem\">"
    +               "<div class=\"menu-subitem-symbol\"></div>"
    +               "<div class=\"menu-subitem-title\">"
    +                   "<a href=\"/serveradmin/pages/domain-management.sf.html\"><p>Manage Domains</p></a>"
    +               "</div>"
    +           "</div>"
    +       "</li>"

    for domain in domains {

        menu += "<li><div class=\"menu-subitem\"><div class=\"menu-subitem-symbol\"></div><div class=\"menu-subitem-title\">"
        
        menu += postingLink(target: "/serveradmin/pages/domain.sf.html", text: domain.name, keyValuePairs: ["DomainName": domain.name])
        
        menu += "</div></div></li>"
    }
    
    menu += "</ul>"

    return menu.data(using: String.Encoding.utf8)
}

