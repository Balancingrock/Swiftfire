// =====================================================================================================================
//
//  File:       Service.Setup.Page.AdminTable.swift
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


/// Create the admin table for the domain setup page,
///
/// - Parameters:
///     - domain: The domain for which to create it
///
/// - Returns: The requested HTML code.

func adminTable(_ domain: Domain, _ account: Account) -> String {
    
    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }
    
    var html: String =
    """
        <div class="center-content">
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Account ID</th>
                            <th>Remove</th>
                            <th>Password</th>
                            <th>Details</th>
                        </tr>
                    </thead>
                    <tbody>
    """
    
    for accountName in domain.accounts {
        
        if account.name == "Anon" { continue }
        
        if accountName != account.name {
            
            let row = """
                <tr>
                    <td>\(accountName)</td>
                    <td>
                        <form action="\(setupCommand("confirm-delete-account"))" method="post">
                            <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                            <input type="submit" value="Remove">
                        </form>
                    </td>
                    <td>
                        <form action="\(setupCommand("change-password"))" method="post">
                            <input type="hidden" name="change-password-name" value="\(accountName)">
                            <input type="text" name="change-password-password" value="">
                            <input type="submit" value="Set New Password">
                        </form>
                    </td>
                    <td>
                        <form action="/setup/account-details" method="post">
                            <input type="hidden" name="account-name" value="\(accountName)">
                            <input type="submit" value="Details">
                        </form>
                    </td>
                </tr>
            """
            
            html += row
            
        } else {
            
            let row = """
                <tr>
                    <td>\(accountName)</td>
                    <td></td>
                    <td>
                        <form action="\(setupCommand("change-password"))" method="post">
                            <input type="hidden" name="admin-name" value="\(accountName)">
                            <input type="text" name="admin-password" value="">
                            <input type="submit" value="Set New Password">
                        </form>
                    </td>
                    <td>
                        <form action="/setup/account-details" method="post">
                            <input type="hidden" name="account-name" value="\(accountName)">
                            <input type="submit" value="Details">
                        </form>
                    </td>
                </tr>
            """
            
            html += row
        }
    }
    
    html += """
                    </tbody>
                </table>
            </div>
        </div>
    """

    
    return html
}
