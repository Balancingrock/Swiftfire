// =====================================================================================================================
//
//  File:       EvaluateKeyArgument.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Moved getInfo and postInfo into requestinfo
//       - Added a requestinfo! to return an empty string if the requested parameter does not exist
//       - Fixed a bug that caused the account name not to be returned
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation


/// Parse the given argument and return the requested value if it is a keyed argument.
///
/// Example: $requestinfo.name will return the value of the dictionary entry under request.info["name"]
///
/// Allowable identifiers
///
/// _source requestInfo_: All possible strings. Returns an error message if the parameter does not exist
///
/// _source requestInfo!_: All possible strings. Will not retrun an error, but an empty string if the parameter does ot exist
///
/// _source functionsInfo_: None yet
///
/// _source serviceInfo_:
///
///    - absoluteresourcepath (String)
///    - relativeresourcepath (String)
///    - responsestarted (Int64.description)
///
/// _source sessionInfo_: None yet
///
/// _source account_:
///
///    - name (String)
///
/// - Parameters:
///   - arg: The keyed argument.
///   - using: The functionInfo structure.
///   - in: The environment the function is executing in.
///
/// - Returns:
///   - The argument if the argument does not start with '$'
///   - ***error*** If there the request is invalid or of an non-existing source/key
///   - The requested value

public func evaluateKeyArgument(_ arg: String, using functionsInfo: Functions.Info, in environment: Functions.Environment) -> String {
    
    guard (arg.first ?? " ") == "$" else { return arg } // Not a key argument
    
    let args = arg.split(separator: ".")
    
    guard args.count >= 2 else {
        Log.atError?.log("Missing source or key in argument")
        return "***error***"
    }
    
    switch args[0].lowercased() {
    
    case "$requestinfo":
                
        guard let result = environment.request.info[String(args[1]).lowercased()] else {
            Log.atError?.log("Request.info does not contain key: \(args[1])")
            return "***error***"
        }
        
        return result
        
        
    case "$requestinfo!":

        return environment.request.info[String(args[1]).lowercased()] ?? ""

        
    case "$functionsinfo":
        
        guard let result = functionsInfo[String(args[1]).lowercased()] as? String else {
            Log.atError?.log("FunctionInfo does not contain key: \(args[1])")
            return "***error***"
        }
        
        return result

        
    case "$serviceinfo":
        
        switch args[1].lowercased() {
            
        case "absoluteresourcepath":
            
            return (environment.serviceInfo[.absoluteResourcePathKey] as? String) ?? "***error***"
            

        case "relativeresourcepath":
            
            return (environment.serviceInfo[.relativeResourcePathKey] as? String) ?? "***error***"

            
        case "responsestarted":
        
            return (environment.serviceInfo[.responseStartedKey] as? Int64)?.description ?? "***error***"


        default:
            Log.atError?.log("No access to ServiceInfo mapped for key: \(args[1].lowercased())")
            return "***error***"
        }

        
    case "$sessioninfo":
        
        guard (environment.serviceInfo[.sessionKey] as? SessionInfo) != nil else {
            Log.atError?.log("No SessionInfo found")
            return "***error***"
        }
        
        switch args[1].lowercased() {
            
        default:
            Log.atError?.log("No access to SessionInfo mapped for key: \(args[1].lowercased())")
            return "***error***"
        }

        
    case "$account":
        
        guard let session = (environment.serviceInfo[.sessionKey] as? Session) else {
            Log.atError?.log("No Session found")
            return "***error***"
        }

        guard let account = session.info[.accountKey] as? Account else {
            return ""
        }
        
        switch args[1].lowercased() {
        
        case "name": return account.name
            
        default:
            Log.atError?.log("No access to Account mapped for key: \(args[1].lowercased())")
            return "***error***"

        }
        
        
    case "$domain":
        
        switch args[1].lowercased() {
            
        case "name": return environment.domain.name
        
        case "root": return environment.domain.webroot
            
        case "forewardurl": return environment.domain.forwardUrl
            
        case "enabled": return environment.domain.enabled.description
            
        case "accesslogenabled": return environment.domain.accessLogEnabled.description
            
        case "404logenabled": return environment.domain.four04LogEnabled.description
            
        case "sessionlogenabled": return environment.domain.sessionLogEnabled.description
            
        case "phppath": return (environment.domain.phpPath?.path ?? "")
            
        case "phpoptions":
            if environment.domain.phpPath != nil {
                return (environment.domain.phpOptions ?? "")
            } else {
                return "PHP Disabled"
            }
            
        case "phpmapindex":
            if environment.domain.phpPath != nil {
                return environment.domain.phpMapIndex.description
            } else {
                return "PHP Disabled"
            }
            
        case "phpmapall":
            if environment.domain.phpPath != nil {
                return environment.domain.phpMapAll.description
            } else {
                return "PHP Disabled"
            }
            
        case "phptimeout":
            if environment.domain.phpPath != nil {
                return environment.domain.phpTimeout.description
            } else {
                return "PHP Disabled"
            }
            
        case "sfresources": return environment.domain.sfresources
            
        case "sessiontimeout": return environment.domain.sessionTimeout.description

        default:
            Log.atError?.log("No access to Domain mapped for key: \(args[1].lowercased())")
            return "***error***"
        }
        
        
    default:
        Log.atError?.log("Unknown source for key argument: '\(args[0])'")
        return "***error***"
    }
}
