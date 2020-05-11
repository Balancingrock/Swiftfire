// =====================================================================================================================
//
//  File:       Service.Setup.ExecuteConfirmDeleteAccount.swift
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

import Http
import Core


/// This command requestes the confirmation for the removal of an account.
///
/// - Parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain for the account.

func executeConfirmDeleteAccount(_ request: Request, _ response: Response, _ domain: Domain) -> Bool {
    
    func setupCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }

    guard let accountUuidString = request.info["account-uuid"],
        let uuid = UUID(uuidString: accountUuidString),
        let account = domain.accounts.getAccount(for: uuid) else {
        
            Log.atError?.log("Cannot identify account to delete")
            return false
    }

    let html: String =
    """
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="utf-8">
                <meta http-equiv="X-UA-Compatible" content="IE=edge">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <meta name="theme-color" content="#ffffff">
                <title>Confirm Account Removal</title>
                <meta name="description" content="Remove account">
            </head>
            <body>
                <div style="display:flex; justify-content:center; margin-bottom:50px;">
                    <div style="margin-left:auto; margin-right:auto;">
                    <h1>Confirm removal of account with name: \(account.name)</h1>
                        <form method="post">
                            <input type="hidden" name="remove-account-uuid" value="\(account.uuid.uuidString)">
                            <input type="submit" value="Confirmed" formaction="\(setupCommand("remove-account"))">
                            <input type="submit" value="Don't remove" formaction="/\(domain.setupKeyword!)">
                        </form>
                    </div>
                </div>
            </body>
        </html>
    """
    
    response.body = html.data(using: .utf8)
    response.code = Response.Code._200_OK
    response.contentType = mimeTypeHtml
    
    return true
}
