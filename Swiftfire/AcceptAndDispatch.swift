// =====================================================================================================================
//
//  File:       AcceptAndDispatch.swift
//  Project:    Swiftfire
//
//  Version:    0.9.0
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swiftfire.html
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
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = ((#file as NSString).lastPathComponent as NSString).stringByDeletingPathExtension


// This var is used to stop the HTTP server

private var stopHttpServer: Bool = false


/// Use this function to stop accepting new HTTP requests. Note that this will only affect new requests, requested that are processed will not be aborted by this function. This function is thread safe.

func stopAcceptAndDispatch() {
    stopHttpServer = true
}


// This var indicates if the accept loop is still running

private var httpAcceptLoopIsActive: Bool = false


/// Use this function to find out if the HTTP accept loop is still running or not. Note that this function is only usefull if there is just 1 http server running. If there are more than 1, the result is unreliable. 

func httpServerIsRunning() -> Bool {
    return httpAcceptLoopIsActive
}


/// Accepts incoming HTTP requests and starts processing these requests on the default-priority dispatch queue. If an HTTP server is already running, it  start a additional server.
///
/// - Parameter socketDescriptor: The socket descriptor of the socket on which the application should listen for HTTP requests.

func acceptAndDispatch(socket: Int32) {
    
    
    // The accept loop is now active
    
    httpAcceptLoopIsActive = true
    
    
    // Enable the loop
    
    stopHttpServer = false
    
    
    // ========================
    // Start the "endless" loop
    // ========================
    
    ACCEPT_LOOP: while !stopHttpServer {
        
        
        // ============================
        // Allocate a connection object
        // ============================
        
        // Note: This limits the number of simultanious connections to ap_MaxNumberOfAcceptedConnections. Connections that are
        // not accepted stay in the ESTABLISHED state, and there are a maximum of ap_MaxNumberOfEstablishedConnects of
        // established connections possible. When both ap_MaxNumberOfAcceptedConnections and ap_MaxNumberOfEstablishedConnects
        // are reached, new requests will be ignored. (Not counting the fudge factor that is usesed in the negotiating phase)
        
        var connection: HttpConnection? = nil
        var loopCount = 0
        
        while (connection == nil) {

            
            // Check if the HTTP server must be stopped.
            
            if stopHttpServer { break ACCEPT_LOOP }

            
            // Try to get a free connection object
            
            connection = httpConnectionPool.allocate()
            
            if connection != nil {
                log.atLevelDebug(id: socket, source: SOURCE, message: "Got connection object")
            }
            
            
            // If no connection object could be had, try again in a little while until the specified timeout
            
            if connection == nil {
            
                // Update telemetry
                
                telemetry.nofAcceptWaitsForConnectionObject.increment()
                
                sleep (1) // Wait for 1 second, maybe something will be free by then
                
                loopCount += 1
                if loopCount > Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS) {
                    
                    let message = "Connection objects are no longer available (waited for \(Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS)) seconds)"
                    log.atLevelEmergency(id: 0, source: #file.source(#function, #line), message: message)
                    
                    httpConnectionPool.request()
                    
                    loopCount = 0
                }
            }
        }
        
        
        // =======================================
        // Wait for an incoming connection request
        // =======================================
        
        let acceptTelemetry = SwifterSockets.AcceptTelemetry()
        
        let result = SwifterSockets.acceptNoThrow(socket, abortFlag: &stopHttpServer, abortFlagPollInterval: 2.0, timeout: nil, telemetry: acceptTelemetry)
        
        switch result {
            
        case .TIMEOUT: // Should not happen, but if it does, try to continue
            
            log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "Unexpected timeout received... continuing")
            
            httpConnectionPool.free(connection!)
            
            
        case .ABORTED: // Time to end the server ...
            
            log.atLevelDebug(id: socket, source: SOURCE, message: "Accept was aborted, closing connection")

            httpConnectionPool.free(connection!)
            
            break ACCEPT_LOOP
            
            
        case .CLOSED: // Should be impossible
            
            log.atLevelCritical(id: socket, source: #file.source(#function, #line), message: "Accept closed unexpectedly (Bad File Descriptor)")
            
            httpConnectionPool.free(connection!)
            
            break ACCEPT_LOOP

            
        case let .ERROR(msg): // If there was an error, log the error message an abort the accept loop.

            log.atLevelCritical(id: socket, source: #file.source(#function, #line), message: msg)
            
            httpConnectionPool.free(connection!)

            break ACCEPT_LOOP
            
            
        case let .ACCEPTED(acceptedSocket): // If the connection request was accepted
        
            
            log.atLevelDebug(id: socket, source: SOURCE, message: "Connection request accepted")

            
            // ================================================
            // Set the socket option: prevent SIGPIPE exception
            // ================================================
            
            var optval = 1;
            
            let status = setsockopt(
                acceptedSocket,
                SOL_SOCKET,
                SO_NOSIGPIPE,
                &optval,
                socklen_t(sizeof(Int)))
            
            
            // Telemetry update
                
            telemetry.nofAcceptedHttpRequests.increment()
                
                
            // ====================================================================
            // Fill the connection object with the data from the connection request
            // ====================================================================
                
            connection!.timeOfAccept = NSDate()
            connection!.socket = acceptedSocket
            connection!.clientIp = acceptTelemetry.clientAddress ?? "Unknown"
            connection!.clientPort = acceptTelemetry.clientPort ?? "Unknown"
                
            if status == -1 {
                
                let strError = String(UTF8String: strerror(errno)) ?? "Unknown error code"
                connection!.closeConnection()
                log.atLevelEmergency(id: socket, source: #file.source(#function, #line), message: strError)
                
            } else {

                // ===================================================================
                // Start processing of the connection object in its own receiver queue
                // ===================================================================
                
                log.atLevelDebug(id: socket, source: SOURCE, message: "Dispatching request")

                dispatch_async(connection!.receiverQueue, {
                    
                    let buffer = UnsafeMutablePointer<UInt8>.alloc(Parameters.asInt(ParameterId.MAX_CLIENT_MESSAGE_SIZE))
                    let bufferPtr = UnsafeMutableBufferPointer(start: buffer, count: Parameters.asInt(ParameterId.MAX_CLIENT_MESSAGE_SIZE))

                    log.atLevelDebug(id: socket, source: SOURCE, message: "Starting Receiver Loop")

                    RECEIVER_LOOP: while (!stopHttpServer && !connection!.abortProcessing) {
                        
                        let result = SwifterSockets.receiveBytes(acceptedSocket, buffer: bufferPtr, timeout: Double(Parameters.asInt(ParameterId.HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT)), dataEndDetector: connection!, telemetry: nil)
                        
                        switch result {
                        case .BUFFER_FULL:
                            // A client should never send more than ParameterId.MAX_CLIENT_MESSAGE_SIZE in a single message
                            log.atLevelError(id: connection!.logId, source: #file.source(#function, #line), message: "Unexpected Buffer Full received")
                            break RECEIVER_LOOP
                            
                        case .CLIENT_CLOSED: // Normal
                            log.atLevelDebug(id: socket, source: SOURCE, message: "Stopping Receiver Loop, client closed")
                            break RECEIVER_LOOP

                        case .SERVER_CLOSED: // Not currently used
                            log.atLevelDebug(id: socket, source: SOURCE, message: "Stopping Receiver Loop, server closed")
                            break RECEIVER_LOOP

                        case .TIMEOUT: // Normal
                            log.atLevelDebug(id: socket, source: SOURCE, message: "Stopping Receiver Loop, timeout")
                            break RECEIVER_LOOP
                            
                        case let .ERROR(message: msg):
                            log.atLevelError(id: connection!.logId, source: #file.source(#function, #line), message: msg)
                            break RECEIVER_LOOP

                        case .READY:
                            log.atLevelDebug(id: socket, source: SOURCE, message: "Continuing Receiver Loop")
                            break
                        }
                    }
                    
                    log.atLevelDebug(id: socket, source: SOURCE, message: "Exiting Receiver Loop, closing connection")

                    // ***I*** (2)
                    
                    connection!.closeConnection()
                })
            }
        }
    } // End of ACCEPT_LOOP
    
    
    // Signal that the HTTP Accept loop is no longer running
    
    httpAcceptLoopIsActive = false
}