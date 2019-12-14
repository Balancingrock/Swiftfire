// =====================================================================================================================
//
//  File:       Service.Setup.ExecuteChangePassword.swift
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


internal func executeChangePassword(_ request: Request, _ domain: Domain) {
    
    guard let str = request.info["changepasswordid"], let uuid = UUID(uuidString: str) else {
        Log.atError?.log("Missing id")
        return
    }

    guard let pwd = request.info["changepasswordpassword"] else {
        Log.atError?.log("Missing password")
        return
    }

    if let account = domain.accounts.getAccount(for: uuid) {

        
        // Change the password
        
        if account.updatePassword(pwd) {
            Log.atNotice?.log("Updated the password for domain admin \(account.name)")
        } else {
            Log.atError?.log("Failed to update the password for domain admin \(account.name)")
        }
        
        account.isEnabled = true
        account.emailVerificationCode = ""

    } else {
     
        Log.atError?.log("Account not found for uuid: \(str)")
    }
}
