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
// To install this service, insert it after GetPostFormUrlEncoded and before GetResourcePathFromUrl.
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
    
    // If the 'serveradmin' keyword is present as the first part of the URL then this is a request for the admin site.
    // In order to serve an admin page, an admin must be owner of this session. If there is a request for an admin site
    // resource and there is no admin logged in, then present the admin login page and remember the page that was requested
    // to be served immediately after the login.
    //
    // There are thus 4 starting conditions for this routine:
    //
    // 0) No server admin access.
    // 1) Initial: No admin logged in, access may either be the login page or any other page.
    // 2) Admin logged in, previous access from (1) is pending.
    // 3) Admin logged in, no previous access is pending.
    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // The connection is a SFConnection
    
    guard let connection = connection as? SFConnection else {
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Failed to cast Connection as SFConnection")
        response.code = HttpResponseCode.code500_InternalServerError
        return .abort
    }
    
    
    // Retrieve the url
    
    guard let urlstr = request.url else { return .next }
    
    
    // Check if it starts with 'serveradmin'.
    
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
    // Check if the admin is logged in
    // =================================================================================================================
    
    if let session = info[.sessionKey] as? Session {
        
        // Session found
        // Is it from an admin?
        
        if let account = session.info[.accountKey] as? Account {
            
            if adminAccounts.contains(account.uuid) {
                
                // The session contains an admin account
                // -------------------------------------
                // Check if there is a preLoginUrl, if so, return that resource.
                // If not, return the requested page from this request.
                
            } else {
                
                // Not an admin account
                // --------------------
                // Store the requested URL in a preLoginUrlKey.
                // Return the admin login page.
            }
            
        } else {
            
            // No account found
            // ----------------
            // Check if login credentials are available.
            // If so, check the credentials.
            // If not, request the credentials.
            
            if  let postInfo = info[.postInfoKey] as? Dictionary<String, String>,
                let name = postInfo["UserName"],
                let password = postInfo["Password"] {
                
                if let account = adminAccounts.getAccount(for: name, using: password) {
                    
                    // Store the account in the session
                    
                    session.info[.accountKey] = account
                    
                } else {
                    
                    // Invalid credentials
                    // Request new credentials after a short sleep
                    
                    sleep(5)
                    
                    
                }
                
            } else {
                
            }
        }
        
    } else {
        
        // No session found
        // ----------------
        // Create session
        // Store the requested url in a preLoginUrlKey.
        // Request the server admin credentials.
        
        
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
    // Read, process and return the resource
    // =================================================================================================================
    
    Log.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "")
    
    return .next
}
