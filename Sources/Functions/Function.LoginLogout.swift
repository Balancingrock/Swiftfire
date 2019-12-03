// =====================================================================================================================
//
//  File:       Function.LoginLogout.swift
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
// 1.3.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Core
import Services


/// Returns either a message with account name (and logout), or presents login/register links
///
/// __Webpage Use__:
///
/// _Signature_: .loginLogout(loggedInMessage, logoutMessage, loginMessage, registerMessage)
///
/// Note: There should be either 0 or 4 messages. If there are 0 messages, defaults will be used. Otherwise the given messages will be used.
///
/// _Number of arguments_: 0 or 4
///
/// _Type of argument_:
///   - loggedInMessage: The message to be displayed when somebody is logged in. This message will be followed by the name of the user.
///   - logoutMessage: The message to be displayed when somebody is logged in. This message will be followed by the name of the user.
///   - loginMessage: The message to be displayed when somebody is logged in. This message will be followed by the name of the user.
///   - registerMessage: The message to be displayed when somebody is logged in. This message will be followed by the name of the user.
///
///
/// _Returns_: The HTML code for the login field.

public func function_loginLogout(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    
    // There should be no arguments
    
    guard case .arrayOfString(let arr) = args, (arr.count == 0 || arr.count == 4) else {
        Log.atWarning?.log("Function .loginLogout() should have 0 or 4 arguments")
        return htmlErrorMessage
    }
    
    
    // There should be a session. If there is no session the site cannot support login/logout

    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        return Data()
    }
    
    
    let loggedInMessage = (arr.count == 4) ? arr[0] : "Logged in as: "
    let logoutMessage = (arr.count == 4) ? arr[1] : "Logout"
    let loginMessage = (arr.count == 4) ? arr[2] : "Login"
    let registerMessage = (arr.count == 4) ? arr[3] : "Register"
        
    var html: String
    
    
    // Don't display the login/logout line for the login page or register page    
    
    if let account = session.info.getAccount(inDomain: environment.domain) {
                
        html = """
            <div class="sf-loginlogout">
                <div class="sf-loginlogout-firstoption">\(loggedInMessage)\(account.name)</div>
                <p> - </p>
                <div class="sf-loginlogout-secondoption">
                    <form method="post" action="/command/logout">
                    <button type="submit" name="\(ORIGINAL_PAGE_URL_KEY)" value="\(environment.serviceInfo[.relativeResourcePathKey] as? String ?? "/index.sf.html")" style="border:none; background:none; cursor:pointer; margin:0 0 0 0; padding: 0 0 0 0;">\(logoutMessage)</button>
                    </form>
                </div>
            </div>
        """
    
    } else {
        
        html = """
            <div class="sf-loginlogout">
                <div class="sf-loginlogout-firstoption">
                    <a href="/pages/login.sf.html">\(loginMessage)</a>
                </div>
                <p> - </p>
                <div class="sf-loginlogout-secondoption">
                    <a href="/pages/register.sf.html">\(registerMessage)</a>
                </div>
            </div>
        """
    }
    
    return html.data(using: .utf8)
}
