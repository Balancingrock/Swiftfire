// =====================================================================================================================
//
//  File:       EvaluateKeyArgument.swift
//  Project:    Swiftfire
//
//  Version:    1.2.0
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
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation


/// Parse the given argument and return the requested value if it is a keyed argument.
///
/// Example: $postinfo.name will return the value of the dictionary entry under postInfo["name"]
///
/// Allowable identifiers
///
/// _source postInfo_: All possible strings.
///
/// _source getInfo_: All possible strings.
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
///
///   - The argument if the argument does not start with '$'
///   - "***error*** If there the request is invalid or of an non-existing source/key
///   - The requested value

public func evaluateKeyArgument(_ arg: String, using functionsInfo: Functions.Info, in environment: Functions.Environment) -> String {
    
    guard (arg.first ?? " ") == "$" else { return arg } // Not a key argument
    
    let args = arg.split(separator: ".")
    
    guard args.count >= 2 else {
        Log.atError?.log("Missing source or key in argument")
        return "***error***"
    }
    
    switch args[0].lowercased() {
    
    case "$postinfo":
        
        guard let postInfo = environment.serviceInfo[.postInfoKey] as? PostInfo else {
            Log.atError?.log("No PostInfo found")
            return "***error***"
        }
        
        guard let result = postInfo[String(args[1])] else {
            Log.atError?.log("PostInfo does not contain key: \(args[1])")
            return "***error***"
        }
        
        return result
        
        
    case "$getinfo":
        
        guard let getInfo = environment.serviceInfo[.getInfoKey] as? Dictionary<String, String> else {
            Log.atError?.log("No GetInfo found")
            return "***error***"
        }
        
        guard let result = getInfo[String(args[1])] else {
            Log.atError?.log("GetInfo does not contain key: \(args[1])")
            return "***error***"
        }
        
        return result

        
    case "$functionsinfo":
        
        switch args[1].lowercased() {
            
        default:
            Log.atError?.log("No access to FunctionInfo mapped for key: \(args[1].lowercased())")
            return "***error***"
        }

        
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
        
        guard let sessionInfo = (environment.serviceInfo[.sessionKey] as? SessionInfo) else {
            Log.atError?.log("No SessionInfo found")
            return "***error***"
        }

        guard let account = sessionInfo[.accountKey] as? Account else {
            return ""
        }
        
        switch args[1].lowercased() {
        
        case "name": return account.name
            
        default:
            Log.atError?.log("No access to Account mapped for key: \(args[1].lowercased())")
            return "***error***"

        }
        
        
    default:
        Log.atError?.log("Unknown source for key argument: '\(args[0])'")
        return "***error***"
    }
}