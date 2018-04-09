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
    
    func subitem(link: String) -> Div {
        let text = Div(klass:"text", link)
        let symbol = Div(klass: "symbol")
        let title = Div(klass: "title", symbol, text)
        return Div(klass: "subitem", title)
    }
    

    let checkbox = Input(.checkbox, [], "domain-checkbox")

    let label = Label(klass: "symbol", forId: "domain-checkbox", P(klass: "code"))
    
    let text = Div(klass: "text", P(klass: "paddingAsLInk", "Domains"))

    let title = Div(klass: "title", label, text)
    
    var dropdown = Div(klass: "dropdown")

    dropdown.append(Div(klass: "subitem-separator", P("<!-- empty but necessary! -->")))
    
    let link = A(href: "/serveradmin/pages/domain-management.sf.html", P("Manage Domains"))

    dropdown.append(subitem(link: link.html))
    
    for domain in domains {
        dropdown.append(Div(klass: "subitem-separator", P("<!-- empty but necessary! -->")))
        dropdown.append(subitem(link: postingLink(target: "/serveradmin/pages/domain.sf.html", text: domain.name, keyValuePairs: ["DomainName": domain.name])))
    }

    let item = Div(klass: "item", checkbox, title, dropdown)
    
    let item_separator = Div(klass: "item-separator", P("<!-- empty but necessary! -->"))
    
    
    // If the next expression fails, it will be noticable during tests
    
    return (item_separator.html + item.html).data(using: String.Encoding.utf8)!
}

