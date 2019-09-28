// =====================================================================================================================
//
//  File:       Service.StorePreLoginUrl.swift
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
// 1.3.0 - Initial version
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets
import Http
import Core


/// This service stores the last page URL that was accessed before a login in the session info.
///
/// _Input_:
///    - services.info[.sessionKey]: There must be an existing session.
///    - services.info[.relativeResourcePath]: Will be checked for html, or php page that is not login .
///
/// _Output_:
///    - services.info[.preLoginUrlKey]: The URL of the last usefull page before a login.
///
/// _Sequence_:
///   - Should come after GetSession and GetResourcePathFromUrl

func service_storePreLoginUrl(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: Services.Info, _ response: Response) -> Services.Result {

    
    // Get the relative url
    
    guard let url = info[.relativeResourcePathKey] as? String else {
        Log.atError?.log("No relative resource path found, this service should come after GetResourcePathFromUrl!")
        return .next
    }


    // Get the session
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atError?.log("No session found, this service should come after GetSession!")
        return .next
    }
        
    
    // Is a user logged in?
    
    if let account = session.info[.accountKey] as? Account {
        Log.atDebug?.log("User \(account.name) logged in")
        return .next
    }
    
    
    // Store only php, htm and html resources in the pre login url
    
    switch (url as NSString).pathExtension.lowercased() {
    case "php", "htm", "html": break
    default: return .next
    }
    
    
    // Is this not a login url?
    
    if url.contains("templates/login.sf.htm") {
        Log.atDebug?.log("No tracking of login attempts")
        return .next
    }
    
    
    // Add the relative path in the pre-login url key
    
    Log.atDebug?.log("Pre login URL key old: \(session.info[.preLoginUrlKey] as? String ?? "not-a-string")")

    session.info[.preLoginUrlKey] = url
    
    Log.atDebug?.log("Pre login URL key new: \(session.info[.preLoginUrlKey] as? String ?? "not-a-string")")
    
    return .next
}
