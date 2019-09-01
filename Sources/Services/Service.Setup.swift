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
        return "\(domain.webroot)/\(domain.setupKeyword!)/\(cmd)"
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
                        <p style="margin-bottom:0px">ID:</p>
                        <input type="text" name="ID" value="name" autofocus><br>
                        <p style="margin-bottom:0px">Password:</p>
                        <input type="password" name="Password" value="****"><br><br>
                        <input style="width:100%" type="submit" value="Login">
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
                    <th>
                        <td>Parameter</td><td>Value</td><td>Description</td>
                    </th>
                    <tr>
                        <td>Enabled</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="enabled" value="\(domain.enabled)">
                                <input type="submit" name="UpdateN" value="UpdateV">
                            </form>
                        </td>
                        <td>The domain is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>Access Log</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="accessLogEnabled" value="\(domain.accessLogEnabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The access log is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>404 Log</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="four04LogEnabled" value="\(domain.four04LogEnabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The 404 log is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>Session Log</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="sessionLogEnabled" value="\(domain.sessionLogEnabled)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>The session log is enabled when set to 'true', disabled otherwise</td>
                    </tr>
                    <tr>
                        <td>Session Timeout</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="sessionTimeout" value="\(domain.sessionTimeout)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>A session is considered expired when inactive for this long (in seconds)</td>
                    </tr>
                    <tr>
                        <td>PHP Map Index</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="phpMapIndex" value="\(domain.phpMapIndex)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>Maps index requests to include index.php and index.sf.php</td>
                    </tr>
                    <tr>
                        <td>PHP Map All</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="phpMapAll" value="\(domain.phpMapAll)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>Allows to map *.html to *.php</td>
                    </tr>
                    <tr>
                        <td>PHP Timeout</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="phpTimeout" value="\(domain.phpTimeout)">
                                <input type="submit" value="Update">
                            </form>
                        </td>
                        <td>Timeout for PHP processing (in mSec)</td>
                    </tr>
                    <tr>
                        <td>Foreward URL</td>
                        <td>
                            <form method="post" action="\(domainCommand("UpdateDomain"))">
                                <input type="text" name="forwardUrl" value="\(domain.forwardUrl)">
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
                    <th>
                        <td>Name</td><td>Value</td><td>Description</td>
                    </th>
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
                    <th><td>Address</td><td>Action</td><td></td></th>
            """
            
            domain.blacklist.list.forEach { (address, action) in
                
                let row = """
                    <tr>
                        <td>\(address)</td>
                        <td>
                            <form method="post" action="/\(domain.webroot)/command/UpdateBlacklist">
                                <input type="radio" name="\(address)" value="close" checked="\(action == .closeConnection)">
                                <p> Close Connection, <p>
                                <input type="radio" name="\(address)" value="503" checked="\(action == .send503ServiceUnavailable)">
                                <p> 503 Service Unavailable, <p>
                                <input type="radio" name="\(address)" value="401" checked="\(action == .send401Unauthorized)">
                                <p> 401 Unauthorized </p>
                                <input type="submit" title="Update">
                            </form>
                        </td>
                        <td>
                            <form method="post" action="/\(domain.webroot)/command/RemoveFromBlacklist">
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
                <form method="post" action="/\(domain.webroot)/command/AddToBlacklist">
                    <div>
                        <p>Address:</p>
                        <input type="text" name="newEntry", value="">
                    </div>
                    <div>
                        <input type="radio" name="action" value="close" checked="true"><p> Close Connection</p><br>
                        <input type="radio" name="action" value="503" checked="false"><p> 503 Services Unavailable</p><br>
                        <input type="radio" name="action" value="401" checked="false"><p> 401 Unauhorized</p><br>
                    </div>
                    <div>
                        <input type="submit" value="Add to Blacklist">
                    </div>
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
            for service in domain.serviceNames {
                tableRows.append(TableRow(rowIndex: index, name: service, usedByDomain: true))
                index += 1
            }
            
            OUTER: for service in services.registered {
                for row in tableRows {
                    if row.name == service.key { continue OUTER }
                }
                tableRows.append(TableRow(rowIndex: tableRows.count, name: service.key, usedByDomain: false))
            }
            
            
            // Create the table
            
            let hidden = Input.hidden(name: "DomainName", value: domain.name)
            var table = Table(klass: ["domain-service-table"], columnTitles: "Index", "Seq.", "Service Name", "Used")
            
            for row in tableRows {
                
                let seqName = "seqName\(row.rowIndex)"
                let nameName = "nameName\(row.rowIndex)"
                let usedName = "usedName\(row.rowIndex)"
                
                let serviceNameHidden = Input.hidden(name: nameName, value: row.name)
                let sequenceEntry = Input.text(klass: ["seq-column"], name: seqName, value: row.rowIndex.description)
                var serviceName = Input.text(klass: ["name-column"], name: nameName, value: row.name)
                serviceName.disabled = true
                let usedCheckbox = Input.checkbox(klass: ["used-column"], name: usedName, value: usedName, checked: row.usedByDomain)
                
                table.appendRow(Td(row.rowIndex.description), Td(sequenceEntry), Td(serviceName, serviceNameHidden), Td(usedCheckbox))
            }
            
            let submitButton = Input.submit(klass: "service-submit-form", name: "Submit", title: "Update Services")
            let form = Form(method: .post, action: "/serveradmin/sfcommand/UpdateDomainServices", hidden, table, submitButton)

            return form.html
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
    
    guard urlComponents.count > 0 && urlComponents.count <= 2 else { return .next }
    
    
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
    
    if urlComponents.count == 2 {
        switch urlComponents[1] {
        default:
            Log.atError?.log("")
            break
        }
    }
    
    
    // Return the domain admin page again
    
    domainAdminPage()
    return .next
}
    

