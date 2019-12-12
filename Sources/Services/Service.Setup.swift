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
                
            session[.accountUuidKey] = nil
                
                
            // Set the timestamp for the failed attempt
                
            session[.lastFailedLoginAttemptKey] = Date().javaDate
                
                
            loginPage(response, domain.name)
                
            return .next
        }
            
        
        Log.atNotice?.log("Domain: \(domain.name), admin: \(name) logged in", id: connection.logId)
            
            
        // Associate the account with the session. This allows access for subsequent admin pages.
            
        session[.accountUuidKey] = account
    }
    
    
    // Check if an admin is logged in
    
    guard let account = session.info.getAccount(inDomain: domain) else {
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
                session.info.remove(key: .accountUuidKey)
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
    
    if let account = session.info.getAccount(inDomain: domain), account.isDomainAdmin {
        setupPage(domain, account, response)
    } else {
        loginPage(response, domain.name)
    }
    return .next
}


fileprivate func executeUpdateServices(_ request: Request, _ domain: Domain) {
    
    struct ServiceItem {
        let index: Int
        let name: String
    }
    
    var serviceArr: Array<ServiceItem> = []
    
    var index = 0
    
    var error = false;
    
    while let _ = request.info["seqname\(index)"] {
        
        if let _ = request.info["usedname\(index)"] {
            
            if  let newIndexStr = request.info["seqname\(index)"],
                let newIndex = Int(newIndexStr) {
                
                if let newName = request.info["namename\(index)"] {
                    serviceArr.append(ServiceItem(index: newIndex, name: newName))
                } else {
                    error = true
                    Log.atError?.log("Missing nameName for index \(index)")
                }
                
            } else {
                error = true
                Log.atError?.log("Missing seqName for index \(index)")
            }
        }
        index += 1
    }
    
    guard error == false else { return }
    
    serviceArr.sort(by: { $0.index < $1.index })
    
    domain.serviceNames = serviceArr.map({ $0.name })
    
    domain.rebuildServices()
    
    domain.storeSetup()
    
    var str = ""
    if domain.serviceNames.count == 0 {
        str += "\nDomain Service Names:\n None\n"
    } else {
        str += "\nDomain Service Names:\n"
        domain.serviceNames.forEach() { str += " service name = \($0)\n" }
    }

    Log.atNotice?.log("Updated services for domain \(domain.name) to/n\(str)")
}

fileprivate func executeConfirmDeleteAccount(_ request: Request, _ domain: Domain) -> Bool {
    
    guard let adminId = request.info["admin-name"], let uuid = UUID(uuidString: adminId) else {
        Log.atError?.log("Missing admin ID")
        return false
    }
    
    return domain.accounts.getAccount(for: uuid) != nil
}

fileprivate func executeRemoveAccount(_ request: Request, _ domain: Domain) {
    
    guard let accountId = request.info["removeaccountid"] else {
        Log.atError?.log("Missing RemoveAccountId")
        return
    }

    if domain.accounts.disable(name: accountId) {
        Log.atNotice?.log("Account \(accountId) removed from domain \(domain.name)")
    } else {
        Log.atError?.log("Account not found for \(accountId) in domain \(domain.name)")
    }
}

fileprivate func executeAddAdminChangePassword(_ request: Request, _ domain: Domain) {
    
    guard let adminId = request.info["adminid"], let uuid = UUID(uuidString: adminId) else {
        Log.atError?.log("Missing admin ID")
        return
    }

    guard let adminPwd = request.info["adminpassword"] else {
        Log.atError?.log("Missing admin password")
        return
    }

    if let account = domain.accounts.getAccount(for: uuid) {
        
        
        // Grant admin rights to this account
        
        if !account.isDomainAdmin {
            account.isDomainAdmin = true
            Log.atNotice?.log("Enabled admin rights for account \(adminId)")
        }
        
        
        // Change the password
        
        if account.updatePassword(adminPwd) {
            Log.atNotice?.log("Updated the password for domain admin \(adminId)")
        } else {
            Log.atError?.log("Failed to update the password for domain admin \(adminId)")
        }
        
        account.isEnabled = true
        account.emailVerificationCode = ""

    } else {
        
        
        // Add an admin
        
        if let account = domain.accounts.newAccount(name: adminId, password: adminPwd) {

            account.isDomainAdmin = true
            
            account.isEnabled = true
            account.emailVerificationCode = ""
            
            Log.atNotice?.log("Added domain admin account with id: \(adminId)")

        } else {
            
            Log.atError?.log("Failed to add domain admin for id: \(adminId)")
        }
    }
}

fileprivate func executeChangePassword(_ request: Request, _ domain: Domain) {
    
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


fileprivate func createAccountDetailPage(_ request: Request, _ domain: Domain, _ response: Response) {
    
    guard let str = request.info["account-uuid"], let uuid = UUID(uuidString: str) else {
        Log.atError?.log("Missing account-uuid in request.info")
        response.code = ._500_InternalServerError
        return
    }
    
    guard let account = domain.accounts.getAccount(for: uuid) else {
        Log.atError?.log("Missing account")
        response.code = ._500_InternalServerError
        return
    }
    
    
    // Prevent confusion due to 'strange values' (not an error though)
    
    if account.newPasswordVerificationCode.isEmpty {
        account.newPasswordRequestTimestamp = 0
    }
    
    
    // Build the page
    
    let html: String =
    """
    <!DOCTYPE html>
    <html>
        <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta name="theme-color" content="#ffffff">
            <title>Account: \(account.name)</title>
            <meta name="description" content="Account info">
            <style>
                table {
                    border-collapse: collapse;
                    width: 100%;
                }

                td, th {
                    border: 1px solid gray;
                    text-align: left;
                    padding: 8px;
                }

                tr:nth-child(even) {
                    background-color: lightgray;
                }
            </style>
        </head>
        <body>
            <h1 style="margin-left:auto; margin-right:auto;">Account name: \(account.name)</h1>
            <table>
                <thead>
                    <tr>
                        <th>Parameter</th>
                        <th>Value</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Name:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="account-name">
                                <input type="text" name="value" value="\(account.name)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">The name of the account. Changes will be retroactive.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Is Enabled:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="is-enabled">
                                <input type="checkbox" name="value" value="true" \(account.isEnabled ? "checked" : "")>
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">No changes can be made to the user content associated with this account as long as it is disabled. Note that a user cannot log in as long as the emailVerificationCode is not empty.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Email address:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="email-address">
                                <input type="text" name="value" value="\(account.emailAddress)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">Updates to this field will be accepted AS IS. All auto-generated emails will be sent to this address.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Email verification code:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="email-verification-code">
                                <input type="text" name="value" value="\(account.emailVerificationCode)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">This will be empty once the email address is verified.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Is domain administrator:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="is-domain-admin">
                                <input type="checkbox" name="value" value="true" \(account.isDomainAdmin ? "checked" : "")>
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">If enabled, the account user gets access to the domain setup page.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>New password verification code:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="new-password-verification-code">
                                <input type="text" name="value" value="\(account.newPasswordVerificationCode)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">Used temporary when the user requests a new password.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>New password timestamp:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="new-password-timestamp">
                                <input type="text" name="value" value="\(account.newPasswordRequestTimestamp)" disabled>
                                <input type="submit" value="Restart">
                            </form>
                        </td>
                        <td>
                            <p style="margin-bottom:0;">Time of the new password request made by the user (the request is valid for 24 hours). Will be zero if no request is pending. 'Restart' will start the 24 hour window again, but only if there is a new password verification code.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Account directory URL:</td>
                        <td colspan="2">\(account.dir.path)</td>
                    </tr>
                    <tr>
                        <td>New password timestamp:</td>
                        <td>
                            <form action="/setup/account-details/account-update" method="post">
                                <input type="hidden" name="account-uuid" value="\(account.uuid.uuidString)">
                                <input type="hidden" name="parameter" value="new-password">
                                <input type="text" name="value" value="">
                                <input type="submit" value="Set Password">
                            </form>
                        </td>
                    <td>
                        <p style="margin-bottom:0;">The password is not shown, but a new password can be set. A new password must have more than 4 characters. Setting a password of 4 characters or less will fail silently.</p>
                        </td>
                    </tr>
                    <tr>
                        <td>Account directory URL:</td>
                        <td colspan="2">\(account.dir.path)</td>
                    </tr>
                </tbody>
            </table>
            <div>
                <p><a href="/setup">Return to setup page</a></p>
            </div>
        </body>
    </html>
    """
    
    response.body = html.data(using: .utf8)
    response.code = Response.Code._200_OK
    response.contentType = mimeTypeHtml
}


fileprivate func updateAccount(_ request: Request, _ domain: Domain, _ connection: SFConnection) {
    
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

internal func domainCommand(_ domain: Domain, _ cmd: String) -> String {
    return "/\(domain.setupKeyword!)/command/\(cmd)"
}
