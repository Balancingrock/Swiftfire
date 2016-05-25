// =====================================================================================================================
//
//  File:       HttpConnection.Forwarding.swift
//  Project:    Swiftfire
//
//  Version:    0.9.6
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// v0.9.6 - Header update
// v0.9.3 - Added a telemetry counter to the "bad gateway" errors
// v0.9.2 - Minor adjustment to forwardingOpenConnection
//        - Replaced sendMessageWithCode with httpErrorResponseWithCode
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


private final class ForwardingReceiverEndDetector: DataEndDetector {
    
    var logId: Int32
    
    init(logId: Int32) { self.logId = logId }
    
    func endReached(buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: "Returning true.")
        return true
    }
}


extension HttpConnection {
    
    
    /// Opens a connection to the specified host and starts the receiverloop.
    
    func forwardingOpenConnection(host: Host) {
        
        do {
            
            forwardingSocket = try SwifterSockets.initClientOrThrow(address: host.address, port: (host.port ?? Parameters.asString(ParameterId.SERVICE_PORT_NUMBER)))
            
            
            // Start the receiver
            
            dispatch_async(forwardingReceiverQueue, {[unowned self] in self.forwardingReceiverLoop() })
            
        } catch {
            
            serverTelemetry.nofHttp502Replies.increment()
            log.atLevelError(id: logId, source: #file.source(#function, #line), message: "Could not open connection to \(host).")
            let response = httpErrorResponseWithCode(.CODE_502_Bad_Gateway, andMessage: "<p>Forwarding failed, server not reachable.</p>")
            transferToClient(response)
            
            forwardingCloseConnection()
        }
    }
    
    
    /// Closes the connection to a forwarding target (if any).
    
    func forwardingCloseConnection() {
        
        SwifterSockets.closeSocket(forwardingSocket)
        forwardingSocket = nil
    }
    
    
    /// Transmits the content of the given buffer to the forwarding target (if any).
    
    func forwardingTransmit(buffer: UInt8Buffer) {
        
        if forwardingSocket == nil {
            
            serverTelemetry.nofHttp502Replies.increment()
            let response = httpErrorResponseWithCode(.CODE_502_Bad_Gateway, andMessage: "<p>Forwarding failed, server not reachable.</p>")
            transferToClient(response)
            return
            
        } else {

            do {
                
                try SwifterSockets.transmitOrThrow(forwardingSocket!, buffer: buffer.ptr, timeout: 10.0, telemetry: nil)
                
            } catch {
                
                serverTelemetry.nofHttp502Replies.increment()
                let response = httpErrorResponseWithCode(.CODE_502_Bad_Gateway, andMessage: "<p>Forwarding failed, server not reachable, not responding or generating connection errors.</p>")
                transferToClient(response)
                
                forwardingCloseConnection()
            }
        }
    }
    
    
    private func forwardingReceiverLoop() {
        
        RECEIVER_LOOP: while forwardingSocket != nil {
            

            // The timeout guarantees that the process is terminated if the connection (socket) to the forwarding target is closed outside this process.

            let result = SwifterSockets.receiveNSData(forwardingSocket!, timeout: 1.0, dataEndDetector: ForwardingReceiverEndDetector(logId: logId), telemetry: nil)
            
            switch result {
                
            case .BUFFER_FULL:
                // This should not be possible
                log.atLevelError(id: forwardingSocket!, source: #file.source(#function, #line), message: "Unexpected BUFFER_FULL received")
                break RECEIVER_LOOP
                
            case let .CLIENT_CLOSED(data: data) where data is NSData:
                // Data is unlikely, but is possible, if there is data process it first before exiting the reciever loop
                let buffer = UInt8Buffer(sizeInBytes: (data as! NSData).length)
                buffer.add(data as! NSData)
                log.atLevelDebug(id: forwardingSocket!, source: #file.source(#function, #line), message: "Client closed")
                self.transferToClient(buffer)
                break RECEIVER_LOOP
                
            case let .ERROR(message: message):
                // Log the message and exit the receiver loop
                // Note that this is not necessarily an error
                log.atLevelInfo(id: forwardingSocket!, source: #file.source(#function, #line), message: message)
                break RECEIVER_LOOP
                
            case let .READY(data: data) where data is NSData:
                // Normal case, process the data
                let buffer = UInt8Buffer(sizeInBytes: (data as! NSData).length)
                buffer.add(data as! NSData)
                log.atLevelDebug(id: forwardingSocket!, source: #file.source(#function, #line), message: "Received a total of \((data as! NSData).length) bytes")
                transferToClient(buffer)
                
            case .TIMEOUT:
                // Normal case, repeat...
                break
                
            default:
                // This should not be possible
                log.atLevelError(id: self.forwardingSocket!, source: #file.source(#function, #line), message: "Unexpected 'default' executed")
            }
        }
        
        // Close this side of the connection to the forwarding target
        forwardingCloseConnection()
        
        // Also close the connection to the client (mimick the forwarding target behavior).
        // Keep in mind that the closeConnection operation will schedule the socket closing after the transfer of pending data.
        closeConnection()
    }
}