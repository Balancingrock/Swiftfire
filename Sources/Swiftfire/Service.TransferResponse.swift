// =====================================================================================================================
//
//  File:       Service.TransferResponse.swift
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
// Transfer the response. If necesary first create an error response body.
//
// If no response body is present, first try to build a custom error for the domain involved. If there is none, then
// build a default body.
//
// Once a response body is present, transfer it to the client.
//
// Input:
// ------
//
// response.code: Must be present
// response.body: Must be nil
//
//
// Output:
// -------
//
// response.body: A default response body has been created.
//
//
// Return:
// -------
//
// .next
//
// =====================================================================================================================

import Foundation
import Http
import SwifterLog


/// If the body of the response is empty, but a response code is present, then add the body for the response code.
///
/// - Note: For a full description of all effects of this operation see the file: Service.AddResponseBodyIfEmpty.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next.

func service_transferResponse(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {
    
    
    // Log the code (should be present)
    
    Log.atDebug?.log("Domain services completed with code = \(response.code?.rawValue ?? "None")", id: connection.logId)

    
    // There must be a response code
    
    guard let code = response.code else { return .next }
    
    
    // If there is no playload try to create the default domain reply
    
    if response.body == nil {
        response.body = domain.customErrorResponse(for: code)
        if response.body != nil {
            response.contentType = mimeTypeHtml
        }
    }
    
    
    // If there is stil no payload, try the server default
    
    if response.body == nil {
        response.createErrorMessageInBody()
        if response.body != nil {
            response.contentType = mimeTypeHtml
        }
    }

    
    // Transfer the response
    
    if let reply = response.data {
        
        connection.bufferedTransfer(reply)
        
    } else {
        
        Log.atError?.log("Failed to create response data", id: connection.logId)
        response.body = Data()
    }

    
    return .next
}
