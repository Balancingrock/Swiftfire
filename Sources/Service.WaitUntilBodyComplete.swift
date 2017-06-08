// =====================================================================================================================
//
//  File:       Service.WaitUntilBodyComplete.swift
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
// 0.10.10 - Initial release
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

func service_waitUntilBodyComplete(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {

    // Note: This function runs on the 'worker' thread of a connection.
    // The incoming data is received on the 'receiver' thread of the same connection.
    
    
    // If the content length is zero, no body is expected.
    
    if request.contentLength == request.body.count {
        Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Body already complete")
        return .next
    }
    
    
    // Wait until the body has been received
        
    var remainingBytes = request.contentLength
    
    Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Remaining bytes = \(remainingBytes)")
    
    while remainingBytes > 0 {
        if let chunk = connection.bodyGetNextChunk(timeout: 10.0, pollingInterval: 0.05) {
            request.body?.append(chunk)
            remainingBytes -= chunk.count
            Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Remaining bytes = \(remainingBytes)")
        } else {
            // Timeout: abort processing
            response.code = Response.Code._408_RequestTimeout
            return .abort
        }
    }
    
    
    // Body data is complete
    
    return .next
}
