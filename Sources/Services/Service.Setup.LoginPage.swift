// =====================================================================================================================
//
//  File:       Service.Setup.LoginPage.swift
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


/// This function returns the login page.
///
/// - Parameters:
///     - response: The response to contain the login page.
///     - domainName: The domain name for the login page.

func loginPage(_ response: Response, _ domainName: String) {
    
    let page: String =
    """
    <!DOCTYPE html>
    <html>
        <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta name="theme-color" content="#ffffff">
            <title>\(domainName) Admin Login</title>
            <meta name="description" content="\(domainName) Admin">
        </head>
        <body>
            <div style="display:flex; justify-content:center; margin-bottom:50px;">
                <div style="margin-left:auto; margin-right:auto;">
                    <form action="/setup" method="post">
                        <p style="margin-bottom:0px">ID:</p>
                        <input type="text" name="login-name" value="name" autofocus><br>
                        <p style="margin-bottom:0px">Password:</p>
                        <input type="password" name="login-password" value="****"><br><br>
                        <input type="submit" value="Login">
                    </form>
                </div>
            </div>
        </body>
    </html>
    """
    
    response.body = page.data(using: .utf8)
    response.code = Response.Code._200_OK
    response.contentType = mimeTypeHtml
}
