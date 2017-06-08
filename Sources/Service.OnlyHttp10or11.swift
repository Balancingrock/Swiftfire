// =====================================================================================================================
//
//  File:       Service.OnlyHttp10or11.swift
//  Project:    Swiftfire
//
//  Version:    0.10.10
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
// 0.10.10 - Changed signature of function to use SFConnection
// 0.10.9 - Streamlined and folded http API into its own project
// 0.10.6 - Interface update
//        - Renamed chain... to service...
//        - Renamed HttpHeader to HttpRequest
// 0.10.0 - Renamed HttpConnection to SFConnection
//        - Renamed from DomainService to Service
// 0.9.18 - Header update
//        - Replaced log with Log?
// 0.9.15 - Initial release
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
/// - Returns: On error .abort, on success .next.

func service_onlyHttp10or11(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }

    
    // =============================================================================================================
    // The version must be present
    // =============================================================================================================
    
    guard let httpVersion = request.version else {
        
        
        // Telemetry update
        
        domain.telemetry.nof400.increment()
        
        
        // Aliases
        
        let logId = connection.interface?.logId ?? -2

        
        // Log update
        
        let message = "HTTP Version not present"
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: message)
        
        
        // Mutation update
        
        let mutation = Mutation.createAddClientRecord(from: connection)
        mutation.httpResponseCode = Response.Code._400_BadRequest.rawValue
        mutation.responseDetails = message
        mutation.requestReceived = info[.responseStartedKey] as? Int64 ?? 0
        statistics.submit(mutation: mutation, onError: {
            (message: String) in
            Log.atError?.log(id: connection.logId, source: #file.source(#function, #line), message: "Error during statistics submission:\(message)")
        })
        
        
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
        
        let logId = connection.interface?.logId ?? -2

        
        // Log update
        
        let message = "HTTP Version '\(httpVersion)' not supported"
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: message)
        
        
        // Mutation update
        
        let mutation = Mutation.createAddClientRecord(from: connection)
        mutation.httpResponseCode = Response.Code._505_HttpVersionNotSupported.rawValue
        mutation.responseDetails = message
        mutation.requestReceived = info[.responseStartedKey] as? Int64 ?? 0
        statistics.submit(mutation: mutation, onError: {
            (message: String) in
            Log.atError?.log(id: connection.logId, source: #file.source(#function, #line), message: "Error during statistics submission:\(message)")
        })
        
        
        // Response
        
        response.code = Response.Code._505_HttpVersionNotSupported
        return .next
    }
    
    return .next
}
