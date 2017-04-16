// =====================================================================================================================
//
//  File:       SFConnection.swift
//  Project:    Swiftfire
//
//  Version:    0.10.6
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.6 - Renamed HttpHeader to HttpRequest
//        - Type of objectId changed from Int16 to Int
//        - Type of allocationCount changed from Int32 to Int
// 0.10.0 - Renamed to SFConnection because the connection can also be a HTTPS connection
// 0.9.18 - Header update
//        - Replaced log with Log?
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Changed return of http version number to fit the request header http version
//        - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Added "allocationCount", "objectId" and "objectIdCount"
// 0.9.6  - Header update
//        - Merged MAX_NOF_PENDING_CLIENT_MESSAGES with MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
// 0.9.5  - Added support for different MIME types of response
// 0.9.2  - Replaced sendXXXX functions with httpErrorResponseWithCode and httpResponseWithCode
// 0.9.0  - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Defines the support structure for a HTTP connection based on a SwifterSockets.Connection.
//
// =====================================================================================================================

import Foundation
import SwifterSockets
import SwifterLog
import SwiftfireCore


/// Holds all data that is associated with an HTTP Connection.

final class SFConnection: SwifterSockets.Connection {
    
    
    // A unique object id allows a correlation between statistics and the logfile (debug level)
    
    static var objectIdCount: Int = 0
    let objectId: Int
    
    
    // Designated initializer
    
    override init() {
        objectId = SFConnection.objectIdCount
        SFConnection.objectIdCount += 1
        super.init()
    }
    
    
    /// Prepares the object for (re)use.
    ///
    /// - Parameters:
    ///   - for: The connection type.
    ///   - remoteAddress: The address of the remote computer.
    ///   - options: The options to be set for the connection. The options inactivityDetectionThreshold and inactivityAction are used by this operation and should not be set externally.
    
    override func prepare(for type: SwifterSockets.InterfaceAccess, remoteAddress address: String, options: [Option]) -> Bool {
        
        // In case of inactivity, close the connection.
        var localOptions = options
        localOptions.append(.receiverBufferSize(parameters.clientMessageBufferSize))
        localOptions.append(.transmitterTimeout(parameters.httpResponseClientTimeout))
        localOptions.append(.inactivityDetectionThreshold(Double(parameters.httpKeepAliveInactivityTimeout)/1000.0))
        localOptions.append(.inactivityAction({ (c: Connection) in c.closeConnection()}))
        
        guard super.prepare(for: type, remoteAddress: address, options: localOptions) else { return false }
    
        
        // Reinitialize internal data
        
        self.forwarder = nil
        self.messageBuffer = Data()
        self.httpRequest = nil
        self.maxSendBufferSize = nil
        self.abortProcessing = false
        self.mustClose = false
        
        return true
    }
    
    
    /// Any process that services a HTTP-Request must monitor this flag and close the connection (and terminate itself) when this flag is set to 'true'.
    
    /// This flag is used to achieve some kind of gracefull performance degradation in case of a system overload. An overload is characterized by an inability of Swiftfire to accept HTTP Connection requests in time (See AcceptConnectionRequests and the ap_MaxWaitForWaitingHttpConnections). When this condition arises the "abortProcessing" flag of the oldest connection will be set to 'true'. However nothing else will be done by AcceptConnectionRequests. The process that services the request must monitor this flag and terminate itself to free up this connection.
     
    /// It is of course possible that under very heavy loads this may result in an inability to complete any request. For now that is deemed acceptable, but this must be evaluated in a future release for improvement. ***I*** (1)
    
    var abortProcessing = false
    
    
    /// The ID to be used when logging.
    
    var logId: Int32 { return interface?.logId ?? -1 }
    
    
    /// The number of times this connection object was allocated
    
    var allocationCount: Int { return _allocationCount }
    private var _allocationCount: Int = 0
    func incrementAllocationCounter() { _allocationCount += 1 }
    
    
    /// The time when this connection was accepted
    
    var timeOfAccept: Int64 = 0

    
    /// The dispatch queue on which connections process the data from the client
    
    let workerQueue = DispatchQueue(label: "Worker queue for SFConnection object")
    
    
    /// The file manager to be used for this connection object
    
    let filemanager = FileManager()
    
    
    /// The size of the send buffer at OS level, set during socket accept
    
    var maxSendBufferSize: Int?
    
    
    /// The received HTTP request
    
    var httpRequest: HttpRequest?
    

    /// The data received from a client.

    var messageBuffer = Data()


    /// The socket on which to forward incoming requests from the client
    
    var forwarder: Forwarder?
    
    
    // If set to 'true' the connection will (should) be closed asap
    
    var mustClose = false
    
    
    override func abortConnection() {
    
        
        // Record the closing
        
        Log.atInfo?.log(id: self.logId, source: #file.source(#function, #line), message: "Closing connection")
        
        
        // Close a potential forwarding socket
        
        self.forwarder = nil // deinit will close the target client
        
        
        // Clean out old stuff so a new client can use this object
        
        self.messageBuffer = Data()
        self.httpRequest = nil
        self.maxSendBufferSize = nil
        self.abortProcessing = false
        self.mustClose = false
        
        super.abortConnection()

        // Free this connection object
        connectionPool.free(connection: self)
    }
    
    override func transmitterReady(_ id: Int) {
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line))
    }
    
    override func transmitterTimeout(_ id: Int) {
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line))
        super.transmitterTimeout(id)
    }
    
    override func transmitterError(_ id: Int, _ message: String) {
        Log.atError?.log(id: logId, source: #file.source(#function, #line), message: message)
        super.transmitterError(id, message)
    }
    
    override func transmitterClosed(_ id: Int) {
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line))
        super.transmitterClosed(id)
    }
    
    
    // MARK: - SwifterSocketsReceiver protocol overrides
    
    override func receiverClosed() {}
    
    override func receiverError(_ message: String) {
        Log.atError?.log(id: logId, source: #file.source(#function, #line), message: "Error event: \(message)")
    }
    
    override func receiverLoop() -> Bool {
        return true // Continue receiving
    }
    
    
    /// This function stores the client data and checks if a complete HTTP Message has been received. If it has, it will start an http worker on the workerqueue, remove the message form the buffer and check for more messages.
    
    override func receiverData(_ buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        
        
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: "Received \(buffer.count) bytes")
        
        
        // Add the new data
        
        messageBuffer.append(buffer)
        
        
        // See if there are complete messages
        
        SCAN_FOR_COMPLETE_MESSAGES: while true {
            
            
            // If there is no request, try to read a header
            
            if httpRequest == nil {
                
                
                // See if the header is complete
                
                if let request = HttpRequest(data: messageBuffer) {
                    
                    
                    // Store the header for future reference
                    
                    httpRequest = request
                    
                    
                    // The header is complete
                    
                    Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: "HTTP Request Header complete")
                    
                    
                    // =======================
                    // The header is complete.
                    // =======================
                    
                    // Write the header to the log if so required
                    // Note: This is done now because there might be errors this request that would be missed if the log is not done at the earliest possible moment..
                    
                    if parameters.headerLoggingEnabled { headerLogger?.record(connection: self, request: httpRequest!) }
                }
            }
            
            
            // ====================================
            // If there is no header break the scan
            // ====================================
            
            if httpRequest == nil { break SCAN_FOR_COMPLETE_MESSAGES }
            
            
            // =========================
            // Check for a complete body
            // =========================
            
            let bodyLength = httpRequest!.contentLength
            let messageSize = bodyLength + httpRequest!.headerLength
            
            if messageSize > messageBuffer.count { break SCAN_FOR_COMPLETE_MESSAGES }
            
            
            // ====================
            // The body is complete
            // ====================
            
            
            // Create duplicates of the header and body and pass these to the worker. This way the worker has sole access to the data it works on. Note that the header is a class and can thus be copied as is if the local header is set to nil afterwards.
            
            let bodyRange = Range(uncheckedBounds: (lower: httpRequest!.headerLength, upper: messageSize))
            httpRequest!.payload = messageBuffer.subdata(in: bodyRange)
            
            Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: "HTTP Message Body complete, dispatching worker")
            
            
            // =====================
            // Start the Http Worker
            // =====================
            
            workerQueue.async() { [unowned self] in self.worker(self.httpRequest!) }
            
            
            // ===========================================================
            // Remove the message from the buffer and the header from self
            // ===========================================================
            
            let unprocessedRange = Range(uncheckedBounds: (lower: messageSize, upper: messageBuffer.count))
            messageBuffer = messageBuffer.subdata(in: unprocessedRange)
            
            httpRequest = nil
        }
        
        inactivityDetectionRestart()
        
        return true
    }
}


/// A connection factory for HTTP connections.
///
/// This factory recycles the connections that are available in the global connection pool.
///
/// - Parameters:
///   - cType: The interface to be used for this connection object.
///   - remoreAddress: The remote IP address of the client.
///
/// - Returns: A HttpConnection object if there is a free object available. Nil if all connection object are in use.

func httpConnectionFactory(_ cType: SwifterSockets.InterfaceAccess, _ remoteAddress: String) -> SwifterSockets.Connection? {
    
    
    // Exclude access for blacklisted clients (Server level blacklisting rejects the connection request before data is received, hence no HTML message will be sent as the client is -quite likely- not ready for it)
    
    if serverBlacklist.action(forAddress: remoteAddress) != nil { return nil }
    
    
    // Find a free SFConnection object
    
    let (count, availableConnection) = connectionPool.allocateOrTimeout(parameters.maxWaitForPendingConnections)
    
    if count > 0 { telemetry.nofAcceptWaitsForConnectionObject.increment() }
    
    guard let connection = availableConnection as? SFConnection else {
        Log.atEmergency?.log(id: -1, source: #file.source(#function, #line), message: "SF Connection could not be allocated, client at \(remoteAddress) will be rejected")
        return nil
    }
    
    
    // Increase the allocation counter
    
    connection.incrementAllocationCounter()
    
    
    // Create log entry that can be used to associate this place in the logfile with data from the statistics.
    
    Log.atDebug?.log(id: cType.logId, source: #file.source(#function, #line), message: "Allocating connection object \(connection.objectId) to client from address \(remoteAddress) on socket \(cType.logId) with allocation count \(connection.allocationCount)")
    
    
    // Configure the connection
    
    if !connection.prepare(for: cType, remoteAddress: remoteAddress, options: []) {
        Log.atEmergency?.log(id: -1, source: #file.source(#function, #line), message: "Cannot prepare SF connection \(connection.objectId) for reuse")
        connectionPool.free(connection: connection)
        return nil
    }
    
    connection.timeOfAccept = Date().javaDate
    
    
    // Telemetry update
    
    telemetry.nofAcceptedHttpRequests.increment()
    
    
    return connection
}
