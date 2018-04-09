// =====================================================================================================================
//
//  File:       Forwarder.swift
//  Project:    Swiftfire
//
//  Version:    0.10.11
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.12 - Upgraded to SwifterLog 1.1.0
// 0.10.11 - Renaming createErrorMessageInBody
// 0.10.9 - Streamlined and folded http API into its own project
// 0.10.7 - Changed receiverData to processReceivedData
// 0.10.6 - Update of receiverLoop
// 0.9.18 - Header update
//        - Replaced log with Log?
// 0.9.15 - General update and switch to frameworks, Initial release
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

class Forwarder: SwifterSockets.Connection {
    
    static var error: String?
    
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
        Log.atError?.log(message: message, from: Source(id: Int(client!.interface!.logId), file: #file, type: "Forwarder", function: #function, line: #line))
        closeForwarder()
    }
    
    override func processReceivedData(_ buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        _ = client?.transfer(buffer, callback: nil)
        return true
    }
}
