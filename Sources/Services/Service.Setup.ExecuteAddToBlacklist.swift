// =====================================================================================================================
//
//  File:       Service.Setup.ExecuteAddToBlacklist.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019-2020 Marinus van der Lugt, All rights reserved.
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


/// This command adds to a blacklist.
///
/// - Parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain of the blacklist.

func executeAddToBlacklist(_ request: Request, _ domain: Domain) {
    
    guard let address = request.info["blacklist-address"] else {
        Log.atError?.log("Missing blacklist-address")
        return
    }
    
    guard let actionStr = request.info["blacklist-action"] else {
        Log.atError?.log("Missing blacklist-action")
        return
    }
    
    let action: Blacklist.Action = {
        switch actionStr {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(actionStr)")
            return .closeConnection
        }
    }()
    
    domain.blacklist.add(address, action: action)
    
    domain.blacklist.store(to: Urls.domainBlacklistFile(for: domain.name))
    
    Log.atNotice?.log("Added address \(address) to blacklist with action \(action) in domain \(domain.name)")
}
