// =====================================================================================================================
//
//  File:       Service.OnlyGetOrPost.swift
//  Project:    Swiftfire
//
//  Version:    1.0.1
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
// 1.0.1 - Documentation updates.
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets
import Http
import Core


/// Creates an error code if the HTTP request is not a GET or POST request.
///
/// _Input_:
///    - request.method
///
/// _Output_:
///    - response.code: Set to a an error code if the method is not a GET or POST. Otherwise set to nil.
///
/// _Sequence_:
///    - Can be one of the first services, does not need any predecessors.

func service_onlyGetOrPost(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }

    
    // =============================================================================================================
    // It must be either a GET or POST operation
    // =============================================================================================================
    
    guard let method = request.method else {
        
        
        // Telemetry update
        
        domain.telemetry.nof400.increment()
        
        
        // Aliases
        
        let logId = Int(connection.interface?.logId ?? -2)

        
        // Log update
        
        let message = "Could not extract operation"
        Log.atDebug?.log(message, id: logId)
        

        // Response
        
        response.code = Response.Code._400_BadRequest
        return .next
    }

    
    // =============================================================================================================
    // It must be either a GET or POST method
    // =============================================================================================================

    guard (method == .get || method == .post) else {
        
        
        // Telemetry update
        
        domain.telemetry.nof501.increment()
        
        
        // Aliases
        
        let logId = Int(connection.interface?.logId ?? -2)

        
        // Log update
        
        let message = "Method '\(method.rawValue)' not supported)"
        Log.atDebug?.log(message, id: logId)
        
        
        // Response
        
        response.code = Response.Code._501_NotImplemented
        return .next
    }

    return .next
}

