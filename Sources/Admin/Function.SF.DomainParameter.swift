// =====================================================================================================================
//
//  File:       Function.SF.DomainParameter.swift
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
// Description
// =====================================================================================================================
//
// Returns the value of a parameter in a domain.
//
//
// Signature:
// ----------
//
// .domainParameter(domain-name, parameter-name)
//
//
// Parameters:
// -----------
//
// args[0]: Name of the domain.
// args[1]: Name of the parameter.
//
//
// Other Input:
// ------------
//
// None.
//
//
// Returns:
// --------
//
// The value of the requested parameter in the specified domain or '***error***'
//
//
// Other Output:
// -------------
//
// None.
//
//
// =====================================================================================================================

import Foundation

import SwifterLog
import Core


/// - Returns: A button with an action to remove a domain.

func function_sf_domainParameter(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    guard case .arrayOfString(let arr) = args else {
        return "Argument type error".data(using: String.Encoding.utf8)
    }
    
    
    // There must be two arguments
    
    guard arr.count == 2 else {
        Log.atError?.log("Missing arguments, expected 2, found: \(arr.count)")
        return htmlErrorMessage
    }
    
    guard let domainName = readKey(arr[0], using: info, in: environment) else {
        Log.atError?.log("Cannot read key domain name argument: \(arr[0])")
        return htmlErrorMessage
    }
    
    guard let parameterName = readKey(arr[1], using: info, in: environment) else {
        Log.atError?.log("Cannot read key parameter name argument: \(arr[1])")
        return htmlErrorMessage
    }

    
    // Check that a server admin is logged in
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        Log.atError?.log("No session found")
        return htmlErrorMessage
    }
    
    guard let account = session.getAccount(inDomain: environment.domain) else {
        Log.atError?.log("No account found")
        return htmlErrorMessage
    }
    
    guard serverAdminDomain.accounts.contains(account.name) else {
        Log.atAlert?.log("Attempt to access server admin operation by: '\(account.uuid)'")
        return htmlErrorMessage
    }

    
    // Check that a valid domain name was specified
    
    guard let domain = domainManager.domain(for: domainName) else {
        Log.atError?.log("No domain found for: \(domainName)")
        return htmlErrorMessage
    }
    
    
    // Return the parameter value

    switch parameterName {
        
    case "root": return domain.webroot.data(using: .utf8)
    case "enabled": return String(domain.enabled).data(using: .utf8)
    case "sf-resources": return domain.sfresources.data(using: .utf8)
    case "access-log-enabled": return String(domain.accessLogEnabled).data(using: .utf8)
    case "404-log-enabled": return String(domain.four04LogEnabled).data(using: .utf8)
    case "session-log-enabled": return String(domain.sessionLogEnabled).data(using: .utf8)
    case "session-timeout": return String(domain.sessionTimeout).data(using: .utf8)
    case "php-path": return (domain.phpPath?.path ?? "PHP Disabled").data(using: .utf8)
    case "php-options": return ((domain.phpPath != nil) ? (domain.phpOptions ?? "Not Set") : "PHP Disabled").data(using: .utf8)
    case "php-map-index": return ((domain.phpPath != nil) ? String(domain.phpMapIndex) : "PHP Disabled").data(using: .utf8)
    case "php-map-all": return ((domain.phpPath != nil) ? String(domain.phpMapAll) : "PHP Disabled").data(using: .utf8)
    case "php-timeout": return ((domain.phpPath != nil) ? String(domain.phpTimeout) : "PHP Disabled").data(using: .utf8)
    case "foreward-url": return domain.forwardUrl.data(using: .utf8)
    case "comment-auto-approval-threshold": return String(domain.commentAutoApprovalThreshold).data(using: .utf8)
        
    default:
        Log.atDebug?.log("Unknown parameter name: \(parameterName)")
        return htmlErrorMessage
    }
}
