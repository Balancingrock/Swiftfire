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
// To install this service, insert it after DecodePostFormUrlEncoded and before GetResourcePathFromUrl.
//
//
// Input:
// ------
//
// request.url: Analyzed for "serveradmin" domain access.
// response.code: If set, skips this service
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
import SwiftfireCore
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
    
    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // The connection is a SFConnection
    
    guard let connection = connection as? SFConnection else {
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Failed to cast Connection as SFConnection")
        response.code = HttpResponseCode.code500_InternalServerError
        return .abort
    }
    
    
    // =================================================================================================================
    // First priority is to make sure an admin account exists
    // =================================================================================================================

    if adminAccounts.count == 0 {
        
        // If there are no admin setup credentials, then request them.
        // If there are credentials, then validate them.
        // If the credentials are valid, create the account
        
        guard let postInfo = info[.postInfoKey] as? Dictionary<String, String> else {
            adminCreateAccountPage(response: &response, name: "", nameColor: "black", pwdColor: "black", rootColor: "black")
            return .next
        }
        
        guard let name = postInfo["CreateAdminAccountName"], !name.isEmpty, name.characters.count < 30 else {
            adminCreateAccountPage(response: &response, name: "", nameColor: "red", pwdColor: "black", rootColor: "black")
            return .next
        }
        
        guard let pwd1 = postInfo["CreateAdminAccountPwd1"], !pwd1.isEmpty else {
            adminCreateAccountPage(response: &response, name: "", nameColor: "black", pwdColor: "red", rootColor: "black")
            return .next
        }
        
        guard let pwd2 = postInfo["CreateAdminAccountPwd2"], pwd2 == pwd1 else {
            adminCreateAccountPage(response: &response, name: "", nameColor: "black", pwdColor: "red", rootColor: "black")
            return .next
        }
        
        guard let root = postInfo["CreateAdminAccountRoot"], !root.isEmpty else {
            adminCreateAccountPage(response: &response, name: "", nameColor: "black", pwdColor: "black", rootColor: "red")
            return .next
        }
        
        // There must be an index file in the server admin root directory
        
        let rootUrl = URL(fileURLWithPath: root, isDirectory: true)
        let indexUrl = rootUrl.appendingPathComponent("index.sf.html")
                            
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: indexUrl.path, isDirectory: &isDir), isDir.boolValue == false else {
            adminCreateAccountPage(response: &response, name: "", nameColor: "black", pwdColor: "black", rootColor: "red")
            return .next
        }
        
        // Credentials are valid, create account
    }
    
    
    
    // Only service the serverAdminPseudoDomain
    
    guard domain === serverAdminPseudoDomain else { return .next }
    
    
    // Prepare the url
    
    guard let urlstr = request.url else { return .next }
    
    
    // Remove the first path component if it is 'serveradmin'.
    
    var url = URL(fileURLWithPath: urlstr)
    var pathComponents = url.pathComponents

    guard pathComponents.count > 0 else { return .next }
    
    let firstPathComponent = pathComponents.removeFirst()
        
    if firstPathComponent.caseInsensitiveCompare("serveradmin") != ComparisonResult.orderedSame { return .next }
    
    
    // Yes, it is a request for a server admin page
    // Create the resource path.
    
    url = URL(fileURLWithPath: parameters.adminSiteRoot.value)
    for comp in pathComponents { url.appendPathComponent(comp) }
    
    var fullPath = url.path
    
    
    // =================================================================================================================
    // Determine the action to be taken
    // =================================================================================================================
    
    
    let session = info[.sessionKey] as? Session
    
    
    // Initially there is no session
    // -----------------------------
    
    if session == nil {
        
        // Create session
        // Store the requested url in a preLoginUrlKey.
        // Request the server admin credentials.
        
        let newSession = adminSessions.newSession(address: connection.remoteAddress, domainName: "SwiftfireServer", logId: connection.logId, connectionId: connection.objectId, allocationCount: connection.allocationCount, timeout: 600)
        
        info[.sessionKey] = newSession
        
        if pathComponents.count > 0 { session?.info[.preLoginUrlKey] = fullPath }
        
        fullPath = URL(fileURLWithPath: parameters.adminSiteRoot.value).appendingPathComponent("login.sf.html").path

    } else {
    
        
        // Then there is a session and there are a login credentials but the credentials are not yet checked.
        // --------------------------------------------------------------------------------------------------
        
        let account = session?.info[.accountKey] as? Account
        
        if account == nil {
            
            
            // Check the credentials and find the used account
            
            if  let postInfo = info[.postInfoKey] as? Dictionary<String, String>,
                let name = postInfo["UserName"],
                let password = postInfo["Password"],
                let account = adminAccounts.getAccount(for: name, using: password) {
                
                
                // Save the account
                
                session?.info[.accountKey] = account
                
                
                // There should be a preLoginUrl path, use that and remove it.
                
                if let preLoginUrlPath = session?.info[.preLoginUrlKey] as? String {
                    
                    session?.info[.preLoginUrlKey] = nil
                    fullPath = preLoginUrlPath
                    
                } else {
                    
                    // If there was no preLoginUrl then go to the index page
                    
                    fullPath = parameters.adminSiteRoot.value
                }
                
            } else {
                
                // Something is missing/wrong, try again
                
                fullPath = URL(fileURLWithPath: parameters.adminSiteRoot.value).appendingPathComponent("login.sf.html").path
            }
            
        } else {
            
            // This is the normal case: an admin is logged in and requests pages
            // -----------------------------------------------------------------
            
            // Be sure it is an admin, if not dump the account and try a login again
            
            if !adminAccounts.contains(account?.uuid ?? "") {
                
                session?.info[.accountKey] = nil
                
                fullPath = URL(fileURLWithPath: parameters.adminSiteRoot.value).appendingPathComponent("login.sf.html").path
            }
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
    
    let payload: Data
    
    // If the file can contain function calls, then process it. Otherwise return the file as read.
    
    if (fullPath as NSString).lastPathComponent.contains(".sf.") {
        
        switch SFDocument.factory(path: fullPath, filemanager: connection.filemanager) {
            
        case .error(let message):
            
            handle500_ServerError(connection: connection, resourcePath: fullPath, message: message, line: #line)
            return .next
            
            
        case .success(let doc):
            
            var environment = Function.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
            
            payload = doc.getContent(with: &environment)
        }
        
        
        
    } else {
        
        guard let data = connection.filemanager.contents(atPath: fullPath) else {
            handle500_ServerError(connection: connection, resourcePath: fullPath, message: "Reading contents of file failed (but file is reported readable), resource: \(resourcePath)", line: #line)
            return .next
        }
        
        payload = data
    }
    
    
    // =============================================================================================================
    // Create the http response
    // =============================================================================================================
    
    
    // Telemetry update
    
    domain.telemetry.nof200.increment()
    
    
    // Response
    
    response.code = HttpResponseCode.code200_OK
    response.contentType = mimeType(forPath: resourcePath) ?? mimeTypeDefault
    response.payload = payload
    
    return .next
    
    
    Log.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "")
    
    return .next
}


fileprivate func adminCreateAccountPage(response: inout HttpResponse, name: String, nameColor: String, pwdColor: String, rootColor: String) {
    
    let html = "<!DOCTYPE html>"
        + "<html>"
        +    "<head>"
        +       "<title>Server Admin Setup</title>"
        +    "</head>"
        +    "<body>"
        +       "<div>"
        +          "<form action=\"/serveradmin/setup.html\" method=\"post\">"
        +             "<div>"
        +                "<h3>Server Admin Setup</h3>"
        +                "<p style=\"margin-bottom:0px;color:\(nameColor);\">\(name):</p>"
        +                "<input type=\"text\" name=\"CreateAdminAccountName\" value=\"Server Admin\"><br>"
        +                "<p style=\"margin-bottom:0px;color:\(pwdColor);\">Password:</p>"
        +                "<input type=\"password\" name=\"CreateAdminAccountPwd1\" value=\"\"><br>"
        +                "<p style=\"margin-bottom:0px;color:\(pwdColor);\">Repeat:</p>"
        +                "<input type=\"password\" name=\"CreateAdminAccountPwd2\" value=\"\"><br>"
        +                "<p style=\"margin-bottom:0px;color:\(rootColor);\">Root directory for the server admin site:</p>"
        +                "<input type=\"text\" name=\"CreateAdminAccountRoot\" value=\"\" style=\"min-width:300px;\"><br><br>"
        +                "<input type=\"submit\" value=\"Submit\">"
        +              "</div>"
        +           "</form>"
        +       "</div>"
        +    "</body>"
        + "</html>"
    
    
    let response = HttpResponse()
    response.code = HttpResponseCode.code200_OK
    response.version = HttpVersion.http1_1
    response.contentType = mimeTypeDefault
    response.payload = html.data(using: String.Encoding.utf8)
}
