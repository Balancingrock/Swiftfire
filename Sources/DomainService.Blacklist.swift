// =====================================================================================================================
//
//  File:       DomainService.Blacklist.swift
//  Project:    Swiftfire
//
//  Version:    0.9.15
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
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
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
// 0.9.15  - General update and switch to frameworks
// 0.9.14  - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Determines if the client's IP address is contained in the blacklist file for the domain. If it is in the blacklist
// it will trigger the action specified in it.
//
//
// Input:
// ------
//
// connection.remoteAddress: The IP address of the client.
// domain.blacklist: The list of blacklisted IP addresses for the domain.
//
//
// On success (IP is not contained in the blacklist)
// -------------------------------------------------
//
// response.code: nil
//
// return: .continueChain
//
//
// On error (IP address is contained in the blacklist)
// ---------------------------------------------------
//
// response.code:
// - nil: if the connection must be terminated immediately.
// - code 401: if the "not authorized" response has to be send.
// - code 503: if the "service unavailable" response has to be send.
//
// domain.telemetry.nofBlacklistedAccesses: Incremented.
//
// return:
// - .abortChain: If the IP address is blacklisted and the connection must be terminated immediately
// - .continueChain: If a 401 or 503 is required.
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwiftfireCore
import SwifterSockets


/// Checks if the client IP address is in the domain.blacklist.
///
/// - Note: For a full description of all effects of this operation see the file: DomainService.GetFileAtResourcePath.swift
///
/// - Parameters:
///   - header: The header of the HTTP request.
///   - body: The data that accompanied the HTTP request (if any).
///   - connection: The HttpConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - chainInfo: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abortChain, on success .continueChain.

func ds_blacklist(_ header: HttpHeader, _ body: Data?, _ connection: Connection, _ domain: Domain, _ chainInfo: inout DomainServices.ChainInfo, _ response: inout DomainServices.Response) -> DomainServices.ServiceResult {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .continueChain }
    
    
    // Aliases
    
    let logId = connection.interface?.logId ?? -2
    
    
    // Check if the client IP is blacklisted
    
    switch domain.blacklist.action(forAddress: connection.remoteAddress) {

    case nil: // No blacklisting action required
        
        return .continueChain
        
        
    case Blacklist.Action.closeConnection?:
        
        domain.telemetry.nofBlacklistedAccesses.increment()
        
        log.atLevelNotice(id: logId, source: #file.source(#function, #line), message: "Domain rejected blacklisted client \(connection.remoteAddress) by closing the connection")
        
        return .abortChain
        
        
    case Blacklist.Action.send401Unauthorized?:
        
        domain.telemetry.nofBlacklistedAccesses.increment()

        log.atLevelNotice(id: logId, source: #file.source(#function, #line), message: "Domain rejected blacklisted client \(connection.remoteAddress) with 401 reply")
        
        response.code = HttpResponseCode.code401_Unauthorized
        
        return .continueChain
        
        
    case Blacklist.Action.send503ServiceUnavailable?:
        
        domain.telemetry.nofBlacklistedAccesses.increment()

        log.atLevelNotice(id: logId, source: #file.source(#function, #line), message: "Domain rejected blacklisted client \(connection.remoteAddress) with 503 reply")
        
        response.code = HttpResponseCode.code503_ServiceUnavailable

        return .continueChain
    }
}


