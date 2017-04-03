// =====================================================================================================================
//
//  File:       Service.GetFileAtResourcePath.swift
//  Project:    Swiftfire
//
//  Version:    0.10.0
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
// 0.10.0 - Renamed HttpConnection to SFConnection
//        - Added support for .sf. files (i.e. function call's from source text)
//        - Renamed from DomainService to Service
// 0.9.18 - Header update
//        - Replaced log with Log?
// 0.9.15 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Retrieves the file at the path from chainInfo[ResourcePathKey] and places it in the response.payload.
//
//
// Input:
// ------
//
// chainInfo[ResourcePathKey]: A string with the full path for the file to be read.
// response.code: If set, this service will exit immediately with .continueChain'.
//
//
// On success:
// -----------
//
// response.payload: Set with contents of file at chainInfo[ResourcePathKey]
// response.mimeType: Set to the mime type for the file extension
// response.code: Set to code 200 (OK)
//
// domain.telemetry.nof200: Incremented
//
// return: .continueChain
//
//
// On error:
// ---------
//
// response.code: Set to code 500 (Internal Server Error)
//
// domain.telemetry.nof500: Incremented
//
// statistics: Updated with new ClientRecord
//
// return: .abortChain
//
// Possible error causes:
// - No resource path found in chainInfo
// - Resource path in chainInfo points to a resource that cannot be retrieved
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwiftfireCore
import SwifterSockets


/// Retrieve the file content from the resource path and put it in the response payload.
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

func ds_getFileAtResourcePath(_ header: HttpHeader, _ body: Data?, _ connection: Connection, _ domain: Domain, _ chainInfo: inout Service.ChainInfo, _ response: inout Service.Response) -> Service.Result {
    
    

    func handle500_ServerError(connection: SFConnection, resourcePath: String?, message: String, line: Int) {
        
        
        // Telemetry update
        
        domain.telemetry.nof500.increment()
        
        
        // Log update
        
        Log.atCritical?.log(id: connection.logId, source: #file.source(#function, #line), message: message)
        
        
        // Mutation update
        
        let mutation = Mutation.createAddClientRecord(from: connection)
        mutation.httpResponseCode = HttpResponseCode.code500_InternalServerError.rawValue
        mutation.url = resourcePath
        mutation.responseDetails = message
        mutation.requestReceived = chainInfo[Service.ChainInfoKey.responseStartedKey] as? Int64 ?? 0
        statistics.submit(mutation: mutation, onError: {
            (message: String) in
            Log.atError?.log(id: connection.logId, source: #file.source(#function, line), message: "Error during statistics submission:\(message)")
        })
        
        
        // Response
        
        response.code = HttpResponseCode.code500_InternalServerError
    }
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .continueChain }

    
    // Aliases
    
    let connection = (connection as! SFConnection)
    
    
    // =================================================================================================================
    // Make sure a resource path string is present in the chainInfo
    // =================================================================================================================
    
    guard let resourcePath = chainInfo[Service.ChainInfoKey.absoluteResourcePathKey] as? String else {
        handle500_ServerError(connection: connection, resourcePath: nil, message: "No resource path present", line: #line)
        return .continueChain
    }

    
    // =================================================================================================================
    // Fetch the requested resource
    // =================================================================================================================
    
    let payload: Data
    
    // If the file can contain function calls, then process it. Otherwise return the file as read.
    
    if (resourcePath as NSString).lastPathComponent.contains(".sf.") {
    
        switch SFDocument.factory(path: resourcePath, filemanager: connection.filemanager) {
            
        case .error(let message):
            
            handle500_ServerError(connection: connection, resourcePath: resourcePath, message: message, line: #line)
            return .continueChain
            
            
        case .success(let doc):

            let environment = Function.Environment(header: header, body: body, connection: connection, domain: domain, response: &response, chainInfo: &chainInfo)
            
            payload = doc.getContent(with: environment)
        }
        
        
        
    } else {
        
        guard let data = connection.filemanager.contents(atPath: resourcePath) else {
            handle500_ServerError(connection: connection, resourcePath: resourcePath, message: "Reading contents of file failed (but file is reported readable), resource: \(resourcePath)", line: #line)
            return .continueChain
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
    response.mimeType = mimeType(forPath: resourcePath) ?? mimeTypeDefault
    response.payload = payload
        
    return .continueChain
}

