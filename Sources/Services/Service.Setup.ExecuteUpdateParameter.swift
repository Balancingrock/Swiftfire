// =====================================================================================================================
//
//  File:       Service.Setup.ExecuteUpdateParameter.swift
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

internal func executeUpdateParameter(_ request: Request, _ domain: Domain) {
    
    guard let parameter = request.info["parameter-name"] else {
        Log.atError?.log("Missing parameter name in request.info")
        return
    }
    
    guard let value = request.info["parameter-value"] else {
        Log.atError?.log("Missing parameter value in request.info")
        return
    }

    
    switch parameter.lowercased() {
    case "forewardurl": domain.forwardUrl = value
    case "enabled": domain.enabled = Bool(lettersOrDigits: value) ?? domain.enabled
    case "accesslogenabled": domain.accessLogEnabled = Bool(lettersOrDigits: value) ?? domain.accessLogEnabled
    case "four04logenabled": domain.four04LogEnabled = Bool(lettersOrDigits: value) ?? domain.four04LogEnabled
    case "sessionlogenabled": domain.sessionLogEnabled = Bool(lettersOrDigits: value) ?? domain.sessionLogEnabled
    case "phpmapindex": domain.phpMapIndex = Bool(lettersOrDigits: value) ?? domain.phpMapIndex
    case "phpmapall":
        if Bool(lettersOrDigits: value) ?? domain.phpMapAll {
            domain.phpMapAll = true
            domain.phpMapIndex = true
        } else {
            domain.phpMapAll = false
        }
    case "phptimeout": domain.phpTimeout = Int(value) ?? domain.phpTimeout
    case "sessiontimeout": domain.sessionTimeout = Int(value) ?? domain.sessionTimeout
    default: Log.atError?.log("Unknown key '\(parameter)' with value '\(value)'")
    }
    
    domain.storeSetup()
}
