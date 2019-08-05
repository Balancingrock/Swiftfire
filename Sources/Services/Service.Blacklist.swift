// =====================================================================================================================
//
//  File:       Service.Blacklist.swift
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
// return: .next
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
// - .abort: If the IP address is blacklisted and the connection must be terminated immediately
// - .next: If a 401 or 503 is required.
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets
import Http
import Core


/// Checks if the client IP address is in the domain.blacklist.
///
/// - Note: For a full description of all effects of this operation see the file: DomainService.GetFileAtResourcePath.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abort, on success .next.

func service_blacklist(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }
    
    
    // Aliases
    
    let logId = Int(connection.interface?.logId ?? -2)
    
    
    // Check if the client IP is blacklisted
    
    switch domain.blacklist.action(for: connection.remoteAddress) {

    case nil: // No blacklisting action required
        
        return .next
        
        
    case .closeConnection?:
        
        domain.telemetry.nofBlacklistedAccesses.increment()
        
        Log.atNotice?.log("Domain rejected blacklisted client \(connection.remoteAddress) by closing the connection", id: logId)

        
        return .abort
        
        
    case .send401Unauthorized?:
        
        domain.telemetry.nofBlacklistedAccesses.increment()

        Log.atNotice?.log("Domain rejected blacklisted client \(connection.remoteAddress) with 401 reply", id: logId)
        
        response.code = Response.Code._401_Unauthorized
        
        return .next
        
        
    case .send503ServiceUnavailable?:
        
        domain.telemetry.nofBlacklistedAccesses.increment()

        Log.atNotice?.log("Domain rejected blacklisted client \(connection.remoteAddress) with 503 reply", id: logId)
        
        response.code = Response.Code._503_ServiceUnavailable

        return .next
    }
}


