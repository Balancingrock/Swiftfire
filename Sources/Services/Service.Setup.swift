// =====================================================================================================================
//
//  File:       Service.Setup.swift
//  Project:    Swiftfire
//
//  Version:    1.2.0
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
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Http
import Html
import SwifterLog
import Core
import Functions


func service_setup(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    func domainCommand(_ cmd: String) -> String {
        return "\(domain.setupKeyword!)/command/\(cmd)"
    }
    
    func loginDomainAdminPage() {
        
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
                            <input type="text" name="ID" value="name" autofocus><br>
                            <p style="margin-bottom:0px">Password:</p>
                            <input type="password" name="Password" value="****"><br><br>
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
    
    func domainAdminPage() {
        
        func domainParameterTable() -> String {
            
            let table = """
                <table>
                    <tr>
                        <th>Parameter</th><th>Value</th><th>Description</th>
                    </tr>
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
                </table>
            """
            
            return table
        }
        
        func domainTelemetryTable() -> String {
            
            var table: String = """
                <table>
                    <tr>
                        <th>Name</th><th>Value</th><th>Description</th>
                    </tr>
            """
            
            domain.telemetry.all.forEach() {
                table += """
                    <tr>
                        <td>\($0.name)</td><td>\($0.stringValue)</td><td>\($0.about)</td>
                    </tr>
                """
            }
        
            table += """
                </table>
            """
            
            return table
        }

        func domainBlacklistTable() -> String {
            
            var table: String = """
                <table>
                    <tr><th>Address</th><th>Action</th><th></th></tr>
            """
            
            domain.blacklist.list.forEach { (address, action) in
                
                let row = """
                    <tr>
                        <td>\(address)</td>
                        <td>
                            <form method="post" action="/\(domainCommand("UpdateBlacklist"))>
                                <div style="display:flex; flex-direction:column justify-content:start">
                                    <div style="display:flex; flex-direction:row align-items:center">
                                        <input type="radio" name="\(address)" value="close" checked="\(action == .closeConnection)">
                                        <span> Close Connection, <span>
                                    </div>
                                    <div style="display:flex; flex-direction:row align-items:center">
                                        <input type="radio" name="\(address)" value="503" checked="\(action == .send503ServiceUnavailable)">
                                        <span> 503 Service Unavailable, <span>
                                    </div>
                                    <div style="display:flex; flex-direction:row align-items:center">
                                        <input type="radio" name="\(address)" value="401" checked="\(action == .send401Unauthorized)">
                                        <span> 401 Unauthorized </span>
                                    </div>
                                    <input type="submit" title="Update">
                                </div>
                            </form>
                        </td>
                        <td>
                            <form method="post" action="/\(domainCommand("RemoveFromBlacklist"))>
                                <input type="submit" name="\(address)" value="Remove">
                            </form>
                        </td>
                    </tr>
                """
                
                table += row
            }
            
            table += """
                </table>
            """
            
            let createEntry: String = """
                <h3>Add address to blacklist</h3>
                <form method="post" action="/\(domainCommand("AddToBlacklist"))>
                    <table>
                        <tr>
                            <td>Address:</td>
                            <td><input type="text" name="newEntry", value=""></td>
                            <td>
                                <div style="display:flex; flex-direction:column; justify-content:start;">
                                    <div><input type="radio" name="action" value="close" checked="true"><span> Close Connection</span></div>
                                    <div><input type="radio" name="action" value="503" checked="false"><span> 503 Services Unavailable</span></div>
                                    <div><input type="radio" name="action" value="401" checked="false"><span> 401 Unauhorized</span></div>
                                </div>
                            </td>
                            <td><input type="submit" value="Add to Blacklist"></td>
                        </tr>
                    </table>
                </form>
            """
            
            return table + "<br>" + createEntry
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
            
            var table: String = """
                <form method="post" target="\(domainCommand("UpdateServices"))">
                    <table>
                        <tr>
                            <th>Index</th><th>Seq.</th><th>Service Name</th><th>Used</th>
                        </tr>
            """
            
            for row in tableRows {
                
                let entry: String = """
                    <tr>
                        <td>\(row.rowIndex)</td>
                        <td style="width: auto"><input type="text" name="seqName\(row.rowIndex)" value="\(row.rowIndex)"></td>
                        <td><input type="text" name="nameName\(row.rowIndex)" value="\(row.name)" disabled></td>
                        <td><input type="checkbox" name="usedName\(row.rowIndex)" value="usedName\(row.rowIndex)" \(row.usedByDomain ? "checked" : "")></td>
                    </tr>
                """
                table += entry
            }
            
            table += """
                    </table>
                    <input type="submit" name="Submit" value="Update Services">
                </form>
            """
            
            return table
        }
        
        let body: String = """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <meta http-equiv="X-UA-Compatible" content="IE=edge">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <meta name="theme-color" content="#ffffff">
                    <title>\(domain.name.capitalized) Admin Login</title>
                    <meta name="description" content="\(domain.name.capitalized) Admin">
                </head>
                <body>
                    <div style="display:flex; justify-content:center; margin-bottom:50px;">
                        <div style="margin-left:auto; margin-right:auto;">
                            <h1>\(domain.name.capitalized)</h1>
                            <h2>Parameters</h2>
                            \(domainParameterTable())
                            <h2>Telemetry</h2>
                            \(domainTelemetryTable())
                            <h2>Blacklist</h2>
                            \(domainBlacklistTable())
                            <h2>Domain Services</h2>
                            \(domainServicesTable())
                        </div>
                    </div>
                </body>
            </html>
        """

        response.body = body.data(using: .utf8)
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
        
    if let postInfo = info[.postInfoKey] as? PostInfo,
        let name = postInfo["ID"],
        let pwd = postInfo["Password"] {
            
        Log.atDebug?.log("Found login information for admin \(name)")
            
            
        // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt
            
        if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
            let now = Date().javaDate
            if now - previousAttempt < 2000 {
                session[.lastFailedLoginAttemptKey] = now
                loginDomainAdminPage()
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
                
                
            loginDomainAdminPage()
                
            return .next
        }
            
        
        Log.atNotice?.log("Domain: \(domain.name), admin: \(name) logged in", id: connection.logId)
            
            
        // Associate the account with the session. This allows access for subsequent admin pages.
            
        session[.accountKey] = account
    }
    
    
    // Check if an admin is logged in
    
    guard let account = session[.accountKey] as? Account, account.isAdmin else {
        Log.atAlert?.log("No account present", id: connection.logId)
        loginDomainAdminPage()
        return .next
    }

    guard account.isAdmin else {
        Log.atAlert?.log("Not an admin for domain: \(domain.name) using ID: \(account.name)", id: connection.logId)
        loginDomainAdminPage()
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
                
                if let postInfo = info[.postInfoKey] as? PostInfo {

                    switch urlComponents[2] {
                    
                    case "UpdateParameter": executeUpdateParameter(postInfo, domain)
                    case "UpdateBlacklist": break
                    case "RemoveFromBlacklist": break
                    case "AddToBlacklist": break
                    case "UpdateServices": break

                    default:
                        Log.atError?.log("No command with name \(urlComponents[2])")
                        break
                    }
                } else {
                    Log.atError?.log("PostInfo not present")
                }
            } else {
                Log.atError?.log("Too many parts in command")
            }
            
        default:
            Log.atWarning?.log("No option with name \(urlComponents[1])")
        }
    }
    
    
    // Return the domain admin page again
    
    domainAdminPage()
    return .next
}
    
fileprivate func executeUpdateParameter(_ postInfo: PostInfo, _ domain: Domain) {
    
    guard let parameter = postInfo["Parameter"] else {
        Log.atError?.log("Missing parameter name in postInfo")
        return
    }
    
    guard let value = postInfo["Value"] else {
        Log.atError?.log("Missing parameter value in postInfo")
        return
    }

    
    switch parameter {
    case "forewardurl": domain.forwardUrl = value
    case "enabled": domain.enabled = Bool(lettersOrDigits: value) ?? domain.enabled
    case "accesslogenabled": domain.accessLogEnabled = Bool(lettersOrDigits: value) ?? domain.accessLogEnabled
    case "four04logenabled": domain.four04LogEnabled = Bool(lettersOrDigits: value) ?? domain.four04LogEnabled
    case "sessionlogenabled": domain.sessionLogEnabled = Bool(lettersOrDigits: value) ?? domain.sessionLogEnabled
    case "phpmapindex":
        if domain.phpPath != nil {
            domain.phpMapIndex = Bool(lettersOrDigits: value) ?? domain.phpMapIndex
        }
    case "phpmapall":
        if domain.phpPath != nil {
            if Bool(lettersOrDigits: value) ?? domain.phpMapAll {
                domain.phpMapAll = true
                domain.phpMapIndex = true
            } else {
                domain.phpMapAll = false
            }
        }
    case "phptimeout":
        if domain.phpPath != nil {
            domain.phpTimeout = Int(value) ?? domain.phpTimeout
        }
    case "sessiontimeout": domain.sessionTimeout = Int(value) ?? domain.sessionTimeout
    default:
        Log.atError?.log("Unknown key '\(parameter)' with value '\(value)'")
    }
    
    domain.storeSetup()
}

