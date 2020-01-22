// =====================================================================================================================
//
//  File:       Service.Setup.CreateAccountDetailPage.swift
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

import Http
import Core


/// Creates an account detail page.
///
/// - Parameters:
///     - request: The originating request.
///     - domain: The domain of the account.
///     - response: The response to contain the page.

func createAccountDetailPage(_ request: Request, _ domain: Domain, _ response: Response) {
    
    guard let str = request.info["account-uuid"], let uuid = UUID(uuidString: str) else {
        Log.atError?.log("Missing account-uuid in request.info")
        response.code = ._500_InternalServerError
        return
    }
    
    guard let account = domain.accounts.getAccount(for: uuid) else {
        Log.atError?.log("Missing account")
        response.code = ._500_InternalServerError
        return
    }
    
    
    // Prevent confusion due to 'strange values' (not an error though)
    
    if account.newPasswordVerificationCode.isEmpty {
        account.newPasswordRequestTimestamp = 0
    }
    
    
    // Build the page
    
    let html: String =
    """
    <!DOCTYPE html>
    <html>
        <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta name="theme-color" content="#ffffff">
            <title>Account: \(account.name)</title>
            <meta name="description" content="Account info">
            <style>
                table {
                    border-collapse: collapse;
                    width: 100%;
                }

                td, th {
                    border: 1px solid gray;
                    text-align: left;
                    padding: 8px;
                }

                tr:nth-child(even) {
                    background-color: lightgray;
                }
            </style>
        </head>
        <body>
            <h1 style="margin-left:auto; margin-right:auto;">Account name: \(account.name)</h1>
            <table>
                <thead>
                    <tr>
                        <th>Parameter</th>
                        <th>Value</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Name:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="account-name">
                                <input type="text" name="value" value="\(account.name)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">The name of the account. Changes will be retroactive.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Is Enabled:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="is-enabled">
                                <input type="checkbox" name="value" value="true" \(account.isEnabled ? "checked" : "")>
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">No changes can be made to the user content associated with this account as long as it is disabled. Note that a user cannot log in as long as the emailVerificationCode is not empty.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Email address:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="email-address">
                                <input type="text" name="value" value="\(account.emailAddress)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">Updates to this field will be accepted AS IS. All auto-generated emails will be sent to this address.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Email verification code:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="email-verification-code">
                                <input type="text" name="value" value="\(account.emailVerificationCode)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">This will be empty once the email address is verified.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Is domain administrator:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="is-domain-admin">
                                <input type="checkbox" name="value" value="true" \(account.isDomainAdmin ? "checked" : "")>
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">If enabled, the account user gets access to the domain setup page.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>New password verification code:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="new-password-verification-code">
                                <input type="text" name="value" value="\(account.newPasswordVerificationCode)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">Used temporary when the user requests a new password.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>New password timestamp:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="new-password-timestamp">
                                <input type="text" name="value" value="\(account.newPasswordRequestTimestamp)" disabled>
                                <input type="submit" value="Restart">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">Time of the new password request made by the user (the request is valid for 24 hours). Will be zero if no request is pending. 'Restart' will start the 24 hour window again, but only if there is a new password verification code.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Account directory URL:</td>
                        <td colspan="2">\(account.dir.path)</td>
                    </tr>
                    <tr>
                        <td>New password timestamp:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="new-password">
                                <input type="text" name="value" value="">
                                <input type="submit" value="Set Password">
                            </form>
                        </td>
                    <td>
                        <p style="margin-bottom:0;">The password is not shown, but a new password can be set. A new password must have more than 4 characters. Setting a password of 4 characters or less will fail silently.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Account directory URL:</td>
                        <td colspan="2">\(account.dir.path)</td>
                    </tr>
                </tbody>
            </table>
            <div>
                <p><a href="/setup">Return to setup page</a></p>
            </div>
        </body>
    </html>
    """
    
    response.body = html.data(using: .utf8)
    response.code = Response.Code._200_OK
    response.contentType = mimeTypeHtml
}
