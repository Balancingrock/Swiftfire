// =====================================================================================================================
//
//  File:       Service.Setup.Page.NewDomainAdmin.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019-2020 Marinus van der Lugt, All rights reserved.
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

func newDomainAdmin(_ domain: Domain) -> String {
    
    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }

    let html: String = """
        <div class="center-content">
            <div class="table-container">
                <form method="post" action="\(setupCommand("add-admin-change-password"))">
                    <input type="hidden" name="Domain" value=".show($request.DomainName)">
                    <table>
                        <tr>
                            <td>Domain admin:</td>
                            <td><input type="text" name="AdminID" value=""></td>
                            <td></td>
                        </tr>
                        <tr>
                            <td>Password:</td>
                            <td><input type="text" name="AdminPassword" value=""></td>
                            <td><input type="submit" value="Add Admin / Change Password"></td>
                        </tr>
                    </table>
                </form>
            </div>
        </div>
    """
    
    return html
}

