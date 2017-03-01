// =====================================================================================================================
//
//  File:       DomainService.OnlyHttp10or11.swift
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
// 0.9.15 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Examines the request header and create an error code if the header is neither a HTTP 1.0 or HTTP 1.1 verion.
//
// If a response.code is set, this operation exists immediately with .continueChain.
//
//
// Input:
// ------
//
// header.httpVersion: The version of the http request header.
// response.code: If set, this service will exit immediately with .continueChain'.
//
//
// On success:
// -----------
//
// return: .continueChain
//
//
// On error: Missing http version
// -----------------------------------------
// response.code: code 400 (Bad Request) if the HTTP request contains no operation.
// domain.telemetry.nof400: incremented
// statistics: Updated with a ClientRecord.
//
// return: .continueChain
//
//
// On error: Wrong http version
// ----------------------------------------------------
//
// response.code: code 505 (HTTP Version Not Supported) if the HTTP request was neither 1.0 or 1.1.
// domain.telemetry.nof505: incremented
// statistics: Updated with a ClientRecord.
//
// return: .continueChain
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwiftfireCore
import SwifterSockets


/// Generate an error code if the request is not version HTTP 1.0 or HTTP 1.1.
///
/// - Note: For a full description of all effects of this operation see the file: DomainService.GetResourcePathFromUrl.swift
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

func ds_onlyHttp10or11(_ header: HttpHeader, _ body: Data?, _ connection: Connection, _ domain: Domain, _ chainInfo: inout DomainServices.ChainInfo, _ response: inout DomainServices.Response) -> DomainServices.ServiceResult {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .continueChain }

    
    // =============================================================================================================
    // The version must be present
    // =============================================================================================================
    
    guard let httpVersion = header.httpVersion else {
        
        
        // Telemetry update
        
        domain.telemetry.nof400.increment()
        
        
        // Aliases
        
        let connection = (connection as! HttpConnection)
        let logId = connection.interface?.logId ?? -2

        
        // Log update
        
        let message = "HTTP Version not present"
        log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: message)
        
        
        // Mutation update
        
        let mutation = Mutation.createAddClientRecord(from: connection)
        mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
        mutation.responseDetails = message
        mutation.requestReceived = chainInfo[ResponseStartedKey] as? Int64 ?? 0
        statistics.submit(mutation: mutation)
        
        
        // Response
        
        response.code = HttpResponseCode.code400_BadRequest
        return .continueChain
    }
    
    
    // =============================================================================================================
    // The header must be HTTP version 1.0 or 1.1
    // =============================================================================================================

    guard httpVersion == HttpVersion.http1_0 || httpVersion == HttpVersion.http1_1 else {
        
        
        // Telemetry update
        
        domain.telemetry.nof505.increment()
        
        
        // Aliases
        
        let connection = (connection as! HttpConnection)
        let logId = connection.interface?.logId ?? -2

        
        // Log update
        
        let message = "HTTP Version '\(httpVersion)' not supported"
        log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: message)
        
        
        // Mutation update
        
        let mutation = Mutation.createAddClientRecord(from: connection)
        mutation.httpResponseCode = HttpResponseCode.code505_HttpVersionNotSupported.rawValue
        mutation.responseDetails = message
        mutation.requestReceived = chainInfo[ResponseStartedKey] as? Int64 ?? 0
        statistics.submit(mutation: mutation)
        
        
        // Response
        
        response.code = HttpResponseCode.code505_HttpVersionNotSupported
        return .continueChain
    }
    
    return .continueChain
}
