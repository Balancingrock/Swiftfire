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


/// This command updates a domain parameter.
///
/// - Parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain for the parameter.

func executeUpdateParameter(_ request: Request, _ domain: Domain) {
    
    guard let parameter = request.info["parameter-name"] else {
        Log.atError?.log("Missing parameter name in request.info")
        return
    }
    
    guard let value = request.info["parameter-value"] else {
        Log.atError?.log("Missing parameter value in request.info")
        return
    }

    
    switch parameter.lowercased() {
    case "forward-url": domain.forwardUrl = value
    case "enabled": domain.enabled = Bool(lettersOrDigits: value) ?? domain.enabled
    case "access-log-enabled": domain.accessLogEnabled = Bool(lettersOrDigits: value) ?? domain.accessLogEnabled
    case "404-log-enabled": domain.four04LogEnabled = Bool(lettersOrDigits: value) ?? domain.four04LogEnabled
    case "session-log-enabled": domain.sessionLogEnabled = Bool(lettersOrDigits: value) ?? domain.sessionLogEnabled
    case "php-executable-path":
        domain.phpPath = nil
        if FileManager.default.isExecutableFile(atPath: value) {
            let url = URL(fileURLWithPath: value)
            if url.lastPathComponent.lowercased().contains("php") {
                domain.phpPath = URL(fileURLWithPath: value)
            } else {
                Log.atWarning?.log("Filename at \(value) should contain 'php'")
            }
        } else {
            Log.atWarning?.log("File at \(value) either does not exist or is not an executable")
        }

    case "php-map-index": domain.phpMapIndex = Bool(lettersOrDigits: value) ?? domain.phpMapIndex
    case "php-map-all":
        if Bool(lettersOrDigits: value) ?? domain.phpMapAll {
            domain.phpMapAll = true
            domain.phpMapIndex = true
        } else {
            domain.phpMapAll = false
        }
    case "php-timeout": domain.phpTimeout = Int(value) ?? domain.phpTimeout
    case "session-timeout": domain.sessionTimeout = Int(value) ?? domain.sessionTimeout
    case "comment-auto-approval-threshold": domain.commentAutoApprovalThreshold = Int32(value) ?? Int32.max
    default: Log.atError?.log("Unknown key '\(parameter)' with value '\(value)'")
    }
    
    domain.storeSetup()
}
