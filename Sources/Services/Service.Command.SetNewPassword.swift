// =====================================================================================================================
//
//  File:       Service.Command.SetNewPassword.swift
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


// The set new password command (the follow-up of the request new password Command)

internal let COMMAND_SET_NEW_PASSWORD = "set-new-password"

internal let SET_NEW_PASSWORD_TEMPLATE = "/pages/set-new-password.sf.html"
fileprivate let SET_NEW_PASSWORD_SUCCESS_TEMPLATE = "/pages/set-new-password-success.sf.html"

internal let SET_NEW_PASSWORD_ACCOUNT_ID_KEY = "uuid"
fileprivate let SET_NEW_PASSWORD_PASSWORD1_KEY = "set-new-password-1"
fileprivate let SET_NEW_PASSWORD_PASSWORD2_KEY = "set-new-password-2"


internal func executeSetNewPassword(_ request: Request, _ domain: Domain) -> String {
    
    guard let accountId = request.info[SET_NEW_PASSWORD_ACCOUNT_ID_KEY], let uuid = UUID(uuidString: accountId) else {
        Log.atError?.log("Missing account id")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard let account = domain.accounts.getAccount(for: uuid) else {
        Log.atError?.log("Unknown account for uuid: \(accountId)")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard account.newPasswordRequestTimestamp != 0 else {
        Log.atNotice?.log("Somebody seems to be trying to set a new password for `\(account.name)` without a pending request")
        return ATTEMPT_NOT_ALLOWED_TEMPLATE
    }
    
    
    // The request info should contain a Password1 key

    guard let password1 = request.info[SET_NEW_PASSWORD_PASSWORD1_KEY] else {
        Log.atError?.log("No '\(SET_NEW_PASSWORD_PASSWORD1_KEY)' found")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard password1.count > 4 else {
        Log.atDebug?.log("Password should contain more than 4 characters")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Password should contain more than 4 characters"
        return SET_NEW_PASSWORD_TEMPLATE
    }

    
    // The request info should contain a Password2 key

    guard let password2 = request.info[SET_NEW_PASSWORD_PASSWORD2_KEY] else {
        Log.atError?.log("No '\(SET_NEW_PASSWORD_PASSWORD2_KEY)' found")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard password1 == password2 else {
        Log.atDebug?.log("Passwords are not the same")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "First and second password must be equal"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    
    // Set the new password
    
    guard account.updatePassword(password1) else {
        Log.atError?.log("Could not changethe password")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    account.newPasswordVerificationCode = ""
    account.newPasswordRequestTimestamp = 0
    
    return SET_NEW_PASSWORD_SUCCESS_TEMPLATE
}
