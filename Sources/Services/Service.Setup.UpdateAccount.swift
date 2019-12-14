// =====================================================================================================================
//
//  File:       Service.Setup.UpdateAccount.swift
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


internal func updateAccount(_ request: Request, _ domain: Domain, _ connection: SFConnection) {
    
    guard let str = request.info["account-uuid"], !str.isEmpty, let uuid = UUID(uuidString: str) else {
        Log.atError?.log("Missing account uuid")
        return
    }
    
    guard let parameter = request.info["parameter"], !parameter.isEmpty else {
        Log.atError?.log("Missing parameter")
        return
    }
    
    guard let account = domain.accounts.getAccount(for: uuid) else {
        Log.atError?.log("Missing account")
        return
    }
    
    guard account.name != "Anon" else {
        Log.atAlert?.log("Attempt to modify Anon account from IP: \(connection.remoteAddress)")
        return
    }
    
    switch parameter {
        
    case "account-name":
        
        if let value = request.info["value"], !value.isEmpty {
            Log.atInfo?.log("Updating name of account \(account.name) to '\(value)'")
            account.name = value
        } else {
            Log.atError?.log("New value not present or empty")
        }
        
        
    case "is-enabled":
        
        if request.info["value"] != nil {
            Log.atInfo?.log("Enabling account \(account.name)")
            account.isEnabled = true
        } else {
            Log.atInfo?.log("Disabling account \(account.name)")
            account.isEnabled = false
        }
        
        
    case "email-address":
        
        if let value = request.info["value"], !value.isEmpty {
            Log.atInfo?.log("Updating email address of account \(account.name) to '\(value)'")
            account.emailAddress = value
        } else {
            Log.atError?.log("New value not present or empty")
        }
        
        
    case "email-verification-code":
        
        if let value = request.info["value"] {
            Log.atInfo?.log("Updating email verification code of account \(account.name) to '\(value)'")
            account.emailVerificationCode = value
        } else {
            Log.atError?.log("New value not present")
        }

        
    case "is-domain-admin":
        
        if request.info["value"] != nil {
            Log.atInfo?.log("Enabling domain admin privelidges of account \(account.name)")
            account.isDomainAdmin = true
        } else {
            Log.atInfo?.log("Disabling domain admin privelidges of account \(account.name)")
            account.isDomainAdmin = false
        }

        
    case "new-password-verification-code":
        
        if let value = request.info["value"] {
            Log.atInfo?.log("Updating new password verification code of account \(account.name) to '\(value)'")
            account.newPasswordVerificationCode = value
        } else {
            Log.atError?.log("New value not present")
        }

        
    case "new-password-timestamp":

        if !account.newPasswordVerificationCode.isEmpty {
            Log.atInfo?.log("Restarting timeout for new password of account \(account.name)")
            account.newPasswordRequestTimestamp = Date().unixTime
        }

        
    case "new-password":
        
        if let value = request.info["value"], value.count > 4 {
            Log.atInfo?.log("Updating password of account \(account.name)")
            _ = account.updatePassword(value)
        } else {
            Log.atError?.log("New value not present or too short")
        }

        
    default:
        Log.atError?.log("Unknown parameter: \(parameter)")
        return
    }
}
