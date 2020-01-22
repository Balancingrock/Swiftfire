//
//  Service.Setup.Page.swift
// =====================================================================================================================
//
//  File:       Service.Setup.ExecuteUpdateBlacklist.swift
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


/// Creates the setup page for a domain.
///
/// - parameters:
///     - domain: The domain for which to review the comments.
///     - account: The account, must be a domain administrator..
///     - response: The response that will be returned.

func setupPage(_ domain: Domain, _ account: Account, _ response: Response) {
                            
    let html: String = """
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="utf-8">
                <meta http-equiv="X-UA-Compatible" content="IE=edge">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <meta name="theme-color" content="#ffffff">
                <title>\(domain.name.capitalized) Admin Login</title>
                <meta name="description" content="\(domain.name.capitalized) Admin">
                <style>
                    h1 { text-align: center; }
                    h2 { text-align: center; }
                    h3 { text-align: center; }
                    .center-content { display:flex; flex-direction:column; justify-content:center }
                    .center-self { margin-left:auto; margin-right:auto; }
                    .bottom-offset { margin-bottom: 100px }
                    .table-container { background-color:#f0f0f0; border: 1px solid lightgray; margin-left:auto; margin-right:auto; }
                    .submit-offset { margin-top:5px; margin-bottom: 2px; }
                </style>
            </head>
            <body>
                <div class="bottom-offset">
                    <div>
                        <h1>\(domain.name.uppercased())</h1>
                        <h2>Parameters</h2>
                        \(parameterTable(domain))
                        <h2>Telemetry</h2>
                        \(telemetryTable(domain))
                        <h2>Blacklist</h2>
                        \(blacklistTable(domain))
                        <h2>Domain Services</h2>
                        \(servicesTable(domain))
                        <h2>Domain Accounts</h2>
                        \(adminTable(domain, account))
                        <h2>Add Admin or change Password</h2>
                        \(newDomainAdmin(domain))
                        <h2>Logoff</h2>
                        \(logoff(domain))
                    </div>
                </div>
            </body>
        </html>
    """

    response.body = html.data(using: .utf8)
    response.code = Response.Code._200_OK
    response.contentType = mimeTypeHtml
}
