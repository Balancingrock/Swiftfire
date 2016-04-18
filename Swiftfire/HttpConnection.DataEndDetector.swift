// =====================================================================================================================
//
//  File:       HttpConnection.DataEndDetector.swift
//  Project:    Swiftfire
//
//  Version:    0.9.0
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swiftfire.html
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
//
//  License:    Use this code any way you like with the following three provision:
//
//  1) You are NOT ALLOWED to redistribute this source code.
//
//  2) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  3) You WILL NOT seek compensation for possible damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that NAP is the way for societies to function optimally. I thus reject the implicit use of force
//  to extract payment. Since I cannot negotiate with you about the price of this code, I have choosen to leave it up to
//  you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/google to ensure that you actually pay me and not some imposter)
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
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = ((#file as NSString).lastPathComponent as NSString).stringByDeletingPathExtension


// For the buffer that is used to hold the HTTP messages.

class HttpMessageBuffer: UInt8Buffer {
    
    
    // If an HTTP message is present, this is the length of the complete message header + content.
    
    var firstMessageSize = 0
    
    
    // Returns true if the complete message was received
    
    var firstMessageIsComplete: Bool {
        if firstMessageSize == 0 { return false }
        return fill >= firstMessageSize
    }
    
    
    /**
     Remove the processed data from the buffer.
     */
    
    func removeFirstMessage() {
        
        if firstMessageSize == 0 { return }
        
        remove(firstMessageSize)
        
        firstMessageSize = 0
    }
}


extension HttpConnection: DataEndDetector {
    
    /**
     This function stores the client data and checks if a complete HTTP Message has been received. If it has, it will start an http worker on the workerqueue, remove the message form the buffer and check for more messages. If no more (complete) messages are found, it terminates with "false". I.e. it never wants the connection to terminate. Connection termination is (nominally) left to the worker or to the client.
     
     - Returns: False if no message was found, true if a complete message was found.
     */
    
    func endReached(buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        
        
        log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "Received \(buffer.count) bytes")
        
        
        // Add the new data
        
        messageBuffer.add(buffer)
        
        // Signal true if at least one complete message was found
        
        var result = false
        
        
        // See if there are complete messages
        
        SCAN_FOR_COMPLETE_MESSAGES: while true {
            
            
            // Quick check
            
            if messageBuffer.fill == 0 {
                break SCAN_FOR_COMPLETE_MESSAGES
            }
            
            
            // Init
            
            var messageHeaderLength = 0
            
            
            // =========================================================
            // If the message header is not complete yet, try to read it
            // =========================================================
            
            if httpHeader == nil {
                
                
                // See if the header is complete in the incoming data
                
                if let rangeCrLfCrLf = messageBuffer.stringValue.rangeOfString(CRLFCRLF, options: NSStringCompareOptions(), range: nil, locale: nil) {
                    
                    
                    // Yes, the header should be complete
                    
                    log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "Found end of http request")
                    
                    
                    // Create the http request header from the incoming data
                    
                    let headerString = messageBuffer.stringValue.substringToIndex(rangeCrLfCrLf.startIndex)
                    
                    
                    // Set the length of the header
                    
                    messageHeaderLength = headerString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) + 4 // +4 for the CRLFCRLF
                    
                    
                    // Split the header into its constitue lines
                    
                    let headerLines = headerString.componentsSeparatedByString(CRLF)
                    
                    
                    // Create the message header
                    
                    httpHeader = HttpHeader(lines: headerLines)
                    
                    
                    // =======================
                    // The header is complete.
                    // =======================
                    
                    
                    // Write the header to the log
                    
                    if Parameters.asBool(ParameterId.DEBUG_MODE) {
                        httpHeader!.writeToDebugLog(logId)
                    }
                    
                } else {
                    
                    // ==============================
                    // The header is not complete yet
                    // ==============================
                    
                    break SCAN_FOR_COMPLETE_MESSAGES
                }
            }
            
            
            // Check if the body is complete
            
            let bodyLength = httpHeader!.contentLength
            messageBuffer.firstMessageSize = bodyLength + messageHeaderLength
            
            if messageBuffer.firstMessageIsComplete {
                
                // ============================
                // Header and body are complete
                // ============================
                
                
                // Create duplicates of the header and buffer and pass these to the worker. This way the worker has sole access to the data it works on.
                
                if let header = httpHeader?.copy {
                    
                    let body = UInt8Buffer(from: messageBuffer, startByteOffset: messageHeaderLength, endByteOffset: self.messageBuffer.firstMessageSize)
                    
                    log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "HTTP Message Complete, dispatching worker")
                    
                    
                    // =====================
                    // Start the Http Worker
                    // =====================
                    
                    dispatch_async(workerQueue, { [unowned self] in self.httpWorker(header: header, body: body) })
                    
                } else {
                    log.atLevelError(id: logId, source: #file.source(#function, #line), message: "Message is complete, but no httpHeader is available")
                }
                
                
                // =================================================
                // Remove the message that was found from the buffer
                // =================================================
                
                messageBuffer.removeFirstMessage()
                httpHeader = nil
                
                
                // We found at least one complete message
                
                result = false
                
            } else {
                
                // ======================
                // The body is incomplete
                // ======================
                
                break SCAN_FOR_COMPLETE_MESSAGES
            }
        }
        
        return result
    }
}