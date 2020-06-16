// =====================================================================================================================
//
//  File:       Service.WaitUntilBodyComplete.swift
//  Project:    Swiftfire
//
//  Version:    1.3.2
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2020 Marinus van der Lugt, All rights reserved.
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
// 1.3.2 #10 Made the service public
// 1.3.0 - Removed inout from the service signature
// 1.0.1 - Documentation update
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets
import Http
import Core


/// This service waits until the request body has been completely received before continuing.
///
/// _Input_:
///    - connection: The connection on which to wait for receipt of all data.
///
/// _Output_:
///    - request.payload: The data that was received.
///
/// _Sequence_:
///    - This service should come before any service that needs access to the payload. Specifically this includes the service DecodePostFormUrlEncoded.


public func service_waitUntilBodyComplete(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: Services.Info, _ response: Response) -> Services.Result {

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
