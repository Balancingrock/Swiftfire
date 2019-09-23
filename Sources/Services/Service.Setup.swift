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
// 1.3.0 - Merged getInfo and postInfo into register.info
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
    
    func domainCommand(_ cmd: String) -> String {
        return "/\(domain.setupKeyword!)/command/\(cmd)"
    }
    
    func domainAdminLoginPage() {
        
        let page: String =
        """
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="utf-8">
                <meta http-equiv="X-UA-Compatible" content="IE=edge">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <meta name="theme-color" content="#ffffff">
                <title>\(domain.name) Admin Login</title>
                <meta name="description" content="\(domain.name) Admin">
            </head>
            <body>
                <div style="display:flex; justify-content:center; margin-bottom:50px;">
                    <div style="margin-left:auto; margin-right:auto;">
                        <form action="/setup" method="post">
                            <p style="margin-bottom:0px">ID:</p>
                            <input type="text" name="LoginID" value="name" autofocus><br>
                            <p style="margin-bottom:0px">Password:</p>
                            <input type="password" name="LoginPassword" value="****"><br><br>
                            <input type="submit" value="Login">
                        </form>
                    </div>
                </div>
            </body>
        </html>
        """
        
        response.body = page.data(using: .utf8)
        response.code = Response.Code._200_OK
        response.contentType = mimeTypeHtml
    }
    
    func domainAdminPage(_ account: Account) {
        
        func domainParameterTable() -> String {
            
            let html = """
            <div class="center-content">
            <div class="table-container">
                <table>
                <thead>
                    <tr>
                        <th>Parameter</th><th>Value</th><th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Enabled</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="enabled">
                                <input type="text" name="Value" value="\(domain.enabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The domain is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>Access Log</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="accessLogEnabled">
                                <input type="text" name="Value" value="\(domain.accessLogEnabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The access log is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>404 Log</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="four04LogEnabled">
                                <input type="text" name="Value" value="\(domain.four04LogEnabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The 404 log is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>Session Log</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="sessionLogEnabled">
                                <input type="text" name="Value" value="\(domain.sessionLogEnabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The session log is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>Session Timeout</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="sessionTimeout">
                                <input type="text" name="Value" value="\(domain.sessionTimeout)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>A session is considered expired when inactive for this long (in seconds)</td>
                    </tr>
                    <tr>
                        <td>PHP Map Index</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="phpMapIndex">
                                <input type="text" name="Value" value="\(domain.phpMapIndex)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>Maps index requests to include index.php and index.sf.php</td>
                    </tr>
                    <tr>
                        <td>PHP Map All</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="phpMapAll">
                                <input type="text" name="Value" value="\(domain.phpMapAll)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>Allows to map *.html to *.php</td>
                    </tr>
                    <tr>
                        <td>PHP Timeout</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="phpTimeout">
                                <input type="text" name="Value" value="\(domain.phpTimeout)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>Timeout for PHP processing (in mSec)</td>
                    </tr>
                    <tr>
                        <td>Foreward URL</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateParameter"))">
                                <input type="hidden" name="Parameter" value="forwardUrl">
                                <input type="text" name="Value" value="\(domain.forwardUrl)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>(Optional) Forwards all incoming traffic to this url</td>
                    </tr>
                </tbody>
                </table>
            </div>
            </div>
            """
            
            return html
        }
        
        func domainTelemetryTable() -> String {
            
            var html: String = """
                <div class="center-content">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Name</th><th>Value</th><th>Description</th>
                                </tr>
                            </thead>
                            <tbody>
            """
            
            domain.telemetry.all.forEach() {
                html += """
                    <tr>
                        <td>\($0.name)</td><td>\($0.stringValue)</td><td>\($0.about)</td>
                    </tr>
                """
            }
        
            html += """
                            </tbody>
                        </table>
                    </div>
                </div>
            """
            
            return html
        }

        func domainBlacklistTable() -> String {
            
            var html: String = """
                <div class="center-content">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr><th>Address</th><th>Action</th><th></th></tr>
                            </thead>
                            <tbody>
            """
            
            domain.blacklist.list.sorted(by: { (one: (key: String, value: Blacklist.Action), two: (key: String, value: Blacklist.Action)) -> Bool in
                one.key < two.key
            }) .forEach { (address, action) in
                
                let row = """
                    <tr>
                        <td>\(address)</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateBlacklist"))">
                                <div style="display:flex; flex-direction:row; align-items:center;">
                                    <input type="hidden" name="Address" value="\(address)">
                                    <input type="radio" name="Action" value="close" \(action == .closeConnection ? "checked" : "")>
                                    <span> Close Connection, <span>
                                    <input type="hidden" name="Address" value="\(address)">
                                    <input type="radio" name="Action" value="503" \(action == .send503ServiceUnavailable ? "checked" : "")>
                                    <span> 503 Service Unavailable, <span>
                                    <input type="hidden" name="Address" value="\(address)">
                                    <input type="radio" name="Action" value="401" \(action == .send401Unauthorized ? "checked" : "")>
                                    <span> 401 Unauthorized </span>
                                    <input type="submit" value="Update Action">
                                </div>
                            </form>
                        </td>
                        <td>
                            <form method="post" action="\(domainCommand("RemoveFromBlacklist"))">
                                <input type="hidden" name="Address" value="\(address)">
                                <input type="submit" value="Remove">
                            </form>
                        </td>
                    </tr>
                """
                
                html += row
            }
            
            html += """
                            </tbody>
                        </table>
                    </div>
                </div>
                <h3>Add address to blacklist</h3>
                <div class="center-content">
                    <div class="table-container">
                        <form method="post" action="\(domainCommand("AddToBlacklist"))")>
                            <table>
                                <tbody>
                                    <tr>
                                        <td>Address:</td>
                                        <td><input type="text" name="Address" value=""></td>
                                    </tr>
                                    <tr>
                                        <td>Action:</td>
                                        <td>
                                            <div style="display:flex; flex-direction:row; align-items:center;">
                                                <input type="radio" name="Action" value="close" checked><span> Close Connection</span>
                                                <input type="radio" name="Action" value="503"><span> 503 Services Unavailable</span>
                                                <input type="radio" name="Action" value="401"><span> 401 Unauhorized</span>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td></td>
                                        <td><input type="submit" value="Add to Blacklist"></td>
                                    </tr>
                                </tbody>
                            </table>
                        </form>
                    </div>
                </div>
            """
            
            return html
        }
        
        func domainServicesTable() -> String {
        
            
            // Prepare the table data
            
            struct TableRow {
                let rowIndex: Int
                let name: String
                let usedByDomain: Bool
            }
            
            var tableRows: Array<TableRow> = []
            
            var index: Int = 0
            for service in domain.services {
                tableRows.append(TableRow(rowIndex: index, name: service.name, usedByDomain: true))
                index += 1
            }
            
            OUTER: for service in services.registered {
                for row in tableRows {
                    if row.name == service.value.name { continue OUTER }
                }
                tableRows.append(TableRow(rowIndex: tableRows.count, name: service.value.name, usedByDomain: false))
            }
            
            
            // Create the table
            
            var html: String = """
                <div class="center-content">
                    <div class="table-container">
                        <form method="post" action="\(domainCommand("UpdateServices"))">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Index</th>
                                        <th>Seq.</th>
                                        <th>Service Name</th>
                                        <th>Used</th>
                                    </tr>
                                </thead>
                                <tbody>
            
            """
            
            for row in tableRows {
                
                let entry: String = """
                    <tr>
                        <td>\(row.rowIndex)</td>
                        <td><input type="text" name="seqName\(row.rowIndex)" value="\(row.rowIndex)"></td>
                        <td><input type="text" name="nameName\(row.rowIndex)" value="\(row.name)" disabled></td>
                        <td><input type="hidden" name="nameName\(row.rowIndex)" value="\(row.name)"></td>
                        <td><input type="checkbox" name="usedName\(row.rowIndex)" value="usedName\(row.rowIndex)" \(row.usedByDomain ? "checked" : "")></td>
                    </tr>
                
                """
                html += entry
            }
            
            html += """
                                </tbody>
                            </table>
                            <div class="center-content">
                                <div class="center-self submit-offset">
                                    <input type="submit" value="Update Services">
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            """
            
            return html
        }
        
        func domainAdminList() -> String {
            
            var html: String = """
                <div class="center-content">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Account ID</th>
                                    <th></th>
                                    <th></th>
                                </tr>
                            </thead>
                            <tbody>
            """
            
            for accountName in domain.accounts {
                
                if accountName != account.name {
                    
                    let row = """
                        <tr>
                            <td>\(accountName)</td>
                            <td>
                                <form action="\(domainCommand("ConfirmDeleteAccount"))" method="post">
                                    <input type="hidden" name="AdminID" value="\(accountName)">
                                    <input type="submit" value="Remove">
                                </form>
                            </td>
                            <td>
                                <form action="\(domainCommand("AddAdminChangePassword"))" method="post">
                                    <input type="hidden" name="AdminID" value="\(accountName)">
                                    <input type="text" name="AdminPassword" value="">
                                    <input type="submit" value="Set New Password">
                                </form>
                            </td>
                        </tr>
                    """
                    
                    html += row
                    
                } else {
                    
                    let row = """
                        <tr>
                            <td>\(accountName)</td>
                            <td></td>
                            <td>
                                <form action="\(domainCommand("AddAdminChangePassword"))" method="post">
                                    <input type="hidden" name="AdminID" value="\(accountName)">
                                    <input type="text" name="AdminPassword" value="">
                                    <input type="submit" value="Set New Password">
                                </form>
                            </td>
                        </tr>
                    """
                    
                    html += row
                }
            }
            
            html += """
                            </tbody>
                        </table>
                    </div>
                </div>
            """

            
            return html
        }
        
        func addDomainAdmin() -> String {
            
            let html: String = """
                <div class="center-content">
                    <div class="table-container">
                        <form method="post" action="\(domainCommand("AddAdminChangePassword"))">
                            <input type="hidden" name="Domain" value=".show($postInfo.DomainName)">
                            <table>
                                <tr>
                                    <td>Domain admin:</td>
                                    <td><input type="text" name="AdminID" value=""></td>
                                    <td></td>
                                </tr>
                                <tr>
                                    <td>Password:</td>
                                    <td><input type="text" name="AdminPassword" value=""></td>
                                    <td><input type="submit" value="Add Admin / Change Password"></td>
                                </tr>
                            </table>
                        </form>
                    </div>
                </div>
            """
            
            return html
        }
        
        func logoff() -> String {
            
            let html: String = """
                <div class="center-content">
                    <div class="table-container">
                        <form method="post" action="\(domainCommand("Logoff"))">
                            <input type="submit" value="Logoff">
                        </form>
                    </div>
                </div>
            """
            
            return html
        }

        let html: String = """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <meta http-equiv="X-UA-Compatible" content="IE=edge">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <meta name="theme-color" content="#ffffff">
                    <title>\(domain.name.capitalized) Admin Login</title>
                    <meta name="description" content="\(domain.name.capitalized) Admin">
                    <style>
                        h1 { text-align: center; }
                        h2 { text-align: center; }
                        h3 { text-align: center; }
                        .center-content { display:flex; flex-direction:column; justify-content:center }
                        .center-self { margin-left:auto; margin-right:auto; }
                        .bottom-offset { margin-bottom: 100px }
                        .table-container { background-color:#f0f0f0; border: 1px solid lightgray; margin-left:auto; margin-right:auto; }
                        .submit-offset { margin-top:5px; margin-bottom: 2px; }
                    </style>
                </head>
                <body>
                    <div class="bottom-offset">
                        <div>
                            <h1>\(domain.name.uppercased())</h1>
                            <h2>Parameters</h2>
                            \(domainParameterTable())
                            <h2>Telemetry</h2>
                            \(domainTelemetryTable())
                            <h2>Blacklist</h2>
                            \(domainBlacklistTable())
                            <h2>Domain Services</h2>
                            \(domainServicesTable())
                            <h2>Domain admin list</h2>
                            \(domainAdminList())
                            <h2>Add Admin or change Password</h2>
                            \(addDomainAdmin())
                            <h2>Logoff</h2>
                            \(logoff())
                        </div>
                    </div>
                </body>
            </html>
        """

        response.body = html.data(using: .utf8)
        response.code = Response.Code._200_OK
        response.contentType = mimeTypeHtml
    }
    
    func domainConfirmRemoveAccountPage(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
        
        let adminId = requestInfo["AdminID"]!

        let html: String =
        """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <meta http-equiv="X-UA-Compatible" content="IE=edge">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <meta name="theme-color" content="#ffffff">
                    <title>Confirm Account Removal</title>
                    <meta name="description" content="Remove account">
                </head>
                <body>
                    <div style="display:flex; justify-content:center; margin-bottom:50px;">
                        <div style="margin-left:auto; margin-right:auto;">
                            <h1>Confirm removal of account with name: \(adminId)</h1>
                            <form method="post">
                                <input type="hidden" name="RemoveAccountId" value="\(adminId)">
                                <input type="submit" value="Confirmed" formaction="\(domainCommand("RemoveAccount"))">
                                <input type="submit" value="Don't remove" formaction="/\(domain.setupKeyword!)">
                            </form>
                        </div>
                    </div>
                </body>
            </html>
        """
        
        response.body = html.data(using: .utf8)
        response.code = Response.Code._200_OK
        response.contentType = mimeTypeHtml
    }
    
    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // Prepare the url
    
    guard let urlstr = request.url else {
        Log.atError?.log("No request URL found", id: connection.logId)
        response.code = Response.Code._400_BadRequest
        return .next
    }
    
    Log.atDebug?.log("Raw URL request: \(urlstr)")
    
    let urlComponents = urlstr.split(separator: "/")
    
    guard urlComponents.count > 0 && urlComponents.count <= 3 else { return .next }
    
    
    // If the first component contains '<setupKeyword>' then continue.
    
    guard String(urlComponents[0]) == domain.setupKeyword else { return .next }
    
    
    // ======================================================================
    // There must be a session, without an active session nothing is possible
    // ======================================================================
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atCritical?.log("No session found, this service should come AFTER the 'getSession' service.", id: connection.logId)
        domain.telemetry.nof500.increment()
        response.code = Response.Code._500_InternalServerError
        return .next
    }
    
    
    // ===========================================================================
    // If login information is available, then verify if it is from a domain admin
    // ===========================================================================
        
    if let name = request.info["LoginID"], let pwd = request.info["LoginPassword"] {
            
        Log.atDebug?.log("Found login information for admin \(name)")
            
            
        // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt
            
        if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
            let now = Date().javaDate
            if now - previousAttempt < 2000 {
                session[.lastFailedLoginAttemptKey] = now
                domainAdminLoginPage()
                return .next
            }
        }
            
            
        // Get the account for the login data
            
        guard let account = domain.accounts.getAccount(for: name, using: pwd), account.isAdmin else {
                
            // The login attempt failed, no account found.
                
            Log.atNotice?.log("Admin login failed for domain: \(domain.name) using ID: \(name)", id: connection.logId)
                
                
            // Failed login, reset possible account
                
            session[.accountKey] = nil
                
                
            // Set the timestamp for the failed attempt
                
            session[.lastFailedLoginAttemptKey] = Date().javaDate
                
                
            domainAdminLoginPage()
                
            return .next
        }
            
        
        Log.atNotice?.log("Domain: \(domain.name), admin: \(name) logged in", id: connection.logId)
            
            
        // Associate the account with the session. This allows access for subsequent admin pages.
            
        session[.accountKey] = account
    }
    
    
    // Check if an admin is logged in
    
    guard let account = session[.accountKey] as? Account else {
        Log.atDebug?.log("No account present", id: connection.logId)
        domainAdminLoginPage()
        return .next
    }

    guard account.isAdmin else {
        Log.atDebug?.log("Not an admin for domain: \(domain.name) using ID: \(account.name)", id: connection.logId)
        domainAdminLoginPage()
        return .next
    }
    
    
    // A domain administrator is logged in
    

    // =======================================
    // Try to execute a command if it is given
    // =======================================
    
    if urlComponents.count > 1 {
        
        switch urlComponents[1] {
        case "command":
        
            if urlComponents.count == 3 {
                
                switch urlComponents[2] {
                    
                case "UpdateParameter": executeUpdateParameter(request.info, domain)
                case "UpdateBlacklist": executeUpdateBlacklist(request.info, domain)
                case "RemoveFromBlacklist": executeRemoveFromBlacklist(request.info, domain)
                case "AddToBlacklist": executeAddToBlacklist(request.info, domain)
                case "UpdateServices": executeUpdateServices(request.info, domain)
                case "ConfirmDeleteAccount":
                    if executeConfirmDeleteAccount(request.info, domain) {
                        domainConfirmRemoveAccountPage(request.info, domain)
                        return .next
                    }
                        
                case "RemoveAccount": executeRemoveAccount(request.info, domain)
                case "AddAdminChangePassword": executeAddAdminChangePassword(request.info, domain)
                        
                case "Logoff":
                    session.info.remove(key: .accountKey)
                    Log.atNotice?.log("Admin logged out")
                        
                default:
                    Log.atError?.log("No command with name \(urlComponents[2])")
                    break
                }

            } else {
                Log.atError?.log("Too many parts in command")
            }
            
        default:
            Log.atWarning?.log("No option with name \(urlComponents[1])")
        }
    }
    
    
    // Return the domain admin page again
    
    if let account = session[.accountKey] as? Account, account.isAdmin {
        domainAdminPage(account)
    } else {
        domainAdminLoginPage()
    }
    return .next
}
    
fileprivate func executeUpdateParameter(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    guard let parameter = requestInfo["Parameter"] else {
        Log.atError?.log("Missing parameter name in postInfo")
        return
    }
    
    guard let value = requestInfo["Value"] else {
        Log.atError?.log("Missing parameter value in postInfo")
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

fileprivate func executeUpdateBlacklist(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    guard let address = requestInfo["Address"] else {
        Log.atError?.log("Missing address")
        return
    }
    
    guard let actionStr = requestInfo["Action"] else {
        Log.atError?.log("Missing address")
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
    
    if domain.blacklist.update(action: action, for: address) {
        Log.atNotice?.log("Updated blacklist action for \(address) to \(action) in domain \(domain.name)")
    } else {
        Log.atNotice?.log("Failed to update blacklist action for \(address) to \(action) in domain \(domain.name)")
    }
    
    domain.blacklist.store(to: Urls.domainBlacklistFile(for: domain.name))

}

fileprivate func executeRemoveFromBlacklist(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    guard let address = requestInfo["Address"] else {
        Log.atError?.log("Missing address")
        return
    }

    if domain.blacklist.remove(address) {
        Log.atNotice?.log("Removed address \(address) from the blacklist for domain \(domain.name)")
    } else {
        Log.atNotice?.log("Files to removed address \(address) from the blacklist for domain \(domain.name)")
    }
    
    domain.blacklist.store(to: Urls.domainBlacklistFile(for: domain.name))
}

fileprivate func executeAddToBlacklist(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    guard let address = requestInfo["Address"] else {
        Log.atError?.log("Missing address")
        return
    }
    
    guard let actionStr = requestInfo["Action"] else {
        Log.atError?.log("Missing address")
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

fileprivate func executeUpdateServices(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    struct ServiceItem {
        let index: Int
        let name: String
    }
    
    var serviceArr: Array<ServiceItem> = []
    
    var index = 0
    
    var error = false;
    
    while let _ = requestInfo["seqName\(index)"] {
        
        if let _ = requestInfo["usedName\(index)"] {
            
            if  let newIndexStr = requestInfo["seqName\(index)"],
                let newIndex = Int(newIndexStr) {
                
                if let newName = requestInfo["nameName\(index)"] {
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

fileprivate func executeConfirmDeleteAccount(_ requestInfo: Dictionary<String, String>, _ domain: Domain) -> Bool {
    
    guard let adminId = requestInfo["AdminID"] else {
        Log.atError?.log("Missing admin ID")
        return false
    }
    
    return domain.accounts.getAccountWithoutPassword(for: adminId) != nil
}

fileprivate func executeRemoveAccount(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    guard let accountId = requestInfo["RemoveAccountId"] else {
        Log.atError?.log("Missing RemoveAccountId")
        return
    }

    if domain.accounts.remove(name: accountId) {
        Log.atNotice?.log("Account \(accountId) removed from domain \(domain.name)")
    } else {
        Log.atError?.log("Account not found for \(accountId) in domain \(domain.name)")
    }
}

fileprivate func executeAddAdminChangePassword(_ requestInfo: Dictionary<String, String>, _ domain: Domain) {
    
    guard let adminId = requestInfo["AdminID"] else {
        Log.atError?.log("Missing admin ID")
        return
    }

    guard let adminPwd = requestInfo["AdminPassword"] else {
        Log.atError?.log("Missing admin password")
        return
    }

    if let account = domain.accounts.getAccountWithoutPassword(for: adminId) {
        
        
        // Grant admin rights to this account
        
        if !account.isAdmin {
            account.isAdmin = true
            Log.atNotice?.log("Enabled admin rights for account \(adminId)")
        }
        
        
        // Change the password
        
        if account.updatePassword(adminPwd) {
            Log.atNotice?.log("Updated the password for domain admin \(adminId)")
        } else {
            Log.atError?.log("Failed to update the password for domain admin \(adminId)")
        }
        
        
    } else {
        
        
        // Add an admin
        
        if let account = domain.accounts.newAccount(name: adminId, password: adminPwd) {

            account.isAdmin = true
            
            Log.atNotice?.log("Added domain admin account with id: \(adminId)")

        } else {
            
            Log.atError?.log("Failed to add domain admin for id: \(adminId)")
        }
    }
}
