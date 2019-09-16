// =====================================================================================================================
//
//  File:       Service.SF.ServerAdmin.swift
//  Project:    Swiftfire
//
//  Version:    1.2.1
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.2.1 - Fixed bug that failed to update the root directory for the sfadmin
//         Added more debug entries as well as a couple of notification logentries
// 1.2.0 - Added admin account creation and removal
//       - Added creation of domain admin
// 1.1.0 - Changed server blacklist location
// 1.0.0 - Raised to v1.0.0, Removed old change log
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Intercepts access to the URL path: /serveradmin and redirects them to the adminSiteRoot. In effect making the server
// admin website available under any domain that has this service installed.
//
// To install this service, insert it after GetSession and DecodePostFormUrlEncoded but before GetResourcePathFromUrl.
//
//
// Input:
// ------
//
// request.url: Analyzed for "serveradmin" domain access.
// response.code: If set, skips this service.
// info[.sessionKey]: The active session.
//
//
// Output:
// -------
//
// response: Only if the request URL starts with "serveradmin".
//
//
// Return:
// -------
//
// .next
//
// =====================================================================================================================

import Foundation

import SwifterLog
import SwifterSockets
import Http
import Core
import Services


// These identifiers are the glue between admin creation/login pages and the code in this function.

private let SERVER_ADMIN_CREATE_ACCOUNT_NAME = "ServerAdminCreateAccountName"
private let SERVER_ADMIN_CREATE_ACCOUNT_PWD1 = "ServerAdminCreateAccountPwd1"
private let SERVER_ADMIN_CREATE_ACCOUNT_PWD2 = "ServerAdminCreateAccountPwd2"
private let SERVER_ADMIN_CREATE_ACCOUNT_ROOT = "ServerAdminCreateAccountRoot"

private let SERVER_ADMIN_LOGIN_NAME = "ServerAdminLoginName"
private let SERVER_ADMIN_LOGIN_PWD  = "ServerAdminLoginPwd"


/// Intercepts access to the URL path: /serveradmin and redirects them to the adminSiteRoot. In effect making the server
/// admin website available under any domain that has this service installed.
///
/// - Note: For a full description of all effects of this operation see the file: Service.ServerAdmin.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next

func service_serverAdmin(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    
    
    func createAdminAccountPage(name: String, nameColor: String, pwdColor: String, rootColor: String) {
        
        let html: String = """
            <!DOCTYPE html>
            <html>
               <head>
                  <title>Swiftfire Admin Setup</title>
               </head>
               <body>
                  <div>
                     <form action="/serveradmin" method="post">
                        <div>
                           <h3>Server Admin Setup</h3>
                           <p style="margin-bottom:0px;color:\(nameColor);">Admin:</p>
                           <input type="text" name="\(SERVER_ADMIN_CREATE_ACCOUNT_NAME)" value="\(name)"><br>
                           <p style="margin-bottom:0px;color:\(pwdColor);">Password:</p>
                           <input type="password" name="\(SERVER_ADMIN_CREATE_ACCOUNT_PWD1)" value=""><br>
                           <p style="margin-bottom:0px;color:\(pwdColor);">Repeat:</p>
                           <input type="password" name="\(SERVER_ADMIN_CREATE_ACCOUNT_PWD2)" value=""><br>
                           <p style="margin-bottom:0px;color:\(rootColor);">Root directory for the server admin site:</p>
                           <input type="text" name="\(SERVER_ADMIN_CREATE_ACCOUNT_ROOT)" value="" style="min-width:300px;"><br><br>
                           <input type="submit" value="Submit">
                         </div>
                      </form>
                  </div>
               </body>
            </html>
        """
        
        response.code = Response.Code._200_OK
        response.version = Version.http1_1
        response.contentType = mimeTypeHtml
        response.body = html.data(using: String.Encoding.utf8)
        
        Log.atDebug?.log("Returned Admin Account Creation page")
    }
    
    func loginAdminAccountPage() {
        
        // If there is a custom login page, use that instead of the default.
        
        let rootPath = serverParameters.adminSiteRoot.value
        let loginUrl = ((rootPath as NSString).appendingPathComponent("pages") as NSString).appendingPathComponent("/login.sf.html")

        if case let .exists(path: path) = connection.filemanager.readableResourceFileExists(at: loginUrl, for: domain) {
            
            Log.atDebug?.log("A login page exists, using file: \(path)")
            
            switch SFDocument.factory(path: path, filemanager: connection.filemanager) {
                
            case .error(let message):
                
                Log.atError?.log(message)
                
                response.code = Response.Code._500_InternalServerError
                
            case .success(let doc):
                
                var environment = Functions.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
                
                response.body = doc.getContent(with: &environment)
                response.code = Response.Code._200_OK
                response.contentType = mimeTypeHtml
            }
            
        } else {
            
            Log.atError?.log("No (readable) login.sf.html file found in the serveradmin-root-directory/pages")

            response.code = Response.Code._404_NotFound
        }
    }

    func adminStatusPage(message: String? = nil) {
        
        var rootColor = "black"
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: serverParameters.adminSiteRoot.value, isDirectory: &isDir) {
            if isDir.boolValue {
                rootColor = "red"
            }
        }
        
        let message = message ?? "Set root directory for server admin site:"
        
        let html: String = """
            <!DOCTYPE html>
            <html>
               <head>
                  <title>Swiftfire Status</title>
               </head>
               <body>
                  <div>
                     <h3>Swiftfire Status at \(dateFormatter.string(from: Date()))</h3>
                     <p style="margin-bottom:0px;">Swiftfire Version  : \(serverTelemetry.serverVersion.value)</p>
                     <p style="margin-bottom:0px;">HTTP Server Status : \(serverTelemetry.httpServerStatus.value)</p>
                     <p style="margin-bottom:0px;">HTTPS Server Status: \(serverTelemetry.httpsServerStatus.value)</p>
                     <form action="/serveradmin/sfcommand/SetRoot" method="post">
                        <div>
                           <p style="margin-bottom:0px;color:\(rootColor);">\(message)</p>
                           <input type="text" name="\(SERVER_ADMIN_CREATE_ACCOUNT_ROOT)" value="\(serverParameters.adminSiteRoot.value)">
                           <input type="submit" value="Submit/Visit">
                         </div>
                      </form>
                  </div>
               </body>
            </html>
            """
        
        response.code = Response.Code._200_OK
        response.version = Version.http1_1
        response.contentType = mimeTypeHtml
        response.body = html.data(using: String.Encoding.utf8)
    }
    
    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // Only service the serverAdminPseudoDomain
    
    guard domain === serverAdminDomain else {
        Log.atDebug?.log("Not a Server Domain")
        return .next
    }
    
    
    // Prepare the url
    
    guard let urlstr = request.url else {
        Log.atError?.log("No request URL found", id: connection.logId)
        response.code = Response.Code._400_BadRequest
        return .next
    }
    
    Log.atDebug?.log("Raw URL request: \(urlstr)")
    
    
    // If the url contains '/serveradmin' then remove that part.
    
    var pathComponents = (urlstr as NSString).pathComponents

    if  pathComponents.count > 1,
        pathComponents[0].caseInsensitiveCompare("/") == ComparisonResult.orderedSame,
        pathComponents[1].caseInsensitiveCompare("serveradmin") == ComparisonResult.orderedSame {
        
        pathComponents.removeFirst()
        pathComponents.removeFirst()
    }

    
    // Create the relative resource path.
    
    var relPath = pathComponents.joined(separator: "/")

    Log.atDebug?.log("Removed serveradmin from the requested url: \(relPath)")
    
    
    // ======================================================================
    // There must be a session, without an active session nothing is possible
    // ======================================================================
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atCritical?.log("No session found, this service should come AFTER the 'getSession' service.", id: connection.logId)
        domain.telemetry.nof500.increment()
        response.code = Response.Code._500_InternalServerError
        return .next
    }

    
    // =============================================================================
    // If there area no admin accounts, only accept the creation of an admin account
    // =============================================================================

    if serverAdminDomain.accounts.isEmpty {
        
        Log.atDebug?.log("No admin account found")
        
        guard let postInfo = info[.postInfoKey] as? PostInfo else {
            createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
            return .next
        }
        
        guard  let name = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_NAME],
            let pwd1 = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_PWD1],
            let pwd2 = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_PWD2],
            let root = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_ROOT] else {

                // One or more account creation details missing
                
                Log.atDebug?.log("Admin account creation credential(s) missing", id: connection.logId)
                createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
                return .next
        }

        
        // Check the credentials
        
        Log.atDebug?.log("Found admin account creation credentials for: \(name)", id: connection.logId)
        
        guard !name.isEmpty, name.utf8.count < 30 else {
            createAdminAccountPage(name: "", nameColor: "red", pwdColor: "black", rootColor: "black")
            return .next
        }
        
        guard !pwd1.isEmpty else {
            createAdminAccountPage(name: name, nameColor: "black", pwdColor: "red", rootColor: "black")
            return .next
        }
        
        guard pwd2 == pwd1 else {
            createAdminAccountPage(name: name, nameColor: "black", pwdColor: "red", rootColor: "black")
            return .next
        }
        
        guard !root.isEmpty else {
            createAdminAccountPage(name: name, nameColor: "black", pwdColor: "black", rootColor: "red")
            return .next
        }
        
        
        // There root must be a directory, and an index file must exist
        
        serverParameters.adminSiteRoot.value = root
        guard adminSiteRootIsValid(connection.filemanager) else {
            createAdminAccountPage(name: name, nameColor: "black", pwdColor: "black", rootColor: "red")
            return .next
        }
        
        
        // Credentials are considered valid, create account
        
        guard let account = serverAdminDomain.accounts.newAccount(name: name, password: pwd1) else {
            Log.atCritical?.log("Failed to create admin account for: \(name)", id: connection.logId)
            response.code = Response.Code._500_InternalServerError
            return .next
        }
        
        Log.atNotice?.log("Created admin account for: '\(name)'", id: connection.logId)
        
        serverAdminDomain.webroot = root
        
        serverParameters.store()
        
        session[.accountKey] = account
        
        relPath = "/"
        
        /*** Fallthrough ***/
        
    } else {

        Log.atDebug?.log("Admin account present")
        
        // ==============================================================
        // If login information is available, then login the server admin
        // ==============================================================
        
        if let postInfo = info[.postInfoKey] as? PostInfo,
            let name = postInfo[SERVER_ADMIN_LOGIN_NAME],
            let pwd = postInfo[SERVER_ADMIN_LOGIN_PWD] {
            
            Log.atDebug?.log("Found login information for admin \(name)")
            
            
            // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt
            
            if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
                let now = Date().javaDate
                if now - previousAttempt < 2000 {
                    session[.lastFailedLoginAttemptKey] = now
                    loginAdminAccountPage()
                    return .next
                }
            }
            
            
            // Get the account for the login data
            
            guard let account = serverAdminDomain.accounts.getAccount(for: name, using: pwd) else {
                
                // The login attempt failed, no account found.
                
                Log.atNotice?.log("Admin login failed for \(name)", id: connection.logId)
                
                
                // Failed login, reset possible account
                
                session[.accountKey] = nil
                
                
                // Set the timestamp for the failed attempt
                
                session[.lastFailedLoginAttemptKey] = Date().javaDate
                
                
                loginAdminAccountPage()
                
                return .next
            }

            
            Log.atNotice?.log("Admin \(name) logged in, \(account.uuid)", id: connection.logId)
                
                
            // Associate the account with the session. This allows access for subsequent admin pages.
                
            session[.accountKey] = account
                
                
            // If an admin tried to access an protected page while not logged-in, then the URL of that page is stored in the session.
            // Restore the original URL such that the admin is taken to the page he wanted to access.
                
            if let path = session[.preLoginUrlKey] as? String {
                Log.atDebug?.log("Replacing relPath value \(relPath) with \(path)")
                relPath = path
            } else {
                Log.atDebug?.log("Replacing relPath value \(relPath) with \"\\\"")
                relPath = "/"
            }
    
                
            // Remove the previous access url from the session.
                
            session[.preLoginUrlKey] = nil
                
                
            /*** Fallthrough ***/
        }
    }
    
    
    // Special case: The root site for the serveradmin must be updated
    
    if relPath.contains("sfcommand/SetRoot") {
        
        Log.atDebug?.log("Found set root command")
        
        if let postInfo = info[.postInfoKey] as? PostInfo {
            if let newRootPath = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_ROOT], !newRootPath.isEmpty {
        
                Log.atDebug?.log("Setting root path to: \(newRootPath)")
                
                serverParameters.adminSiteRoot.value = newRootPath
                serverAdminDomain.webroot = newRootPath
                
                serverParameters.store()
                
                relPath = "/index.sf.html"
            }
        }
    }
    
    
    // Catch the possibility where the admin has manually changed the configuration files and made an error
    
    if !adminSiteRootIsValid(connection.filemanager) {
        
        Log.atError?.log("Admin site root is invalid at: \(serverParameters.adminSiteRoot.value)")
        
        adminStatusPage()
        return .next
    }

    
    // ======================================
    // Find the page which has to be returned
    // ======================================

    let testPath = (serverAdminDomain.webroot as NSString).appendingPathComponent(relPath)
    var absPath: String = ""
    if !testPath.contains("sfcommand") {
        
        switch connection.filemanager.readableResourceFileExists(at: testPath, for: serverAdminDomain) {
            
        case let .exists(path: path):
            absPath = path
            
        case .cannotBeRead:
            adminStatusPage(message: "Requested page at \(testPath) is not readable")
            return .next
            
        case .doesNotExist:
            adminStatusPage(message: "Requested page at \(testPath) does not exist")
            return .next
            
        case .isDirectoryWithoutIndex:
            adminStatusPage(message: "Directory without index page at \(testPath)")
            return .next
        }
    }
    
    Log.atDebug?.log("relPath \(relPath) resolved to absPath \(absPath)")
    
    
    // ===============================================================
    // An administrator has to be logged in for html, htm or php pages
    // ===============================================================
    
    // Note: Other pages are allowed in order to facilitate the formatting and layout of the login page
    
    let fileExtension = (absPath as NSString).pathExtension.lowercased()
    if (fileExtension == "htm" || fileExtension == "html" || fileExtension == "php" || relPath.contains("sfcommand")) {
        
        Log.atDebug?.log("A protected page is requested")
        
        
        // An admin must be logged in
        
        guard let account = session[.accountKey] as? Account, serverAdminDomain.accounts.contains(account.uuid) else {
            
            Log.atDebug?.log("No admin logged in")
            
            
            // Save the current request url, it will be used when the admin logs in (unless the login page was requested)
            
            if (session.info[.preLoginUrlKey] == nil) && !relPath.contains("login") {
                Log.atDebug?.log("Setting the session preLoginUrl to \(relPath)")
                session.info[.preLoginUrlKey] = relPath
            }
            
            loginAdminAccountPage()
            return .next
        }
        
        Log.atDebug?.log("Admin \(account.name) logged in")
    }

    
    // =================================================================================================================
    // Special case: execute server commands
    // =================================================================================================================

    if pathComponents.count >= 2 && pathComponents[0] == "sfcommand" {
        
        pathComponents.removeFirst()
        var postInfo = info[.postInfoKey] as? PostInfo
        
        switch executeSfCommand(pathComponents, &postInfo, session, &info, &response) {
        
        case .next: return .next
            
        case .newPath(let path):

            relPath = path
            let testPath = (serverAdminDomain.webroot as NSString).appendingPathComponent(relPath)
            
            switch connection.filemanager.readableResourceFileExists(at: testPath, for: serverAdminDomain) {
                
            case let .exists(path: path):
                absPath = path
                
            case .cannotBeRead:
                adminStatusPage(message: "Requested page at \(testPath) is not readable")
                return .next
                
            case .doesNotExist:
                adminStatusPage(message: "Requested page at \(testPath) does not exist")
                return .next
                
            case .isDirectoryWithoutIndex:
                adminStatusPage(message: "Directory without index page at \(testPath)")
                return .next
            }

        case .nop: break
        }
    }
    
    
    // =================================================================================================================
    // Fetch the requested resource
    // =================================================================================================================
    
    // If the file can contain function calls, then process it. Otherwise return the file as read.
    
    if (absPath as NSString).lastPathComponent.contains(".sf.") {
        
        switch SFDocument.factory(path: absPath, filemanager: connection.filemanager) {
            
        case .error(let message):
            
            Log.atError?.log(message, id: connection.logId)

            response.code = Response.Code._500_InternalServerError
            
            return .next
            
            
        case .success(let doc):
            
            var environment = Functions.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
            
            response.body = doc.getContent(with: &environment)
            response.code = Response.Code._200_OK
            response.contentType = mimeType(forPath: absPath) ?? mimeTypeHtml
        }
        
        
    } else {
        
        guard let data = connection.filemanager.contents(atPath: absPath) else {
            
            Log.atError?.log("Reading contents of file failed (but file is reported readable), resource: \(absPath)", id: connection.logId)

            response.code = Response.Code._500_InternalServerError

            return .next
        }
        
        response.body = data
        response.code = Response.Code._200_OK
        response.contentType = mimeType(forPath: absPath) ?? mimeTypeDefault
    }
    
    
    // =============================================================================================================
    // Create the http response
    // =============================================================================================================
    
    
    // Telemetry update
    
    domain.telemetry.nof200.increment()
    
    
    // Response
    
    response.code = Response.Code._200_OK
    response.contentType = mimeType(forPath: absPath) ?? mimeTypeDefault
    
    return .next
}

fileprivate func adminSiteRootIsValid(_ filemanager: FileManager) -> Bool {

    let path = serverParameters.adminSiteRoot.value
    let url = URL(fileURLWithPath: path)
    
    var isDirectory: ObjCBool = false
    
    if !filemanager.fileExists(atPath: path, isDirectory: &isDirectory) { return false }
        
        
    // There is something, it must be a directory, check for index.html or index.htm
        
    if !isDirectory.boolValue { return false }
            
            
    // Check for an index file
    
    for name in ["index.html", "index.sf.html", "index.htm", "index.sf.htm"] {
        
        let turl = url.appendingPathComponent(name)
                
        if filemanager.isReadableFile(atPath: turl.path) { return true }
    }

    return false
}

fileprivate enum CommandExecutionResult {
    case next
    case newPath(String)
    case nop
}

fileprivate func executeSfCommand(_ pathComponents: Array<String>, _ postInfo: inout PostInfo?, _ session: Session, _ info: inout Services.Info, _ response: inout Response) -> CommandExecutionResult {
    
    guard let commandName = pathComponents.first else {
        Log.atError?.log("No command name found")
        return .nop
    }

    Log.atDebug?.log("Executing command: \(commandName)")

    switch commandName {
    case "SetRoot": executeSetRoot(postInfo); return .newPath("")
    case "SetParameter": executeSetParameter(postInfo); return .newPath("/pages/parameters.sf.html")
    case "Restart": executeRestart(); return .newPath("/pages/restart.sf.html")
    case "Quit": return .newPath("/pages/quit.sf.html")
    case "CancelQuit": return .newPath("")
    case "ConfirmedQuit": executeQuitSwiftfire(); return .newPath("/pages/bye.sf.html")
    case "UpdateDomain": executeUpdateDomain(&postInfo); return .newPath("/pages/domain.sf.html")
    case "UpdateDomainServices": executeUpdateDomainServices(&postInfo); return .newPath("/pages/domain.sf.html")
    case "DeleteDomain": executeDeleteDomain(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "CreateDomain": executeCreateDomain(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "CreateAdmin": executeCreateAdmin(postInfo); return .newPath("/pages/admin-management.sf.html")
    case "CreateAlias": executeCreateAlias(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "DeleteAlias": executeDeleteAlias(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "DeleteAccount": executeDeleteAccount(postInfo); return .newPath("/pages/admin-management.sf.html")
    case "ConfirmDeleteAccount": return executeConfirmDeleteAccount(postInfo)
    case "SetNewPassword": executeSetNewPassword(postInfo); return .newPath("/pages/admin-management.sf.html")
    case "UpdateBlacklist": executeUpdateBlacklist(&postInfo); return .newPath("/pages/blacklist.sf.html")
    case "AddToBlacklist": executeAddToBlacklist(&postInfo); return .newPath("/pages/blacklist.sf.html")
    case "RemoveFromBlacklist": executeRemoveFromBlacklist(&postInfo); return .newPath("/pages/blacklist.sf.html")
    case "UpdateDomainBlacklist": executeUpdateDomainBlacklist(&postInfo); return .newPath("/pages/domain.sf.html")
    case "AddToDomainBlacklist": executeAddToDomainBlacklist(&postInfo); return .newPath("/pages/domain.sf.html")
    case "RemoveFromDomainBlacklist": executeRemoveFromDomainBlacklist(&postInfo); return .newPath("/pages/domain.sf.html")
    case "SetDomainAdminPassword": executeSetDomainAdminPassword(postInfo); return .newPath("/pages/domain.sf.html")
    case "Logout": return executeLogout(session);
        
    default:
        Log.atError?.log("Unknown sfcommand: \(commandName)")
        return .nop
    }
}

fileprivate func executeSetRoot(_ postInfo: PostInfo?) {
    
    guard let root = postInfo?[SERVER_ADMIN_CREATE_ACCOUNT_ROOT] else {
        Log.atDebug?.log("Missing key for the admin server set root command")
        return
    }
    
    Log.atNotice?.log("Set admin root directory from: \(serverParameters.adminSiteRoot.value)")

    serverParameters.adminSiteRoot.value = root
    
    serverParameters.store()
    
    Log.atNotice?.log("Set admin root directory to: \(root)")
}

fileprivate func executeSetParameter(_ postInfo: PostInfo?) {
    
    guard let postInfo = postInfo else {
        Log.atError?.log("Missing postInfo")
        return
    }
    
    OUTER: for (key, value) in postInfo {
    
        for p in serverParameters.all {
        
            if p.name == key {
                
                Log.atNotice?.log("Setting parameter '\(key)' from '\(p.stringValue)'")
                
                _ = p.setValue(value)
                
                serverParameters.store()
                
                Log.atNotice?.log("Setting parameter '\(key)' to '\(value)'")
                
                continue OUTER
            }
        }
        
        Log.atError?.log("Unknown parameter name \(key)")
    }
}

fileprivate func executeUpdateBlacklist(_ postInfo: inout PostInfo?) {
    
    guard let address = postInfo?["Address"] else {
        Log.atError?.log("Missing address")
        return
    }
    
    guard let action = postInfo?["Action"] else {
        Log.atError?.log("Missing action")
        return
    }

    let newAction: Blacklist.Action = {
        switch action {
            case "close": return .closeConnection
            case "503": return .send503ServiceUnavailable
            case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    
    guard let oldAction = serverAdminDomain.blacklist.action(for: address) else {
        Log.atError?.log("Address \(address) not found in server blacklist")
        return
    }

    Log.atNotice?.log("Changed the action from \(oldAction) for address \(address) in server blacklist")

    serverAdminDomain.blacklist.update(action: newAction, for: address)
    
    serverAdminDomain.blacklist.store(to: Urls.domainBlacklistFile(for: "serveradmin"))
    
    Log.atNotice?.log("Changed the action to \(action) for address \(address) in server blacklist")
}

fileprivate func executeAddToBlacklist(_ postInfo: inout PostInfo?) {
    
    guard
        let address = postInfo?["NewEntry"],
        isValidIpAddress(address)
    else {
        Log.atError?.log("Unknown address for key NewEntry")
        return
    }

    guard let action = postInfo?["Action"] else {
        Log.atError?.log("Unknown action for key Action")
        return
    }

    let newAction: Blacklist.Action = {
        switch action {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    
    if serverAdminDomain.blacklist.action(for: address) != nil {
        Log.atError?.log("Address \(address) already exists")
        return
    }
    
    serverAdminDomain.blacklist.add(address, action: newAction)
    
    serverAdminDomain.blacklist.store(to: Urls.domainBlacklistFile(for: "serveradmin"))
    
    Log.atNotice?.log("Added address \(address) to server blacklist")
}

fileprivate func executeRemoveFromBlacklist(_ postInfo: inout PostInfo?) {
    
    guard let address = postInfo?["Address"] else {
        Log.atError?.log("Missing address for key Address")
        return
    }
    
    guard let action = serverAdminDomain.blacklist.action(for: address) else {
        Log.atError?.log("Address does not exist in serveradmin domain blacklist")
        return
    }
    
    serverAdminDomain.blacklist.remove(address)
    
    Log.atNotice?.log("Removed address \(address) with action \(action) from server blacklist")
}

fileprivate func executeUpdateDomainBlacklist(_ postInfo: inout PostInfo?) {
    
    guard
        let name = postInfo?["DomainName"],
        let domain = domains.domain(for: name)
        else {
            Log.atError?.log("Missing or wrong domain name")
            return
    }
    
    guard let address = postInfo?["Address"] else {
        Log.atError?.log("Missing address")
        return
    }
    
    guard let action = postInfo?["Action"] else {
        Log.atError?.log("Missing action")
        return
    }

    let newAction: Blacklist.Action = {
        switch action {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    
    guard let oldAction = domain.blacklist.action(for: address) else {
        Log.atError?.log("Address \(address) not present in blacklist of domain \(domain.name)")
        return
    }
    
    Log.atNotice?.log("Updated action of address \(address) from \(oldAction) in domain \(domain.name) blacklist")
    
    domain.blacklist.update(action: newAction, for: address)
    
    Log.atNotice?.log("Updated action of address \(address) to \(action) in domain \(domain.name) blacklist")
}

fileprivate func executeAddToDomainBlacklist(_ postInfo: inout PostInfo?) {
    
    guard
        let name = postInfo?["DomainName"],
        let domain = domains.domain(for: name)
        else {
            Log.atError?.log("Missing domain name")
            return
    }
    
    guard
        let address = postInfo?["NewEntry"],
        isValidIpAddress(address)
        else {
        Log.atError?.log("No 'NewEntry' key found in postInfo dictionary")
        return
    }
    
    guard let action = postInfo?["Action"] else {
        Log.atError?.log("No 'Action' key found in postInfo dictionary")
        return
    }
    
    let newAction: Blacklist.Action = {
        switch action {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    
    if domain.blacklist.action(for: address) != nil {
        Log.atError?.log("Address \(address) is already present in blacklist of domain \(domain.name)")
        return
    }

    domain.blacklist.add(address, action: newAction)
    
    Log.atNotice?.log("Added address \(address) with action \(action) to domain \(domain.name) blacklist")
}

fileprivate func executeRemoveFromDomainBlacklist(_ postInfo: inout PostInfo?) {
    
    guard
        let name = postInfo?["DomainName"],
        let domain = domains.domain(for: name)
        else {
            Log.atError?.log("Missing domain name")
            return
    }
    
    guard let address = postInfo?["Address"] else {
        Log.atError?.log("Missing address for key Address")
        return
    }
    
    guard let oldAction = domain.blacklist.action(for: address) else {
        Log.atError?.log("Address \(address) not present in blacklist of domain \(domain.name)")
        return
    }

    domain.blacklist.remove(address)
    
    Log.atNotice?.log("Removed address \(address) with action \(oldAction) from domain \(domain.name) blacklist")
}


/// Update a parameter in a domain.

fileprivate func executeUpdateDomain(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"] else {
        Log.atError?.log("Missing postInfo")
        return
    }
    
    _ = postInfo!.removeValue(forKey: "DomainName")
    
    guard let domain = domains.domain(for: name) else {
        Log.atError?.log("Missing DomainName in postInfo")
        return
    }
    
    guard let (key, value) = postInfo?.popFirst() else {
        Log.atError?.log("Missing parameter name and value in postInfo")
        return
    }
    
    postInfo!["DomainName"] = name
    
    switch key {
    case "root":
        
        Log.atNotice?.log("Old value for domain \(domain.name) webroot = \(domain.webroot)")
        
        domain.webroot = value
    
        Log.atNotice?.log("New value for domain \(domain.name) webroot = \(domain.webroot)")
        
        
    case "forewardurl":

        Log.atNotice?.log("Old value for domain \(domain.name) forewardUrl = \(domain.forwardUrl)")

        domain.forwardUrl = value

        Log.atNotice?.log("New value for domain \(domain.name) forewardUrl = \(domain.forwardUrl)")

        
    case "enabled":
        
        Log.atNotice?.log("Old value for domain \(domain.name) enabled = \(domain.enabled)")

        domain.enabled = Bool(lettersOrDigits: value) ?? domain.enabled
    
        Log.atNotice?.log("New value for domain \(domain.name) enabled = \(domain.enabled)")

    
    case "accesslogenabled":
        
        Log.atNotice?.log("Old value for domain \(domain.name) accessLogEnabled = \(domain.accessLogEnabled)")

        domain.accessLogEnabled = Bool(lettersOrDigits: value) ?? domain.accessLogEnabled

        Log.atNotice?.log("New value for domain \(domain.name) accessLogEnabled = \(domain.accessLogEnabled)")

        
    case "404logenabled":
        
        Log.atNotice?.log("Old value for domain \(domain.name) 404log-enabled = \(domain.four04LogEnabled)")

        domain.four04LogEnabled = Bool(lettersOrDigits: value) ?? domain.four04LogEnabled

        Log.atNotice?.log("New value for domain \(domain.name) 404log-enabled = \(domain.four04LogEnabled)")

        
    case "sessionlogenabled":
        
        Log.atNotice?.log("Old value for domain \(domain.name) sessionLogEnabled = \(domain.sessionLogEnabled)")

        domain.sessionLogEnabled = Bool(lettersOrDigits: value) ?? domain.sessionLogEnabled
    
        Log.atNotice?.log("New value for domain \(domain.name) sessionLogEnabled = \(domain.sessionLogEnabled)")

    
    case "phppath":
        
        Log.atNotice?.log("Old value for domain \(domain.name) phpPath = \(domain.phpPath?.path ?? "nil")")

        domain.phpPath = nil
        if FileManager.default.isExecutableFile(atPath: value) {
            let url = URL(fileURLWithPath: value)
            if url.lastPathComponent == "php" {
                domain.phpPath = URL(fileURLWithPath: value)
            }
        }
        
        Log.atNotice?.log("New value for domain \(domain.name) phpPath = \(domain.phpPath?.path ?? "nil")")

        
    case "phpoptions":
        
        if domain.phpPath != nil {
            
            Log.atNotice?.log("Old value for domain \(domain.name) phpOptions = \(domain.phpOptions ?? "nil")")

            domain.phpOptions = value

            Log.atNotice?.log("New value for domain \(domain.name) phpOptions = \(domain.phpOptions ?? "nil")")
        }
        
        
    case "phpmapindex":
        
        if domain.phpPath != nil {
            
            Log.atNotice?.log("Old value for domain \(domain.name) phpMapIndex = \(domain.phpMapIndex)")

            domain.phpMapIndex = Bool(lettersOrDigits: value) ?? domain.phpMapIndex

            Log.atNotice?.log("New value for domain \(domain.name) phpMapIndex = \(domain.phpMapIndex)")
        }
        
        
    case "phpmapall":
        
        if domain.phpPath != nil {
            
            Log.atNotice?.log("Old value for domain \(domain.name) phpMapAll = \(domain.phpMapAll)")
            Log.atNotice?.log("Old value for domain \(domain.name) phpMapIndex = \(domain.phpMapIndex)")

            if Bool(lettersOrDigits: value) ?? domain.phpMapAll {
                domain.phpMapAll = true
                domain.phpMapIndex = true
            } else {
                domain.phpMapAll = false
            }

            Log.atNotice?.log("New value for domain \(domain.name) phpMapAll = \(domain.phpMapAll)")
            Log.atNotice?.log("New value for domain \(domain.name) phpMapIndex = \(domain.phpMapIndex)")
        }
        
        
    case "phptimeout":

        if domain.phpPath != nil {
            
            Log.atNotice?.log("Old value for domain \(domain.name) phpTimeout = \(domain.phpTimeout)")

            domain.phpTimeout = Int(value) ?? domain.phpTimeout

            Log.atNotice?.log("New value for domain \(domain.name) phpTimeout = \(domain.phpTimeout)")
        }

        
    case "sfresources":
        
        Log.atNotice?.log("Old value for domain \(domain.name) sfresources = \(domain.sfresources)")

        domain.sfresources = value

        Log.atNotice?.log("New value for domain \(domain.name) sfresources = \(domain.sfresources)")

        
    case "sessiontimeout":
        
        Log.atNotice?.log("Old value for domain \(domain.name) sessionTimeout = \(domain.sessionTimeout)")

        domain.sessionTimeout = Int(value) ?? domain.sessionTimeout
    
        Log.atNotice?.log("New value for domain \(domain.name) sessionTimeout = \(domain.sessionTimeout)")

        
    default:
        Log.atError?.log("Unknown key '\(key)' with value '\(value)'")
    }
    
    domain.storeSetup()
}


/// Update the sequence of services in a domain.

fileprivate func executeUpdateDomainServices(_ postInfo: inout PostInfo?) {

    guard let domainName = postInfo?["DomainName"],
          let domain = domains.domain(for: domainName) else { return }
    
    Log.atNotice?.log("Pre-update services for domain \(domain.name):\n\(domain.serviceNames)")
    
    struct ServiceItem {
        let index: Int
        let name: String
    }
    
    var serviceArr: Array<ServiceItem> = []
    
    var index = 0
    
    while let _ = postInfo?["seqName\(index)"] {
        
        if let _ = postInfo?["usedName\(index)"] {

            if  let newIndexStr = postInfo?["seqName\(index)"],
                let newIndex = Int(newIndexStr) {
            
                if let newName = postInfo?["nameName\(index)"] {
                    serviceArr.append(ServiceItem(index: newIndex, name: newName))
                } else {
                    Log.atError?.log("Missing nameName for index \(index)")
                }
        
            } else {
                Log.atError?.log("Missing seqName for index \(index)")
            }
        }
        index += 1
    }
    
    serviceArr.sort(by: { $0.index < $1.index })
        
    domain.serviceNames = serviceArr.map({ $0.name }) //ArrayOfStrings(serviceNames)
    
    domain.rebuildServices()
    
    domain.serviceNames.store(to: Urls.domainServiceNamesFile(for: domain.name))
    
    Log.atNotice?.log("Post-update services for domain \(domain.name):\n\(domain.serviceNames)")
}


/// Deletes the domain.

fileprivate func executeDeleteDomain(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"] else {
        Log.atError?.log("Missing Domain in postInfo")
        return
    }
    
    guard domains.contains(name) else {
        Log.atError?.log("Domain '\(name)' does not exist")
        return
    }
    
    domains.remove(name)
    
    Log.atNotice?.log("Deleted domain '\(name)')")
}


/// Creates a new domain

fileprivate func executeCreateDomain(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"], !name.isEmpty else {
        Log.atError?.log("Missing DomainName in postInfo")
        return
    }
    
    guard !domains.contains(name) else {
        Log.atError?.log("Domain '\(name)' already exists")
        return
    }
    
    guard let adminId = postInfo?["ID"], !adminId.isEmpty else {
        Log.atError?.log("Missing Domain Admin ID in postInfo")
        return
    }
    
    guard let adminPwd = postInfo?["Password"], !adminPwd.isEmpty else {
        Log.atError?.log("Missing Domain Admin PWD in postInfo")
        return
    }

    if let domain = domains.createDomain(for: name) {
        domain.serviceNames = defaultServices
        if let account = domain.accounts.getAccount(for: adminId, using: adminPwd) {
            account.isAdmin = true
        } else {
            guard let account = domain.accounts.newAccount(name: adminId, password: adminPwd) else {
                domains.remove(name)
                Log.atError?.log("Could not create admin account")
                return
            }
            account.isAdmin = true
        }
        Log.atNotice?.log("Added new domain with \(domain))")
    } else {
        Log.atNotice?.log("Failed to create domain for \(name))")
    }
}


/// Creates a new alias

fileprivate func executeCreateAlias(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"] else {
        Log.atError?.log("Missing Domain in postInfo")
        return
    }

    guard let alias = postInfo?["Alias"], !alias.isEmpty else {
        Log.atError?.log("Missing Alias in postInfo")
        return
    }

    guard domains.contains(name) else {
        Log.atError?.log("Domain '\(name)' does not exist")
        return
    }

    domains.createAlias(alias, forDomainWithName: name)
    
    Log.atNotice?.log("Created new alias '\(alias)' for domain '\(name)'")
}


/// Remove an alias

fileprivate func executeDeleteAlias(_ postInfo: inout PostInfo?) {
    
    guard let alias = postInfo?["Alias"] else {
        Log.atError?.log("Missing Alias in postInfo")
        return
    }
    
    guard domains.contains(alias) else {
        Log.atError?.log("Alias '\(alias)' does not exist")
        return
    }
    
    domains.remove(alias)
    
    Log.atNotice?.log("Deleted alias '\(alias)'")
}


/// This queue is used to delay the execution of a command such that it is possible to return confirmation pages to the admin before Swiftfire initiates the command.

fileprivate let restartQueue = DispatchQueue(label: "Restart queue")


/// If the HTTP server is not running, it will start the HTTP server. If it is running it will be stopped first.

fileprivate func executeRestart() {
    
    Log.atNotice?.log()
    
    restartQueue.asyncAfter(deadline: DispatchTime.now() + 2) {
        
        restartHttpAndHttpsServers()
    }
}

fileprivate func executeQuitSwiftfire() {
    
    restartQueue.asyncAfter(deadline: DispatchTime.now() + 2) {
        
        httpServer?.stop()
        httpsServer?.stop()
    
        _ = Darwin.sleep(5)
    
        quitSwiftfire = true
    }
    
    Log.atNotice?.log()
}

fileprivate func executeLogout(_ session: Session) -> CommandExecutionResult {
    
    if let account = session[.accountKey] as? Account {
        Log.atNotice?.log("Serveradmin \(account.name) logged out")
    }
    
    session[.accountKey] = nil
    
    return .newPath("/pages/login.sf.html")
}

fileprivate func executeCreateAdmin(_ postInfo: PostInfo?) {
    
    guard let id = postInfo?["ID"] else {
        Log.atError?.log("No ID given")
        return
    }
    
    guard let password = postInfo?["Password"] else {
        Log.atError?.log("No password given")
        return
    }
    
    if serverAdminDomain.accounts.newAccount(name: id, password: password) == nil {
        Log.atCritical?.log("Failed to create admin account for: \(id)")
    }
    
    Log.atNotice?.log("Created new admin account with ID = \(id)")
}

fileprivate func executeConfirmDeleteAccount(_ postInfo: PostInfo?) -> CommandExecutionResult {
    
    guard (postInfo?["ID"]) != nil else {
        Log.atError?.log("No ID given")
        return .newPath("/pages/admin-management.sf.html")
    }
    
    return .newPath("/pages/admin-confirm-delete.sf.html")
}

fileprivate func executeDeleteAccount(_ postInfo: PostInfo?) {
    
    guard let name = postInfo?["ID"] else {
        Log.atError?.log("No ID given")
        return
    }

    guard serverAdminDomain.accounts.remove(name: name) else {
        Log.atError?.log("No account for name \(name) found")
        return
    }
    
    Log.atNotice?.log("Server Admin Account \(name) removed.")
}

fileprivate func executeSetNewPassword(_ postInfo: PostInfo?) {
    
    guard let name = postInfo?["ID"], !name.isEmpty else {
        Log.atError?.log("No ID given")
        return
    }

    guard let password = postInfo?["Password"], !password.isEmpty else {
        Log.atError?.log("No new password given for \(name)")
        return
    }
    
    guard let accountToBeChanged = serverAdminDomain.accounts.getAccountWithoutPassword(for: name) else {
        Log.atError?.log("No account found for: \(name)")
        return
    }
    
    if accountToBeChanged.updatePassword(password) {
        Log.atNotice?.log("Password was changed for: \(name)")
    } else {
        Log.atError?.log("Password could not be changed for: \(name)")
    }
}

fileprivate func executeSetDomainAdminPassword(_ postInfo: PostInfo?) {
    
    guard let domainName = postInfo?["Domain"], !domainName.isEmpty else {
        Log.atError?.log("No domain given")
        return
    }

    guard let adminName = postInfo?["ID"], !adminName.isEmpty else {
        Log.atError?.log("No ID given")
        return
    }

    guard let domain = domains.domain(for: domainName) else {
        Log.atError?.log("No domain known for \(domainName)")
        return
    }
    
    
    // Check if the account exists
    
    if let account = domain.accounts.getAccountWithoutPassword(for: adminName) {

        
        // If it is an admin account, then update the password
        
        if account.isAdmin {
            
            guard let newPassword = postInfo?["Password"], !newPassword.isEmpty else {
                Log.atError?.log("No password given")
                return
            }

            if account.updatePassword(newPassword) {
                Log.atNotice?.log("Updated the password for account \(account.name) in domain \(domain.name)")
            } else {
                Log.atError?.log("Could not update password for account \(account.name) in domain \(domain.name)")
            }
            
        } else {
            
            // Make this account an admin
            
            account.isAdmin = true
            
            Log.atNotice?.log("Added account \(account.name) in domain \(domain.name) to the domain admins")

            
            // If there is a password, then also update the password
            
            if let newPassword = postInfo?["Password"], !newPassword.isEmpty {
                
                if account.updatePassword(newPassword) {
                    Log.atNotice?.log("Updated the password for account \(account.name) in domain \(domain.name)")
                } else {
                    Log.atError?.log("Could not update password for account \(account.name) in domain \(domain.name)")
                }
            }
        }

    } else {
        
        // Create a new admin account if the password is also given
        
        if let newPassword = postInfo?["Password"], !newPassword.isEmpty {
            
            if let account = domain.accounts.newAccount(name: adminName, password: newPassword) {
                
                account.isAdmin = true

                Log.atNotice?.log("Created domain admin account for \(account.name) in domain \(domain.name)")

            } else {
                
                Log.atError?.log("Failed to create account for account \(adminName) in domain \(domain.name)")
            }

        } else {
            
            Log.atError?.log("Cannot create account for account \(adminName) in domain \(domain.name) without a password")
        }
    }
}
