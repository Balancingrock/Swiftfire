// =====================================================================================================================
//
//  File:       KeyArgument.Read.swift
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
//       - Renamed function to `readKey`, renamed file to `KeyArgument.Read`
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation


/// Parse the given argument and return the requested value. The identifiers are case-insensitive. Use an exclamation mark behind the source identifier to return an empty string instead of nil if the requested parameter does not exist. Example: `$account.name!`.
///
/// Example: $requestinfo.name will return the value of the dictionary entry under request.info["name"]
///
/// Allowable identifiers
///
/// _requestinfo_: All possible strings. Returns a nil if the parameter does not exist
///
/// _functionsinfo_: None yet
///
/// _serviceinfo_:
///
///    - absoluteresourcepath (String)
///    - relativeresourcepath (String)
///    - responsestarted (Int64.description)
///
/// _sessioninfo_: None yet
///
/// _account_:
///
///    - name (String)
///    - is-domain-admin (Bool.description)
///    - is-moderator (Bool.description)
///
/// - Parameters:
///   - arg: The keyed argument.
///   - using: The functionInfo structure.
///   - in: The environment the function is executing in.
///
/// - Returns:
///   - The argument if the argument is empty or does not start with '$'
///   - The requested value if it exists.
///   - If the requested value does not exist it returns either nil or -if the source identifier has an exclamation mark- an empty string.

public func readKey(_ arg: String, using functionsInfo: Functions.Info, in environment: Functions.Environment) -> String? {
    
    guard !arg.isEmpty else {
        Log.atError?.log("Unexpected empty argument")
        return ""
    }
    
    var argument = arg

    guard argument.first == "$" else {
        Log.atDebug?.log("Returning \(argument) (not a key argument)")
        return arg
    } // Not a key argument
    
    argument.removeFirst()
        
    let emptyForNil: Bool
    if argument.last == "!" {
        emptyForNil = true
        argument.removeLast()
    } else {
        emptyForNil = false
    }
    
    let args = argument.split(separator: ".")
    
    guard args.count > 0 else {
        Log.atError?.log("Missing source or key in argument")
        return arg
    }
    
    let result = reader(args, functionsInfo, environment)
    
    return emptyForNil ? (result ?? "") : result
}


fileprivate func reader(_ args: Array<Substring>, _ functionsInfo: Functions.Info, _ environment: Functions.Environment) -> String? {
    
    switch args[0].lowercased() {
    
    case "request":
        
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }
        
        guard let result = environment.request.info[String(args[1]).lowercased()] else {
            Log.atDebug?.log("Request.Info does not contain key: \(args[1])")
            return nil
        }
        
        return result
        
        
    case "info":
        
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }

        guard let result = functionsInfo[String(args[1]).lowercased()] else {
            Log.atDebug?.log("FunctionInfo does not contain key: \(args[1])")
            return nil
        }
        
        return result

        
    case "service":
        
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }

        switch args[1].lowercased() {
            
        case "absolute-resource-path":
            
            return environment.serviceInfo[.absoluteResourcePathKey] as? String
            

        case "relative-resource-path":
            
            return environment.serviceInfo[.relativeResourcePathKey] as? String

            
        case "response-started":
        
            if let i = environment.serviceInfo[.responseStartedKey] as? Int64 {
                return String(i)
            } else {
                return nil
            }

        case "error-message":
            
            return environment.serviceInfo[.errorMessageKey] as? String


        default:
            Log.atError?.log("No access to ServiceInfo mapped for key: \(args[1].lowercased())")
            return nil
        }

        
    case "session":
        
        guard (environment.serviceInfo[.sessionKey] as? SessionInfo) != nil else {
            Log.atError?.log("No SessionInfo found")
            return nil
        }
        
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }

        switch args[1].lowercased() {
            
        default:
            Log.atError?.log("No access to SessionInfo mapped for key: \(args[1].lowercased())")
            return nil
        }

        
    case "account":
        
        guard let session = (environment.serviceInfo[.sessionKey] as? Session) else {
            Log.atError?.log("No Session found")
            return nil
        }

        switch args.count {
            
        case 1:
            
            return (session.info[.accountUuidKey] as? String) != nil ? "not-nil" : "nil"

            
        case 2:
                                    
            guard let account = environment.account else { return nil }
            
            switch args[1].lowercased() {
        
            case "name": return account.name
                
            case "uuid": return account.uuid.uuidString
            
            case "is-domain-admin": return String(account.isDomainAdmin)
            
            case "is-moderator": return String(account.isModerator)
            
            default:
                Log.atError?.log("No access to Account mapped for key: \(args[1].lowercased())")
                return nil
            }
        
        default:
            Log.atError?.log("Ilegal number of arguments for $account source: \(args.count)")
            return nil
        }
        
        
    case "domain":
        
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }

        switch args[1].lowercased() {
            
        case "name": return environment.domain.name
        
        case "root": return environment.domain.webroot
            
        case "foreward-url": return environment.domain.forwardUrl
            
        case "enabled": return String(environment.domain.enabled)
            
        case "accesslog-enabled": return String(environment.domain.accessLogEnabled)
            
        case "404log-enabled": return String(environment.domain.four04LogEnabled)
            
        case "sessionlog-enabled": return String(environment.domain.sessionLogEnabled)
            
        case "php-path": return (environment.domain.phpPath?.path ?? "")
            
        case "php-options":
            if environment.domain.phpPath != nil {
                return (environment.domain.phpOptions ?? "")
            } else {
                return "PHP Disabled"
            }
            
        case "php-map-index":
            if environment.domain.phpPath != nil {
                return String(environment.domain.phpMapIndex)
            } else {
                return "PHP Disabled"
            }
            
        case "php-map-all":
            if environment.domain.phpPath != nil {
                return String(environment.domain.phpMapAll)
            } else {
                return "PHP Disabled"
            }
            
        case "php-timeout":
            if environment.domain.phpPath != nil {
                return String(environment.domain.phpTimeout)
            } else {
                return "PHP Disabled"
            }
            
        case "sfresources": return environment.domain.sfresources
            
        case "session-timeout": return String(environment.domain.sessionTimeout)

        case "comment-auto-approval-threshold": return String(environment.domain.comments.forApproval.count)
        
        default:
            Log.atError?.log("No access to Domain mapped for key: \(args[1].lowercased())")
            return nil
        }
        
    
    case "server-telemetry":
            
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }

        let telemetryName = args[1]
        
        for t in serverTelemetry.all {
            if t.name == telemetryName { return t.stringValue }
        }

        Log.atError?.log("No access to server-telemetry mapped for key: \(args[1])")
        
        return nil

        
    case "server-parameter":
                
        guard args.count == 2 else {
            Log.atError?.log("Missing source or key in argument")
            return nil
        }

        let parameterName = args[1]

        for p in serverParameters.all {
            if p.name == parameterName { return p.stringValue }
        }

        Log.atError?.log("No access to server-parameter mapped for key: \(args[1])")
        
        return nil

        
    default:
        Log.atError?.log("Unknown source for key argument: '\(args[0])'")
        return nil
    }
}
