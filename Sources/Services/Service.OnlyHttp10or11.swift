// =====================================================================================================================
//
//  File:       Service.OnlyHttp10or11.swift
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
// Examines the request header and create an error code if the header is neither a HTTP 1.0 or HTTP 1.1 verion.
//
// If a response.code is set, this operation exists immediately with .next.
//
//
// Input:
// ------
//
// header.httpVersion: The version of the http request header.
// response.code: If set, this service will exit immediately with .next'.
//
//
// On success:
// -----------
//
// return: .next
//
//
// On error: Missing http version
// -----------------------------------------
// response.code: code 400 (Bad Request) if the HTTP request contains no operation.
// domain.telemetry.nof400: incremented
// statistics: Updated with a ClientRecord.
//
// return: .next
//
//
// On error: Wrong http version
// ----------------------------------------------------
//
// response.code: code 505 (HTTP Version Not Supported) if the HTTP request was neither 1.0 or 1.1.
// domain.telemetry.nof505: incremented
// statistics: Updated with a ClientRecord.
//
// return: .next
//
// =====================================================================================================================

import Foundation

import SwifterLog
import SwifterSockets
import Http
import Core


/// Generate an error code if the request is not version HTTP 1.0 or HTTP 1.1.
///
/// - Note: For a full description of all effects of this operation see the file: Service.OnlyHttp10or11.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next.

func service_onlyHttp10or11(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }

    
    // =============================================================================================================
    // The version must be present
    // =============================================================================================================
    
    guard let httpVersion = request.version else {
        
        
        // Telemetry update
        
        domain.telemetry.nof400.increment()
        
        
        // Aliases
        
        let logId = Int(connection.interface?.logId ?? -2)

        
        // Log update
        
        let message = "HTTP Version not present"
        Log.atDebug?.log(message, id: logId)
        
        
        // Response
        
        response.code = Response.Code._400_BadRequest
        return .next
    }
    
    
    // =============================================================================================================
    // The header must be HTTP version 1.0 or 1.1
    // =============================================================================================================

    guard httpVersion == Version.http1_0 || httpVersion == Version.http1_1 else {
        
        
        // Telemetry update
        
        domain.telemetry.nof505.increment()
        
        
        // Aliases
        
        let logId = Int(connection.interface?.logId ?? -2)

        
        // Log update
        
        let message = "HTTP Version '\(httpVersion)' not supported"
        Log.atDebug?.log(message, id: logId)
        
        
        // Response
        
        response.code = Response.Code._505_HttpVersionNotSupported
        return .next
    }
    
    return .next
}
