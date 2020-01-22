// =====================================================================================================================
//
//  File:       Service.Command.RequestNewPassword.swift
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
//  License:    Use or redistribute this code any way you like with the following two provisions:
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
import Http


// The request new password command (2-stage, followed by set new password)
// This command is triggered by the forgot password mail that was send


/// The  name to be used in HTML to request a new password.

let COMMAND_REQUEST_NEW_PASSWORD = "request-new-password"

fileprivate let REQUEST_NEW_PASSWORD_FAILED_TEMPLATE = "/pages/request-new-password-failed.sf.html"


/// The  name to be used in HTML that specifies the key to be used to set a new password.

let REQUEST_NEW_PASSWORD_CODE_KEY = "request-new-password-code"


/// Execute the Login command.
///
/// - parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain for which to review the comments.
///
/// - Returns: If a specific page should be returned, the path to that page is returned. Otherwise nil.

func executeRequestNewPassword(_ request: Request, _ domain: Domain) -> String {
    
    guard let code = request.info[REQUEST_NEW_PASSWORD_CODE_KEY] else {
        Log.atError?.log("Missing \(REQUEST_NEW_PASSWORD_CODE_KEY)")
        return REQUEST_NEW_PASSWORD_FAILED_TEMPLATE
    }
    
    var account: Account?
    for a in domain.accountsWaitingForNewPassword {
        if code == a.newPasswordVerificationCode {
            domain.accountsWaitingForNewPassword.removeObject(object: a)
            account = a
            break
        }
    }
    
    if let account = account {
        
        // Set the account name and request the set new password page
        request.info[SET_NEW_PASSWORD_ACCOUNT_ID_KEY] = account.uuid.uuidString
        return SET_NEW_PASSWORD_TEMPLATE
        
    } else {
        
        Log.atError?.log("The account was not found, possible time-out or double-try?")
        return REQUEST_NEW_PASSWORD_FAILED_TEMPLATE
    }
}
