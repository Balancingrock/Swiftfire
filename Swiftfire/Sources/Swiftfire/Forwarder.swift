// =====================================================================================================================
//
//  File:       Forwarder.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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

import Foundation
import SwifterSockets
import SwifterLog
import Http


/// Creates a new forwarding connection.

func forwardingConnectionFactory(_ ctype: SwifterSockets.InterfaceAccess, _ address: String) -> Forwarder? {
    let fcon = Forwarder()
    _ = fcon.prepare(for: ctype, remoteAddress: address, options: [])
    return fcon
}


/// A connection that passes incoming data to the designated client.

final class Forwarder: SwifterSockets.Connection {
    
    //static var error: String?
    
    var client: SwifterSockets.Connection?
    
    func closeForwarder() {
        closeConnection()
        client?.closeConnection()
    }
    
    override func receiverClosed() {
        closeForwarder()
    }
    
    override func receiverLoop() -> Bool {
        let reply = Response()
        reply.code = Response.Code._408_RequestTimeout
        reply.version = Version.http1_1
        reply.createErrorMessageInBody(message: "Forwarding target timed out.")
        if let data = reply.data {
            _ = client?.transfer(data, callback: nil)
        }
        closeForwarder()
        return false
    }
    
    override func receiverError(_ message: String) {
        Log.atError?.log(message, id: Int(client!.interface!.logId), type: "Forwarder")
        closeForwarder()
    }
    
    override func processReceivedData(_ buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        _ = client?.transfer(buffer, callback: nil)
        return true
    }
}
