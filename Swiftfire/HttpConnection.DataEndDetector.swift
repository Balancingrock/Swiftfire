// =====================================================================================================================
//
//  File:       HttpConnection.DataEndDetector.swift
//  Project:    Swiftfire
//
//  Version:    0.9.14
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
// v0.9.14 - Upgraded to Xcode 8 beta 6
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.7  - Changed recording of the header from the swifterlog to the header logfile.
// v0.9.6  - Header update
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation


extension HttpConnection: DataEndDetector {
    
    /**
     This function stores the client data and checks if a complete HTTP Message has been received. If it has, it will start an http worker on the workerqueue, remove the message form the buffer and check for more messages. If no more (complete) messages are found, it terminates with "false". I.e. it never wants the connection to terminate. Connection termination is (nominally) left to the worker or to the client.
     
     - Returns: False if no message was found, true if a complete message was found.
     */
    
    func endReached(buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        
        
        log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: "Received \(buffer.count) bytes")
        
        
        // Add the new data
        
        messageBuffer.append(buffer)
        
        
        // Signal true if at least one complete message was found
        
        var result = false
        
        
        // See if there are complete messages
        
        SCAN_FOR_COMPLETE_MESSAGES: while true {
            
            
            // If there is no header, try to read a header
            
            if httpHeader == nil {
                
                
                // See if the header is complete in the incoming data
                
                if let header = HttpHeader(data: messageBuffer) {
                    
                    
                    // Store the header for future reference
                    
                    httpHeader = header
                    
                    
                    // Yes, the header is complete
                    
                    log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: "HTTP Message Header complete")
                    
                    
                    // =======================
                    // The header is complete.
                    // =======================
                    
                    // Write the header to the log if so required
                    // Note: This is done now because there might be errors this request.
                    
                    if parameters.headerLoggingEnabled { header.record(connection: self) }
                }
            }
            
            
            // ====================================
            // If there is no header break the scan
            // ====================================
            
            if httpHeader == nil { break SCAN_FOR_COMPLETE_MESSAGES }
            
            
            // =========================
            // Check for a complete body
            // =========================
            
            let bodyLength = httpHeader!.contentLength
            let messageSize = bodyLength + httpHeader!.headerLength

            if messageSize > messageBuffer.count { break SCAN_FOR_COMPLETE_MESSAGES }
                
                
            // ====================
            // The body is complete
            // ====================
                        
                        
            // Create duplicates of the header and body and pass these to the worker. This way the worker has sole access to the data it works on. Note that the header is a class and can thus be copied as is if the local header is set to nil afterwards.
                
            let bodyRange = Range(uncheckedBounds: (lower: httpHeader!.headerLength, upper: messageSize))
            let body = messageBuffer.subdata(in: bodyRange)
                
            log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: "HTTP Message Body complete, dispatching worker")
                            
                            
            // =====================
            // Start the Http Worker
            // =====================
            
            let header = httpHeader!
            workerQueue.async() { [unowned self] in self.httpWorker(header: header, body: body) }
                
                        
            // ===========================================================
            // Remove the message from the buffer and the header from self
            // ===========================================================
                
            let unprocessedRange = Range(uncheckedBounds: (lower: messageSize, upper: messageBuffer.count))
            messageBuffer = messageBuffer.subdata(in: unprocessedRange)
                
            httpHeader = nil
                        
                        
            // We found at least one complete message
                        
            result = false
        }
        
        return result
    }
}
