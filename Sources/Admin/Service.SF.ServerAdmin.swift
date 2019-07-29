// =====================================================================================================================
//
//  File:       Service.SF.ServerAdmin.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
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


private var dateFormatter: DateFormatter = {
    let ltf = DateFormatter()
    ltf.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return ltf
}()


// These identifiers are the glue between admin creation/login pages and the code in this function.

private let SERVER_ADMIN_CREATE_ACCOUNT_NAME = "ServerAdminCreateAccountName"
private let SERVER_ADMIN_CREATE_ACCOUNT_PWD1 = "ServerAdminCreateAccountPwd1"
private let SERVER_ADMIN_CREATE_ACCOUNT_PWD2 = "ServerAdminCreateAccountPwd2"
private let SERVER_ADMIN_CREATE_ACCOUNT_ROOT = "ServerAdminCreateAccountRoot"

private let SERVER_ADMIN_LOGIN_NAME = "ServerAdminLoginName"
private let SERVER_ADMIN_LOGIN_PWD  = "ServerAdminLoginPwd"


/// Intercepts access to the URL path: /serveradmin and redirects them to the adminSiteRoot. In effect making the server
// admin website available under any domain that has this service installed.
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

func service_serverAdmin(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {
    
    
    
    func createAdminAccountPage(name: String, nameColor: String, pwdColor: String, rootColor: String) {
        
        let html: String = """
            <!DOCTYPE html>"
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
    }
    
    func loginAdminAccountPage() {
        
        // If there is a custom login page, use that instead of the default.
        
        var html: String?
        
        let rootPath = parameters.adminSiteRoot.value
        
        if !rootPath.isEmpty {
            
            let rootUrl = URL(fileURLWithPath: rootPath)
            let loginUrl = rootUrl.appendingPathComponent("login.sf.html")
            
            switch SFDocument.factory(path: loginUrl.path, filemanager: connection.filemanager) {
                
            case .error(let message):
                
                Log.atError?.log(
                    message,
                    from: Source(id: connection.logId, file: #file, function: #function, line: #line)
                )
                
                response.code = Response.Code._500_InternalServerError
                
            case .success(let doc):
                
                var environment = Function.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
                
                response.body = doc.getContent(with: &environment)
                response.code = Response.Code._200_OK
                response.contentType = mimeTypeHtml
            }

            return
        }
        
        if html == nil {
            html = """
                <!DOCTYPE html>
                <html>
                   <head>
                      <title>Swiftfire Admin Login</title>
                   </head>
                   <body>
                      <div>
                         <form action="/serveradmin" method="post">
                            <div>
                               <h3>Server Admin Login</h3>
                               <p style="margin-bottom:0px;">Name:</p>
                               <input type="text" name="ServerAdminLoginName" value="Server Admin"><br>
                               <p style="margin-bottom:0px;">Password:</p>
                               <input type="password" name="ServerAdminLoginPwd" value=""><br>
                               <input type="submit" value="Submit">
                             </div>
                          </form>
                      </div>
                   </body>
                </html>
            """
        }
        
        response.code = Response.Code._200_OK
        response.version = Version.http1_1
        response.contentType = mimeTypeHtml
        response.body = html!.data(using: String.Encoding.utf8)
    }

    func adminStatusPage(message: String? = nil) {
        
        var rootColor = "black"
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: parameters.adminSiteRoot.value, isDirectory: &isDir) {
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
                     <p style="margin-bottom:0px;">Swiftfire Version  : \(telemetry.serverVersion.value)</p>
                     <p style="margin-bottom:0px;">HTTP Server Status : \(telemetry.httpServerStatus.value)</p>
                     <p style="margin-bottom:0px;">HTTPS Server Status: \(telemetry.httpsServerStatus.value)</p>
                     <form action="/serveradmin/sfcommand/SetRoot" method="post">
                        <div>
                           <p style="margin-bottom:0px;color:\(rootColor);">\(message)</p>
                           <input type="text" name="\(SERVER_ADMIN_CREATE_ACCOUNT_ROOT)" value="\(parameters.adminSiteRoot.value)">
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
        return .next
    }
    
    
    // Prepare the url
    
    guard let urlstr = request.url else {
        Log.atError?.log("No request URL found", id: connection.logId)
        response.code = Response.Code._400_BadRequest
        return .next
    }
    
    
    // If the url contains '/serveradmin' then remove that part.
    
    var url = URL(fileURLWithPath: urlstr)
    var pathComponents = url.pathComponents

    if  pathComponents.count > 1,
        pathComponents[0].caseInsensitiveCompare("/") == ComparisonResult.orderedSame,
        pathComponents[1].caseInsensitiveCompare("serveradmin") == ComparisonResult.orderedSame {
        
        pathComponents.removeFirst()
        pathComponents.removeFirst()
    }

    
    // Create the relative resource path.
    
    url = URL(fileURLWithPath: parameters.adminSiteRoot.value)
    for comp in pathComponents { url.appendPathComponent(comp) }
    
    var relPath: String = pathComponents.reduce("") { return ($0 + "/\($1)") }
    
    
    // ======================================================================
    // There must be a session, without an active session nothing is possible
    // ======================================================================
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atCritical?.log("No session found, this service should come AFTER the 'getSession' service.", id: connection.logId)
        domain.telemetry.nof500.increment()
        response.code = Response.Code._500_InternalServerError
        return .next
    }
    
    
    // ================================================================================================================
    // If there are login details available, either login to an account, switch to another account or create an account
    // ================================================================================================================
    
    if let postInfo = info[.postInfoKey] as? PostInfo {
        
        if serverAdminDomain.accounts.isEmpty {
            
            // There is no server account, only accept account creation.
            
            if  let name = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_NAME],
                let pwd1 = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_PWD1],
                let pwd2 = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_PWD2],
                let root = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_ROOT] {
                
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
                
                
                // There must be an index file in the server admin root directory
                
                let rootUrl = URL(fileURLWithPath: root, isDirectory: true)
                let indexUrl = rootUrl.appendingPathComponent("index.sf.html")
                
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: indexUrl.path, isDirectory: &isDir), isDir.boolValue == false else {
                    createAdminAccountPage(name: name, nameColor: "black", pwdColor: "black", rootColor: "red")
                    return .next
                }
                
                
                // Credentials are considered valid, create account
                
                if let account = serverAdminDomain.accounts.newAccount(name: name, password: pwd1) {
                    
                    Log.atNotice?.log("Created admin account for: '\(name)'", id: connection.logId)
                    
                    parameters.adminSiteRoot.value = root
                    
                    if let url = StorageUrls.parameterDefaultsFile {
                        parameters.save(toFile: url)
                    }
                    
                    session[.accountKey] = account
                    
                    relPath = ""

                    /*** FALLTHROUGH ***/
    
                } else {
                    
                    Log.atCritical?.log("Failed to create admin account for: \(name)", id: connection.logId)
                    
                    response.code = Response.Code._500_InternalServerError
                    
                    return .next
                }
                
            } else {
                
                // One or more account creation details missing
                
                Log.atDebug?.log("Admin account creation credential(s) missing", id: connection.logId)
                
                createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
                
                return .next
            }

            
        } else {
            
            // There is a server account, only accept login.
        
            // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt

            if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
                let now = Date().javaDate
                if now - previousAttempt < 2000 {
                    session[.lastFailedLoginAttemptKey] = now
                    loginAdminAccountPage()
                    return .next
                }
            }
            
            
            // Get name/pwd from admin and check if it is known.
            
            if  let name = postInfo[SERVER_ADMIN_LOGIN_NAME],
                let pwd = postInfo[SERVER_ADMIN_LOGIN_PWD] {
                
                
                // Get the account for the login data
                
                if let account = serverAdminDomain.accounts.getAccount(for: name, using: pwd) {
                
                    Log.atNotice?.log("Admin \(name) logged in, \(account.uuid)", id: connection.logId)
                    
                    
                    // Associate the account with the session. This allows access for subsequent admin pages.
                    
                    session[.accountKey] = account
                    
                    
                    // If an admin tried to access an protected page while not logged-in, then the URL of that page is stored in the session.
                    // Restore the original URL such that the admin is taken to the page he wanted to access.
                    
                    if let url = session[.preLoginUrlKey] as? String {
                        
                        // If the admin went directly for the login page, then redirect the URL to the status page (empty path).
                        // Not doing so would cause the login page to be displayed again.
                        
                        if url == "/login.html" {
                            relPath = ""
                        } else {
                            relPath = url
                        }
                        
                    } else {
                        relPath = ""
                    }
                    
                    
                    // Remove the previous access url from the session.
                    
                    session[.preLoginUrlKey] = nil
                    
                    
                    /*** Fallthrough ***/
                    
                    
                } else {
                    
                    // The login attempt failed, no account found.
                    
                    Log.atNotice?.log("Admin login failed for \(name)", id: connection.logId)
                    
                    
                    // Failed login, reset possible account
                    
                    session[.accountKey] = nil
                    
                    
                    // Set the timestamp for the failed attempt
                    
                    session[.lastFailedLoginAttemptKey] = Date().javaDate
                    
                    
                    loginAdminAccountPage()
                    
                    return .next
                }
            }
        }
    }
    
    
    // ==================================================================================================
    // If this is not a request for a CSS file, there should be an active server admin account to proceed
    // ==================================================================================================
    
    if let fileExtension = relPath.components(separatedBy: ".").last,
        fileExtension.caseInsensitiveCompare("css") == ComparisonResult.orderedSame {
        
        // It is an css file, let it go through. This is necessary because some pages will be returned while there is no active admin account. These pages can only render successfully if the formatting is allowed through.
        
    } else {
            
        guard let account = session.info[.accountKey] as? Account, serverAdminDomain.accounts.contains(account.uuid) else {
            
            // A server admin should login first
            
            if serverAdminDomain.accounts.isEmpty {
                
                Log.atDebug?.log("An admin account must be created first", id: connection.logId)
                
                
                // Return the account creation page
                
                createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
                
            } else {
                
                Log.atDebug?.log("An admin should login first", id: connection.logId)
                
                
                // Return the account login page
                
                loginAdminAccountPage()
            }
            
            
            // If the user tried to access a specific admin page, but was not yet logged in, then remember the url that was the target.
            
            if !relPath.isEmpty {
                session.info[.preLoginUrlKey] = relPath
            }
            
            return .next
        }
    }
    
    
    // *****************************************
    // There is a server administrator logged in
    // *****************************************

    
    // =================================================================================================================
    // Special case 1: Changing the root page
    // =================================================================================================================

    if relPath == "/adminstatusroot" {
        adminStatusPage()
        return .next
    }
    
    
    // =================================================================================================================
    // Special case 2: Logout
    // =================================================================================================================
    
    if relPath == "/logout.html" {
        session[.accountKey] = nil
        session[.preLoginUrlKey] = nil
        // Note that we are past the point where the access rights are tested, hence the current page will be returned correctly.
    }

    
    // =================================================================================================================
    // Special case 3: execute server commands
    // =================================================================================================================

    if pathComponents.count >= 2 && pathComponents[0] == "sfcommand" {
        pathComponents.removeFirst()
        var postInfo = info[.postInfoKey] as? PostInfo
        switch executeSfCommand(pathComponents, &postInfo, session, &info, &response) {
        case .next: return .next
        case .newPath(let path): relPath = path
        case .nop: break
        }
    }
    

    // =================================================================================================================
    // Test if the resource exists
    // =================================================================================================================

    // If there is no server admin root set, then display the build-in status page where the admin can set a new root.
    
    if parameters.adminSiteRoot.value.isEmpty {
        adminStatusPage()
        if !relPath.isEmpty {
            session.info[.preLoginUrlKey] = relPath
        }
        return .next
    }

    var absPath = parameters.adminSiteRoot.value + relPath
    
    Log.atDebug?.log("Looking for file at path: '\(absPath)'", id: connection.logId)

    
    // Check for the request file, build a new path if necessary
    
    var isDirectory: ObjCBool = false
    
    if connection.filemanager.fileExists(atPath: absPath, isDirectory: &isDirectory) {
        
        
        // There is something, if it is a directory, check for index.html or index.htm
        
        if isDirectory.boolValue {
            
            
            // Find a root-index file
            
            let acceptedIndexNames = ["index.html", "index.sf.html", "index.htm", "index.sf.htm"]
            
            var success = false
            
            for name in acceptedIndexNames {
                
                
                // Check for an 'index.html' file
                
                let tpath = (absPath as NSString).appendingPathComponent(name)
                
                if connection.filemanager.isReadableFile(atPath: tpath) {
                    
                    absPath = tpath as String
                    
                    success = true
                    
                    break
                }
            }
            
            
            if !success {

                // None of the files exists, or directory access is not allowed

                // Error recovery: Make sure the adminSiteRoot is valid
                
                if adminSiteRootIsValid(connection.filemanager) {
                
                    response.code = Response.Code._404_NotFound
                    
                } else {
                
                    adminStatusPage()
                }
                
                return .next
            }
            
        } else {
            
            // Check if the resource is readable
            
            if !connection.filemanager.isReadableFile(atPath: absPath) {
                
                // Not readable
                
                // Error recovery: Make sure the adminSiteRoot is valid
                
                if adminSiteRootIsValid(connection.filemanager) {

                    response.code = Response.Code._403_Forbidden
                    
                } else {
                    
                    adminStatusPage()
                }
                
                return .next
            }
        }
        
    } else {
        
        // The resource is not found
        
        // Error recovery: Make sure the adminSiteRoot is valid
        
        if !adminSiteRootIsValid(connection.filemanager) {

            response.code = Response.Code._404_NotFound
            
        } else {
            
            adminStatusPage()
        }
        
        return .next
    }
    
    
    Log.atDebug?.log("Reading file at path: \(absPath)", id: connection.logId)

    
    // =================================================================================================================
    // Fetch the requested resource
    // =================================================================================================================
    
    // If the file can contain function calls, then process it. Otherwise return the file as read.
    
    if (absPath as NSString).lastPathComponent.contains(".sf.") {
        
        switch SFDocument.factory(path: absPath, filemanager: connection.filemanager) {
            
        case .error(let message):
            
            Log.atError?.log(
                message,
                from: Source(id: connection.logId, file: #file, function: #function, line: #line)
            )

            response.code = Response.Code._500_InternalServerError
            
            return .next
            
            
        case .success(let doc):
            
            var environment = Function.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
            
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

    let path = parameters.adminSiteRoot.value
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

fileprivate func executeSfCommand(_ pathComponents: Array<String>, _ postInfo: inout PostInfo?, _ session: Session, _ info: inout Service.Info, _ response: inout Response) -> CommandExecutionResult {
    
    Log.atDebug?.log(from: Source(id: -1, file: #file, function: #function, line: #line))

    guard let commandName = pathComponents.first else { return .nop }
        
    switch commandName {
    case "SetRoot": executeSetRoot(postInfo); return .newPath("")
    case "SetParameter": executeSetParameter(postInfo); return .newPath("/pages/parameters.sf.html")
    case "SaveParameters": executeSaveParameters(); return .newPath("/pages/parameters.sf.html")
    case "ReadParameters": executeReadParameters(); return .newPath("/pages/parameters.sf.html")
    case "Restart": executeRestart(); return .newPath("/pages/restart.sf.html")
    case "Quit": return .newPath("/pages/quit.sf.html")
    case "CancelQuit": return .newPath("")
    case "ConfirmedQuit": executeQuitSwiftfire(); return .newPath("/pages/bye.sf.html")
    case "UpdateDomain": executeUpdateDomain(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "UpdateDomainServices": executeUpdateDomainServices(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "DeleteDomain": executeDeleteDomain(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "CreateDomain": executeCreateDomain(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "SaveDomains": executeSaveDomains(); return .newPath("/pages/domain-management.sf.html")
    case "ReadDomains": executeReadDomains(); return .newPath("/pages/domain-management.sf.html")
    case "UpdateBlacklist": executeUpdateBlacklist(&postInfo); return .newPath("/pages/blacklist.sf.html")
    case "AddToBlacklist": executeAddToBlacklist(&postInfo); return .newPath("/pages/blacklist.sf.html")
    case "RemoveFromBlacklist": executeRemoveFromBlacklist(&postInfo); return .newPath("/pages/blacklist.sf.html")
    case "UpdateDomainBlacklist": executeUpdateDomainBlacklist(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "AddToDomainBlacklist": executeAddToDomainBlacklist(&postInfo); return .newPath("/pages/domain-management.sf.html")
    case "RemoveFromDomainBlacklist": executeRemoveFromDomainBlacklist(&postInfo); return .newPath("/pages/domain-management.sf.html")
        
    default:
        Log.atError?.log("Unknown sfcommand: \(commandName)")
        return .nop
    }
}

fileprivate func executeSetRoot(_ postInfo: PostInfo?) {
    guard let root = postInfo?[SERVER_ADMIN_CREATE_ACCOUNT_ROOT] else { return }
    parameters.adminSiteRoot.value = root
    if let url = StorageUrls.parameterDefaultsFile {
        parameters.save(toFile: url)
    }
    Log.atNotice?.log("Set admin root directory to: \(root)")
}

fileprivate func executeSetParameter(_ postInfo: PostInfo?) {
    guard let postInfo = postInfo else {
        Log.atError?.log("Missing postInfo")
        return
    }
    OUTER: for (key, value) in postInfo {
        for p in parameters.all {
            if p.name == key {
                _ = p.setValue(value)
                Log.atNotice?.log("Setting parameter '\(key)' to '\(value)'")
                continue OUTER
            }
        }
        Log.atError?.log("Unknown parameter name \(key)")
    }
}

fileprivate func executeSaveParameters() {
    if let url = StorageUrls.parameterDefaultsFile {
        parameters.save(toFile: url)
    }
}

fileprivate func executeReadParameters() {
    if let url = StorageUrls.parameterDefaultsFile {
        _ = parameters.restore(fromFile: url)
    }
}

fileprivate func executeSaveDomains() {
    if let url = StorageUrls.domainDefaultsFile {
        _ = domains.save(toFile: url)
    }
}

fileprivate func executeReadDomains() {
    if let url = StorageUrls.domainDefaultsFile {
        _ = domains.restore(fromFile: url)
    }
}

fileprivate func executeUpdateBlacklist(_ postInfo: inout PostInfo?) {
    let _ = postInfo?.removeValue(forKey: "submit")
    guard let (address, action) = postInfo?.popFirst() else {
        Log.atError?.log("Missing address & action")
        return
    }
    let newAction: BlacklistAction = {
        switch action {
            case "close": return .closeConnection
            case "503": return .send503ServiceUnavailable
            case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    serverBlacklist.update(action: newAction, for: address)
}

fileprivate func executeAddToBlacklist(_ postInfo: inout PostInfo?) {
    let _ = postInfo?.removeValue(forKey: "submit")
    guard let address = postInfo?["newEntry"], isValidIpAddress(address) else { return }
    guard let action = postInfo?["action"] else { return }
    let newAction: BlacklistAction = {
        switch action {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    serverBlacklist.add(address, action: newAction)
}

fileprivate func executeRemoveFromBlacklist(_ postInfo: inout PostInfo?) {
    guard let (address, _) = postInfo?.popFirst() else { return }
    serverBlacklist.remove(address)
}

fileprivate func executeUpdateDomainBlacklist(_ postInfo: inout PostInfo?) {
    let _ = postInfo?.removeValue(forKey: "submit")
    guard let name = postInfo?.removeValue(forKey: "DomainName"),
          let domain = domains.domain(forName: name) else {
            Log.atError?.log("Missing domain name")
            return
    }
    guard let (address, action) = postInfo?.popFirst() else {
        Log.atError?.log("Missing address & action")
        return
    }
    let newAction: BlacklistAction = {
        switch action {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    domain.blacklist.update(action: newAction, for: address)
}

fileprivate func executeAddToDomainBlacklist(_ postInfo: inout PostInfo?) {
    let _ = postInfo?.removeValue(forKey: "submit")
    guard let name = postInfo?.removeValue(forKey: "DomainName"),
        let domain = domains.domain(forName: name) else {
            Log.atError?.log("Missing domain name")
            return
    }
    guard let address = postInfo?["newEntry"], isValidIpAddress(address) else { return }
    guard let action = postInfo?["action"] else { return }
    let newAction: BlacklistAction = {
        switch action {
        case "close": return .closeConnection
        case "503": return .send503ServiceUnavailable
        case "401": return .send401Unauthorized
        default:
            Log.atError?.log("Unknown action \(action)")
            return .closeConnection
        }
    }()
    domain.blacklist.add(address, action: newAction)
}

fileprivate func executeRemoveFromDomainBlacklist(_ postInfo: inout PostInfo?) {
    guard let name = postInfo?.removeValue(forKey: "DomainName"),
        let domain = domains.domain(forName: name) else {
            Log.atError?.log("Missing domain name")
            return
    }
    guard let (address, _) = postInfo?.popFirst() else { return }
    domain.blacklist.remove(address)
}


/// Update a parameter in a domain.

fileprivate func executeUpdateDomain(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"] else {
        Log.atError?.log("Missing postInfo")
        return
    }
    _ = postInfo?.removeValue(forKey: "DomainName")
    
    guard let domain = domains.domain(forName: name) else {
        Log.atError?.log("Missing DomainName in postInfo")
        return
    }
    
    guard postInfo?.count ?? 0 == 1 else {
        Log.atError?.log("Too many key/value pairs postInfo \(String(describing:postInfo))")
        return
    }
    
    guard let (key, value) = postInfo?.popFirst() else {
        Log.atError?.log("Missing parameter name and value in postInfo")
        return
    }
    
    switch key {
    case "name": domain.name = value
    case "wwwincluded": domain.wwwIncluded = Bool(lettersOrDigits: value) ?? domain.wwwIncluded
    case "root": domain.root = value
    case "forewardurl": domain.forwardUrl = value
    case "enabled": domain.enabled = Bool(lettersOrDigits: value) ?? domain.enabled
    case "accesslogenabled": domain.accessLogEnabled = Bool(lettersOrDigits: value) ?? domain.accessLogEnabled
    case "404logenabled": domain.four04LogEnabled = Bool(lettersOrDigits: value) ?? domain.four04LogEnabled
    case "sessionlogenabled": domain.sessionLogEnabled = Bool(lettersOrDigits: value) ?? domain.sessionLogEnabled
    case "phppath":
        domain.phpPath = nil
        if FileManager.default.isExecutableFile(atPath: value) {
            let url = URL(fileURLWithPath: value)
            if url.lastPathComponent == "php" {
                domain.phpPath = URL(fileURLWithPath: value)
            }
        }
    case "phpoptions":
        if domain.phpPath != nil {
            domain.phpOptions = value
        }
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
    case "sfresources": domain.sfresources = value
    case "sessiontimeout": domain.sessionTimeout = Int(value) ?? domain.sessionTimeout
    default:
        Log.atError?.log("Unknown key '\(key)' with value '\(value)'")
    }
}


/// Update the sequence of services in a domain.

fileprivate func executeUpdateDomainServices(_ postInfo: inout PostInfo?) {

    guard let domainName = postInfo?["DomainName"],
          let domain = domains.domain(forName: domainName) else { return }
    
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
    
    let serviceNames = serviceArr.map({ $0.name })
    
    domain.serviceNames = serviceNames
    
    domain.rebuildServices()
}


/// Deletes the domain.

fileprivate func executeDeleteDomain(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"] else {
        Log.atError?.log("Missing DomainName in postInfo")
        return
    }
    
    guard domains.contains(domainWithName: name) else {
        Log.atError?.log("Domain '\(name)' does not exist")
        return
    }
    
    domains.remove(domainWithName: name)
    
    Log.atNotice?.log("Deleted domain '\(name)')")
}


/// Creates a new domain

fileprivate func executeCreateDomain(_ postInfo: inout PostInfo?) {
    
    guard let name = postInfo?["DomainName"] else {
        Log.atError?.log("Missing DomainName in postInfo")
        return
    }
    
    guard !domains.contains(domainWithName: name) else {
        Log.atError?.log("Domain '\(name)' already exists")
        return
    }
    
    if let url = StorageUrls.domainsDir {
        
        let domainUrl = url.appendingPathComponent(name, isDirectory: true)
        
        if let domain = Domain(name: name, manager: domains, root: domainUrl) {
            domain.serviceNames = defaultServices
            domains.add(domain: domain)
            Log.atNotice?.log("Added new domain with \(domain))")
        } else {
            Log.atNotice?.log("Failed to domain for \(name))")
        }
        
    } else {
        
        Log.atError?.log("Failed to retrieve domains directory)")
    }

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
