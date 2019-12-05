// =====================================================================================================================
//
//  File:       Service.Command.EmailVerification.swift
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


// Email verification. This command is received when a new user clicks the link in the confirmation email.

internal let EMAIL_VERIFICATION_COMMAND = "email-verification"

fileprivate let EMAIL_VERIFICATION_SUCCESS_TEMPLATE = "/pages/email-verification-success.sf.html"
fileprivate let EMAIL_VERIFICATION_FAILED_TEMPLATE = "/pages/email-verification-failed.sf.html"

internal let EMAIL_VERIFICATION_CODE_KEY = "verification-code"


internal func executeEmailVerification(_ request: Request, _ response: Response, _ domain: Domain, _ info: Services.Info) -> String? {
        
    guard let verificationCode = request.info[EMAIL_VERIFICATION_CODE_KEY] else {
        Log.atInfo?.log("Missing verifcation code in command")
        response.code = ._400_BadRequest
        return nil
    }
        
    guard domain.accountUuidsWaitingForVerification.count > 0 else {
        Log.atAlert?.log("An attempt was made to verify an account while there are no accounts waiting for verification")
        return EMAIL_VERIFICATION_FAILED_TEMPLATE
    }
    
    var success = false
    for (index, uuidString) in domain.accountUuidsWaitingForVerification.enumerated() {
        
        guard let uuid = UUID(uuidString: uuidString) else {
            Log.atNotice?.log("Could not create UUID for: \(uuidString)")
            return EMAIL_VERIFICATION_FAILED_TEMPLATE
        }
        
        guard let account = domain.accounts.getAccount(for: uuid) else {
            Log.atNotice?.log("Could not find account with UUID \(uuidString)")
            return EMAIL_VERIFICATION_FAILED_TEMPLATE
        }
        
        if account.emailVerificationCode == verificationCode {
            
            // Mark the account as verified
            account.emailVerificationCode = ""
            
            // Keep track in the log
            Log.atNotice?.log("Account with name \(account.name) and uuid \(uuidString) has been verified")
            
            // Remove the account from the waiting list
            domain.accountUuidsWaitingForVerification.remove(at: index)
            
            // Note: Do not automatically login. That could cause somebody else but the user to be logged in as that user.
                        
            // Successful account verification
            success = true
            
            break
        }
    }
    
    if success {
        return EMAIL_VERIFICATION_SUCCESS_TEMPLATE
    } else {
        Log.atNotice?.log("Account verification failed for code: \(verificationCode)")
        return EMAIL_VERIFICATION_FAILED_TEMPLATE
    }
}