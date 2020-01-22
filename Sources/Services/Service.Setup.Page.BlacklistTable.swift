// =====================================================================================================================
//
//  File:       Service.Setup.AdminPage.BlacklistTable.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Split off from Service.Setup
//
// =====================================================================================================================

import Foundation

import Core

/// Create the blacklist table for the domain setup page,
///
/// - Parameters:
///     - domain: The domain for which to create it
///
/// - Returns: The requested HTML code.

func blacklistTable(_ domain: Domain) -> String {
    
    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }

    var html: String = """
        <div class="center-content">
            <div class="table-container">
                <table>
                    <thead>
                        <tr><th>Address</th><th>Action</th><th></th></tr>
                    </thead>
                    <tbody>
    """
    
    domain.blacklist.list.sorted(by: { (one: (key: String, value: Blacklist.Action), two: (key: String, value: Blacklist.Action)) -> Bool in
        one.key < two.key
    }) .forEach { (address, action) in
        
        let row = """
            <tr>
                <td>\(address)</td>
                <td>
                    <form method="post" action="\(setupCommand("update-blacklist"))">
                        <div style="display:flex; flex-direction:row; align-items:center;">
                            <input type="hidden" name="blacklist-address" value="\(address)">
                            <input type="radio" name="blacklist-action" value="close" \(action == .closeConnection ? "checked" : "")>
                            <span> Close Connection, <span>
                            <input type="radio" name="blacklist-action" value="503" \(action == .send503ServiceUnavailable ? "checked" : "")>
                            <span> 503 Service Unavailable, <span>
                            <input type="radio" name="blacklist-action" value="401" \(action == .send401Unauthorized ? "checked" : "")>
                            <span> 401 Unauthorized </span>
                            <input type="submit" value="Update Action">
                        </div>
                    </form>
                </td>
                <td>
                    <form method="post" action="\(setupCommand("remove-from-blacklist"))">
                        <input type="hidden" name="blacklist-address" value="\(address)">
                        <input type="submit" value="Remove">
                    </form>
                </td>
            </tr>
        """
        
        html += row
    }
    
    html += """
                    </tbody>
                </table>
            </div>
        </div>
        <h3>Add address to blacklist</h3>
        <div class="center-content">
            <div class="table-container">
                <form method="post" action="\(setupCommand("add-to-blacklist"))")>
                    <table>
                        <tbody>
                            <tr>
                                <td>Address:</td>
                                <td><input type="text" name="blacklist-address" value=""></td>
                            </tr>
                            <tr>
                                <td>Action:</td>
                                <td>
                                    <div style="display:flex; flex-direction:row; align-items:center;">
                                        <input type="radio" name="blacklist-action" value="close" checked><span> Close Connection</span>
                                        <input type="radio" name="blacklist-action" value="503"><span> 503 Services Unavailable</span>
                                        <input type="radio" name="blacklist-action" value="401"><span> 401 Unauhorized</span>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td></td>
                                <td><input type="submit" value="Add to Blacklist"></td>
                            </tr>
                        </tbody>
                    </table>
                </form>
            </div>
        </div>
    """
    
    return html
}
