// =====================================================================================================================
//
//  File:       Service.WaitUntilBodyComplete.swift
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
// Ensures that the body has been completely received before continueing servicing the request.
//
//
// Input:
// ------
//
// request: If the payload is non nil, the body is already complete and no delay will occur before returning with .next.
// connection: If the request payload is nil, the connection object will be used to retrieve all the body data before continueing with .next. The data that is received will be stored in request.payload.
//
//
// On success:
// -----------
//
// request.payload: non-nil (but the Data may be empty)
// return: .next
//
//
// On error:
// ---------
//
// response.code:
//
// - code 400 (Bad Request) if the HTTP request header did not contain a url.
//   & domain.telemetry.nof400: incremented
//   & statistics: Updated with a ClientRecord.
//
// - code 404 (Not Found) if no resource (file) was present at the resource path.
//   & domain.telemetry.nof404: incremented
//   & statistics: Updated with a ClientRecord.
//
// - code 403 (Forbidden) if the file at the resource path is not readable.
//   & domain.telemetry.nof403: incremented
//   & statistics: Updated with a ClientRecord.
//
// return: .next
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets
import Http
import Core


/// Ensures that the body has been completely received before continueing servicing the request.
///
/// - Note: For a full description of all effects of this operation see the file: Service.WaitUntilBodyComplete.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abort, on success .next.

func service_waitUntilBodyComplete(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {

    // Note: This function runs on the 'worker' thread of a connection.
    // The incoming data is received on the 'receiver' thread of the same connection.
    
    
    // If the content length is zero, no body is expected.
    
    if request.contentLength == request.body.count {
        Log.atDebug?.log("Body already complete", id: connection.logId)
        return .next
    }
    
    
    // Wait until the body has been received
        
    var remainingBytes = request.contentLength
    
    Log.atDebug?.log("Remaining bytes = \(remainingBytes)", id: connection.logId)
    
    while remainingBytes > 0 {
        if let chunk = connection.bodyGetNextChunk(timeout: 10.0, pollingInterval: 0.05) {
            request.body?.append(chunk)
            remainingBytes -= chunk.count
            Log.atDebug?.log("Remaining bytes = \(remainingBytes)", id: connection.logId)
        } else {
            // Timeout: abort processing
            response.code = Response.Code._408_RequestTimeout
            return .abort
        }
    }
    
    
    // Body data is complete
    
    return .next
}
