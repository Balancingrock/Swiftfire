// =====================================================================================================================
//
//  File:       Service.Setup.swift
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
// 1.3.0 - Replaced postInfo with request.info
//       - Removed inout from the service signature
//       - Updated for account changes
//       - Added account details management
//       - Changed 'requestinfo' identifier to 'request'
// 1.2.1 - Removed dependency on Html
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Http
import SwifterLog
import Core


/// Allows a domain admin to configure the domain. Only active if the URL that was requested started with the domain setup keyword.
///
/// _Input_:
///    - request.cookies: Will be checked for an existing session cookie.
///    - domain.sessions: Will be checked for an existing session, or a new session.
///    - domain.sessionTimeout: If the timeout < 1, then no session will be created.
///
/// _Output_:
///    - response
///
/// _Sequence_:
///   - Should be called after DecodePostFormUrlEncoded.

func service_setup(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: Services.Info, _ response: Response) -> Services.Result {

    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // Need >0, <4 url parts
        
    let urlComponents = request.resourcePathParts
    
    guard urlComponents.count > 0 && urlComponents.count <= 3 else { return .next }
    
    
    // If the first component contains '<setupKeyword>' then continue.
    
    guard String(urlComponents[0]) == domain.setupKeyword else { return .next }
    
    
    // ======================================================================
    // There must be a session, without an active session nothing is possible
    // ======================================================================
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atCritical?.log("No session found, this service should come after the 'getSession' service.", id: connection.logId)
        domain.telemetry.nof500.increment()
        response.code = Response.Code._500_InternalServerError
        return .next
    }
    
    
    // ===========================================================================
    // If login information is available, then verify if it is from a domain admin
    // ===========================================================================
        
    if let name = request.info["login-name"], let pwd = request.info["login-password"] {
            
        Log.atDebug?.log("Found login information for admin \(name)")
            
            
        // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt
            
        if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
            let now = Date().javaDate
            if now - previousAttempt < 2000 {
                session[.lastFailedLoginAttemptKey] = now
                loginPage(response, domain.name)
                return .next
            }
        }
            
            
        // Get the account for the login data
            
        guard let account = domain.accounts.getAccount(withName: name, andPassword: pwd), account.isDomainAdmin else {
                
            // The login attempt failed, no account found.
                
            Log.atNotice?.log("Admin login failed for domain: \(domain.name) using ID: \(name)", id: connection.logId)
                
                
            // Failed login, reset possible account
                
            session.userLogout()
                
                
            // Set the timestamp for the failed attempt
                
            session[.lastFailedLoginAttemptKey] = Date().javaDate
                
                
            loginPage(response, domain.name)
                
            return .next
        }
            
        
        Log.atNotice?.log("Domain: \(domain.name), admin: \(name) logged in", id: connection.logId)
            
            
        // Associate the account with the session. This allows access for subsequent admin pages.
            
        session[.accountUuidKey] = account.uuid.uuidString
    
    } else {
        
        Log.atDebug?.log("No login parameters found")
    }
    
    
    // Check if an admin is logged in
    
    guard let account = session.getAccount(inDomain: domain) else {
        Log.atDebug?.log("No account present", id: connection.logId)
        loginPage(response, domain.name)
        return .next
    }

    guard account.isDomainAdmin else {
        Log.atDebug?.log("Not an admin for domain: \(domain.name) using ID: \(account.name)", id: connection.logId)
        loginPage(response, domain.name)
        return .next
    }
    
    
    // A domain administrator is logged in
    

    // =======================================
    // Try to execute a command if it is given
    // =======================================
    
    if urlComponents.count > 1 {
        
        switch urlComponents[1] {
        case "command":
                        
            guard urlComponents.count == 3 else {
                response.code = ._400_BadRequest
                return .next
            }
            
            switch urlComponents[2] {
                
            case "update-parameter": executeUpdateParameter(request, domain)
            case "update-blacklist": executeUpdateBlacklist(request, domain)
            case "remove-from-blacklist": executeRemoveFromBlacklist(request, domain)
            case "add-to-blacklist": executeAddToBlacklist(request, domain)
            case "update-services": executeUpdateServices(request, domain)
            case "confirm-delete-account":
                if executeConfirmDeleteAccount(request, domain) {
                    confirmAccountRemovalPage(request, response, domain)
                    return .next
                }
                
            case "remove-account": executeRemoveAccount(request, domain)
            case "add-admin-change-password": executeAddAdminChangePassword(request, domain)
            case "change-password": executeChangePassword(request, domain)
            case "logoff":
                session.userLogout()
                Log.atNotice?.log("Admin logged out")
                
            default:
                Log.atError?.log("No command with name \(urlComponents[2])")
                break
            }
            
        case "account-details":
            
            switch urlComponents.count {
            case 3:
                
                if urlComponents[2] == "account-update" {
                    updateAccount(request, domain, connection)
                    fallthrough
                } else {
                    Log.atError?.log("Unknown account detail update: \(urlComponents[2])")
                    response.code = ._400_BadRequest
                    return .next
                }

                
            case 2:

                createAccountDetailPage(request, domain, response)

                
            default:

                response.code = ._400_BadRequest
            }

            return .next
            
            
        default:
            Log.atWarning?.log("No option with name \(urlComponents[1])")
        }
    }
    
    
    // Return the setup page again unless the admin logged out or a non-admin account logged in
    
    if let account = session.getAccount(inDomain: domain), account.isDomainAdmin {
        Log.atDebug?.log("Returning setup page")
        setupPage(domain, account, response)
    } else {
        Log.atDebug?.log("Returning login page")
        loginPage(response, domain.name)
    }
    return .next
}

