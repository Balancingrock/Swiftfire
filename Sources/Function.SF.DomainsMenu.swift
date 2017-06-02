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
import Html


/// - Returns: A menu for the navbar containing all the domains as submenu items.

func function_sf_domainsMenu(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    let checkbox = Input(.checkbox, [], "domains-checkbox")
    
    let placeholder = P("<!-- empty but necessary! -->")
    let menuItemTitle = Div(klass: "menu-item-title", P("Domains"))
    let menuItemSymbol = Div(klass: "menu-item-symbol", placeholder)
    let menuItem = Div(klass: "menu-item", menuItemSymbol, menuItemTitle)
    let menuItemSeparator = Div(klass: "menu-item-separator", placeholder)
    let label = Label(forId: "domains-checkbox", menuItemSeparator, menuItem)
    
    let link = A(href: "/serveradmin/pages/domain-management.sf.html", P("Manage Domains"))
    let firstMenuSubitemTitle = Div(klass: "menu-subitem-title", link)
    let firstMenuSubitemSymbol = Div(klass: "menu-subitem-symbol", [])
    let firstMenuSubitem = Div(klass: "menu-subitem", firstMenuSubitemSymbol, firstMenuSubitemTitle)
    let firstListItem = Li(firstMenuSubitem)
    
    var list = Ul(firstListItem)
    
    for domain in domains {
        
        let link = postingLink(target: "/serveradmin/pages/domain.sf.html", text: domain.name, keyValuePairs: ["DomainName": domain.name])
        
        let menuSubitemTitle = Div(klass: "menu-subitem-title", link)
        let menuSubitemSymbol = Div(klass: "menu-subitem-symbol", [])
        let menuSubitem = Div(klass: "menu-subitem", menuSubitemSymbol, menuSubitemTitle)
        let listItem = Li(menuSubitem)
        
        list.append(listItem)
    }
    
    // If the next expression fails, it will be noticable during tests
    
    return (checkbox.html + label.html + list.html).data(using: String.Encoding.utf8)!
}

