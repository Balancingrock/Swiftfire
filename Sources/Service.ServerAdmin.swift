// =====================================================================================================================
//
//  File:       Service.ServerAdmin.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.7 - Initial release
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


/// Intercepts access to the URL path: /serveradmin and redirects them to the adminSiteRoot. In effect making the server
// admin website available under any domain that has this service installed.
///
/// - Note: For a full description of all effects of this operation see the file: Service.ServerAdmin.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The HttpConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abort, on success .next.

func service_serverAdmin(_ request: HttpRequest, _ connection: Connection, _ domain: Domain, _ info: inout Service.Info, _ response: inout HttpResponse) -> Service.Result {
    
    
    // These identifiers are the glue between admin creation/login pages and the code in this function.
    
    let SERVER_ADMIN_CREATE_ACCOUNT_NAME = "ServerAdminCreateAccountName"
    let SERVER_ADMIN_CREATE_ACCOUNT_PWD1 = "ServerAdminCreateAccountPwd1"
    let SERVER_ADMIN_CREATE_ACCOUNT_PWD2 = "ServerAdminCreateAccountPwd2"
    let SERVER_ADMIN_CREATE_ACCOUNT_ROOT = "ServerAdminCreateAccountRoot"
    
    let SERVER_ADMIN_LOGIN_NAME = "ServerAdminLoginName"
    let SERVER_ADMIN_LOGIN_PWD  = "ServerAdminLoginPwd"
    
    func createAdminAccountPage(name: String, nameColor: String, pwdColor: String, rootColor: String) {
        
        let html = "<!DOCTYPE html>"
            + "<html>"
            +    "<head>"
            +       "<title>Swiftfire Admin Setup</title>"
            +    "</head>"
            +    "<body>"
            +       "<div>"
            +          "<form action=\"/serveradmin/setup.html\" method=\"post\">"
            +             "<div>"
            +                "<h3>Server Admin Setup</h3>"
            +                "<p style=\"margin-bottom:0px;color:\(nameColor);\">Admin:</p>"
            +                "<input type=\"text\" name=\"\(SERVER_ADMIN_CREATE_ACCOUNT_NAME)\" value=\"\(name)\"><br>"
            +                "<p style=\"margin-bottom:0px;color:\(pwdColor);\">Password:</p>"
            +                "<input type=\"password\" name=\"\(SERVER_ADMIN_CREATE_ACCOUNT_PWD1)\" value=\"\"><br>"
            +                "<p style=\"margin-bottom:0px;color:\(pwdColor);\">Repeat:</p>"
            +                "<input type=\"password\" name=\"\(SERVER_ADMIN_CREATE_ACCOUNT_PWD2)\" value=\"\"><br>"
            +                "<p style=\"margin-bottom:0px;color:\(rootColor);\">Root directory for the server admin site:</p>"
            +                "<input type=\"text\" name=\"\(SERVER_ADMIN_CREATE_ACCOUNT_ROOT)\" value=\"\" style=\"min-width:300px;\"><br><br>"
            +                "<input type=\"submit\" value=\"Submit\">"
            +              "</div>"
            +           "</form>"
            +       "</div>"
            +    "</body>"
            + "</html>"
        
        response.code = HttpResponseCode.code200_OK
        response.version = HttpVersion.http1_1
        response.contentType = mimeTypeHtml
        response.payload = html.data(using: String.Encoding.utf8)
    }
    
    func loginAdminAccountPage() {
        
        let html = "<!DOCTYPE html>"
            + "<html>"
            +    "<head>"
            +       "<title>Swiftfire Admin Login</title>"
            +    "</head>"
            +    "<body>"
            +       "<div>"
            +          "<form action=\"/serveradmin/setup.html\" method=\"post\">"
            +             "<div>"
            +                "<h3>Server Admin Login</h3>"
            +                "<p style=\"margin-bottom:0px;\">Name:</p>"
            +                "<input type=\"text\" name=\"ServerAdminLoginName\" value=\"Server Admin\"><br>"
            +                "<p style=\"margin-bottom:0px;\">Password:</p>"
            +                "<input type=\"password\" name=\"ServerAdminLoginPwd\" value=\"\"><br>"
            +                "<input type=\"submit\" value=\"Submit\">"
            +              "</div>"
            +           "</form>"
            +       "</div>"
            +    "</body>"
            + "</html>"
        
        response.code = HttpResponseCode.code200_OK
        response.version = HttpVersion.http1_1
        response.contentType = mimeTypeHtml
        response.payload = html.data(using: String.Encoding.utf8)
    }

    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // The connection is a SFConnection
    
    guard let connection = connection as? SFConnection else {
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Failed to cast Connection as SFConnection")
        response.code = HttpResponseCode.code500_InternalServerError
        return .abort
    }
    
    
    // Only service the serverAdminPseudoDomain
    
    guard domain === serverAdminDomain else {
        Log.atError?.log(id: connection.logId, source: #file.source(#function, #line), message: "Domain should be serverAdminDomain")
        response.code = HttpResponseCode.code500_InternalServerError
        return .abort
    }
    
    
    // Prepare the url
    
    guard let urlstr = request.url else {
        Log.atError?.log(id: connection.logId, source: #file.source(#function, #line), message: "No request URL found")
        response.code = HttpResponseCode.code400_BadRequest
        return .abort
    }
    
    
    // If the url contains '/serveradmin' then remove it'.
    
    var url = URL(fileURLWithPath: urlstr)
    var pathComponents = url.pathComponents

    if  pathComponents.count > 1,
        pathComponents[0].caseInsensitiveCompare("/") != ComparisonResult.orderedSame,
        pathComponents[1].caseInsensitiveCompare("serveradmin") != ComparisonResult.orderedSame {
        
        pathComponents.removeFirst()
        pathComponents.removeFirst()
    }

    
    // Create the full resource path.
    
    url = URL(fileURLWithPath: parameters.adminSiteRoot.value)
    for comp in pathComponents { url.appendPathComponent(comp) }
    
    var fullPath = url.path
    
    
    // =======================
    // There must be a session
    // =======================
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atCritical?.log(id: connection.logId, source: #file.source(#function, #line), message: "No session found, this service should come AFTER the 'getSession' service.")
        domain.telemetry.nof500.increment()
        response.code = HttpResponseCode.code500_InternalServerError
        return .abort
    }
    
    
    // ===========================
    // Check for an active account
    // ===========================
    
    var account = session.info[.accountKey] as? Account
    
    if account == nil {
        
        // There is no account yet
        
        Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "No account found")
        
        
        // ===============================================
        // Check for presence of POST form urlencoded data
        // ===============================================
        
        guard let postInfo = info[.postInfoKey] as? Dictionary<String, String> else {
            
            // No post form data found
            
            Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "No postInfo found")
            
            
            // =================================
            // Check if there are admin accounts
            // =================================
            
            if serverAdminDomain.accounts.isEmpty {
                
                Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "No admin account present")
                
                
                // Return the account creation page
                
                createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
                
                return .next
                
            } else {
                
                Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Admin account(s) present")

            
                // Return the account login page
                
                loginAdminAccountPage()
                
                
                // If the user tried to access a specific admin page, but was not yet logged in, then remember the url that was the target.
                
                if pathComponents.count > 0 {
                    session[.preLoginUrlKey] = fullPath
                }
            }
            
            return .next
        }
        
        
        // =================================
        // Check if there are admin accounts
        // =================================

        if serverAdminDomain.accounts.isEmpty {
            
            
            // ======================================
            // Check for account creation credentials
            // ======================================
            
            if  let name = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_NAME],
                let pwd1 = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_PWD1],
                let pwd2 = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_PWD2],
                let root = postInfo[SERVER_ADMIN_CREATE_ACCOUNT_ROOT] {
                
                // Check the credentials
                
                Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Found admin account creation credentials")
                
                guard !name.isEmpty, name.characters.count < 30 else {
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
                
                
                // Credentials are valid, create account

                account = serverAdminDomain.accounts.newAccount(name: name, password: pwd1)
                
                guard account != nil else {
                    Log.atCritical?.log(id: connection.logId, source: #file.source(#function, #line), message: "Failed to create admin account with valid credentials")
                    response.code = HttpResponseCode.code500_InternalServerError
                    return .abort
                }
                
                parameters.adminSiteRoot.value = root
                
                session[.accountKey] = account!
                
                fullPath = root
                
                // *** FALLTHROUGH ***
            
            } else {
                
                // One or more account creation details missing
                
                Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Admin account creation credential(s) missing")

                createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
                
                return .next
            }
            
        } else {
            
            // ===========================
            // Check for login credentials
            // ===========================
            
            if  let name = postInfo[SERVER_ADMIN_LOGIN_NAME],
                let pwd = postInfo[SERVER_ADMIN_LOGIN_PWD] {
                
                account = serverAdminDomain.accounts.getAccount(for: name, using: pwd)
                
                if account != nil {
                    
                    Log.atNotice?.log(id: connection.logId, source: #file.source(#function, #line), message: "Admin \(name) logged in")
                    
                    session[.accountKey] = account!
                    
                    if let url = session[.preLoginUrlKey] as? String {
                        fullPath = url
                    }
                    
                    // *** Fallthrough ***
                    
                } else {
                    
                    Log.atNotice?.log(id: connection.logId, source: #file.source(#function, #line), message: "Admin login failed")
                    
                    loginAdminAccountPage()
                    
                    return .next
                }
                
            } else {
                
                Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "No login credentials present")
                
                loginAdminAccountPage()
                
                return .next
            }
        }
    
    } else {
        
        Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Account found")

        
        // =================================================
        // Verify that the account belongs to a server admin
        // =================================================
        
        if !serverAdminDomain.accounts.contains(account!.uuid) {

            Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Not a server admin account")
            
            // Error: not a server admin. Return the admin login page or the create admin login page
            
            if serverAdminDomain.accounts.count > 0 {
                createAdminAccountPage(name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
            } else {
                loginAdminAccountPage()
            }

            return .next
        }
    }
    
    
    // =================================================================================================================
    // Test if the resource exists
    // =================================================================================================================
    
    var isDirectory: ObjCBool = false
    
    if connection.filemanager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
        
        
        // There is something, if it is a directory, check for index.html or index.htm
        
        if isDirectory.boolValue {
            
            
            // Find a root-index file
            
            let acceptedIndexNames = ["index.html", "index.sf.html", "index.htm", "index.sf.htm"]
            
            var success = false
            
            for name in acceptedIndexNames {
                
                
                // Check for an 'index.html' file
                
                let tpath = (fullPath as NSString).appendingPathComponent(name)
                
                if connection.filemanager.isReadableFile(atPath: tpath) {
                    
                    fullPath = tpath as String
                    
                    success = true
                    
                    break
                }
            }
            
            
            if !success {

                // Neither file exists, and directory access is not allowed
            
                response.code = HttpResponseCode.code404_NotFound

                return .next
            }
            
        } else {
            
            // Check if the resource is readable
            
            if !connection.filemanager.isReadableFile(atPath: fullPath) {
                
                // Not readable
                
                response.code = HttpResponseCode.code403_Forbidden
                
                return .next
            }
        }
        
    } else {
        
        // The resource is not found
        
        response.code = HttpResponseCode.code404_NotFound
        
        return .next
    }
    
    
    // =================================================================================================================
    // Fetch the requested resource
    // =================================================================================================================
    
    // If the file can contain function calls, then process it. Otherwise return the file as read.
    
    if (fullPath as NSString).lastPathComponent.contains(".sf.") {
        
        switch SFDocument.factory(path: fullPath, filemanager: connection.filemanager) {
            
        case .error(let message):
            
            Log.atError?.log(id: connection.logId, source: #file.source(#function, #line), message: message)

            response.code = HttpResponseCode.code500_InternalServerError
            
            return .next
            
            
        case .success(let doc):
            
            var environment = Function.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
            
            response.payload = doc.getContent(with: &environment)
        }
        
        
        
    } else {
        
        guard let data = connection.filemanager.contents(atPath: fullPath) else {
            
            Log.atError?.log(id: connection.logId, source: #file.source(#function, #line), message: "Reading contents of file failed (but file is reported readable), resource: \(fullPath)")

            response.code = HttpResponseCode.code500_InternalServerError

            return .next
        }
        
        response.payload = data
    }
    
    
    // =============================================================================================================
    // Create the http response
    // =============================================================================================================
    
    
    // Telemetry update
    
    domain.telemetry.nof200.increment()
    
    
    // Response
    
    response.code = HttpResponseCode.code200_OK
    response.contentType = mimeType(forPath: fullPath) ?? mimeTypeDefault
    
    return .next
}



