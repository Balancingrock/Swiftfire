// =====================================================================================================================
//
//  File:       Service.Command.Login.swift
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


// Login. This command is used to login to an existing account. It needs the LoginName and LoginPassword.

internal let LOGIN_COMMAND = "login"

internal let LOGIN_TEMPLATE = "/pages/login.sf.html"

fileprivate let LOGIN_NAME_KEY = "login-name"
fileprivate let LOGIN_PASSWORD_KEY = "login-password"


internal func executeLogin(_ request: Request, _ domain: Domain, _ info: Services.Info) -> String? {
    
    
    // A session should be present
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atError?.log("Missing session")
        return LOGIN_TEMPLATE
    }

    
    // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt
    
    if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
        let now = Date().javaDate
        if now - previousAttempt < 2000 {
            session[.lastFailedLoginAttemptKey] = now
            request.info["PreviousAttemptMessage"] = "Too quick, wait a few seconds before trying again"
            return LOGIN_TEMPLATE
        }
    }

    
    // The request info should contain a LoginName key for the login name
    
    guard let loginName = request.info[LOGIN_NAME_KEY] else {
        Log.atError?.log("Missing '\(LOGIN_NAME_KEY)' in request.info")
        return LOGIN_TEMPLATE
    }
    
    guard !loginName.isEmpty else {
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "The Name field cannot be empty"
        return LOGIN_TEMPLATE
    }
    
    
    // The request info should contain a LoginName key for the login name

    guard let loginPassword = request.info[LOGIN_PASSWORD_KEY] else {
        Log.atError?.log("Missing '\(LOGIN_PASSWORD_KEY)' in request.info")
        return LOGIN_TEMPLATE
    }
            
    
    // Get the account (if it exists, is active and the password is correct)
    
    guard let account = domain.accounts.getAccount(withName: loginName, andPassword: loginPassword) else {
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Unknown name - password combination"
        return LOGIN_TEMPLATE
    }
    
    
    // Make sure the account is active
    
    guard account.isActive else {
        if !account.isEnabled {
            request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "This account has been disabled. Contact the domain administrator if this was in error."
        } else {
            if !account.emailVerificationCode.isEmpty {
                request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "The email address for this account has not yet been verified"
            } else {
                request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "This account is not active"
            }
        }
        return LOGIN_TEMPLATE
    }
    
    
    // Success
    
    Log.atDebug?.log("Account name \(account.name) logged in")
    
    session.info[.accountUuidKey] = account.uuid
    
    return (session.info[.preLoginUrlKey] as? String) ?? "/index.sf.html"
}