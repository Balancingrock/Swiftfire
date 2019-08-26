// =====================================================================================================================
//
//  File:       SFConnection.swift
//  Project:    Swiftfire
//
//  Version:    1.1.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2019 Marinus van der Lugt, All rights reserved.
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
// 1.1.0 - Changed server blacklist location
// 1.0.0 - Raised to v1.0.0, Removed old change log,
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
import Http
import BRUtils


/// Holds all data that is associated with an HTTP Connection.

public final class SFConnection: SwifterSockets.Connection {
    
    
    // A unique object id allows a correlation between statistics and the logfile (debug level)
    
    static var objectIdCount: Int = 0
    public let objectId: Int
    
    
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
    
    override public func prepare(for type: SwifterSockets.InterfaceAccess, remoteAddress address: String, options: [Option]) -> Bool {
        
        // In case of inactivity, close the connection.
        var localOptions = options
        localOptions.append(.receiverBufferSize(serverParameters.clientMessageBufferSize.value))
        localOptions.append(.transmitterTimeout(TimeInterval(serverParameters.httpResponseClientTimeout.value)))
        localOptions.append(.inactivityDetectionThreshold(Double(serverParameters.httpKeepAliveInactivityTimeout.value)/1000.0))
        localOptions.append(.inactivityAction({ (c: Connection) in c.closeConnection()}))
        
        guard super.prepare(for: type, remoteAddress: address, options: localOptions) else { return false }
    
        
        // Reinitialize internal data
        
        self.forwarder = nil
        self.headerData = nil
        self.httpRequest = nil
        self.maxSendBufferSize = nil
        self.abortProcessing = false
        self.mustClose = false
        self.bodyRemainingBytes = 0
        self.bodyChunk = nil
        
        return true
    }
    
    
    /// Any process that services a HTTP-Request must monitor this flag and close the connection (and terminate itself) when this flag is set to 'true'.
    
    /// This flag is used to achieve some kind of gracefull performance degradation in case of a system overload. An overload is characterized by an inability of Swiftfire to accept HTTP Connection requests in time (See AcceptConnectionRequests and the ap_MaxWaitForWaitingHttpConnections). When this condition arises the "abortProcessing" flag of the oldest connection will be set to 'true'. However nothing else will be done by AcceptConnectionRequests. The process that services the request must monitor this flag and terminate itself to free up this connection.
     
    /// It is of course possible that under very heavy loads this may result in an inability to complete any request. For now that is deemed acceptable, but this must be evaluated in a future release for improvement. ***I*** (1)
    
    public var abortProcessing = false
    
    
    /// The ID to be used when logging.
    
    public var logId: Int { return (objectId << 16) + Int(Int16(interface?.logId ?? -1)) }
    
    
    /// The number of times this connection object was allocated
    
    public var allocationCount: Int { return _allocationCount }
    private var _allocationCount: Int = 0
    public func incrementAllocationCounter() { _allocationCount += 1 }
    
    
    /// The time when this connection was accepted
    
    public var timeOfAccept: Int64 = 0

    
    /// The dispatch queue on which connections process the data from the client
    
    public let workerQueue = DispatchQueue(label: "Worker queue")
    
    
    /// The body receipt queue
    
    public let bodyQueue = DispatchQueue(label: "Http Request Body Queue")
    
    
    /// The file manager to be used for this connection object
    
    public let filemanager = FileManager()
    
    
    /// The size of the send buffer at OS level, set during socket accept
    
    public var maxSendBufferSize: Int?
    
    
    /// The received HTTP request
    
    fileprivate var httpRequest: Request?
    

    /// The data received from a client.

    public var headerData: Data?


    /// The socket on which to forward incoming requests from the client
    
    public var forwarder: Forwarder?
    
    
    // If set to 'true' the connection will (should) be closed asap
    
    public var mustClose = false
    
    
    override public func connectionWasClosed() {
    
        
        // Record the closing
        
        Log.atInfo?.log("Closing connection", id: logId, type: "SFConnection")
        
        
        // Free this connection object
        
        connectionPool.free(connection: self)
    }
    
    override public func transmitterReady(_ id: Int) {
        Log.atDebug?.log(id: logId, type: "SFConnection")
    }
    
    override public func transmitterTimeout(_ id: Int) {
        Log.atDebug?.log(id: logId, type: "SFConnection")
        super.transmitterTimeout(id)
    }
    
    override public func transmitterError(_ id: Int, _ message: String) {
        Log.atError?.log(message, id: logId, type: "SFConnection")
        super.transmitterError(id, message)
    }
    
    override public func transmitterClosed(_ id: Int) {
        Log.atDebug?.log(id: logId, type: "SFConnection")
        super.transmitterClosed(id)
    }
    
    
    // MARK: - SwifterSocketsReceiver protocol overrides
    
    override public func receiverClosed() {}
    
    override public func receiverError(_ message: String) {
        Log.atError?.log("Error event: \(message)", id: logId, type: "SFConnection")
    }
    
    override public func receiverLoop() -> Bool {
        return true // Continue receiving
    }
    
    
    /// Checks if a complete HTTP Request Header has been received. If it has, it will start an http worker on the workerqueue. The body data may not be completely received at that point.

    override public func processReceivedData(_ buffer: UnsafeBufferPointer<UInt8>) -> Bool {
    
        // If there is no httpRequest present, the incoming data must be examined for new requests
        
        if httpRequest == nil {
        
            
            // Append the new data to (potentially present) older data
            
            headerData = headerData ?? Data()
            headerData?.append(buffer)
            
            
            // Keep scanning for new requests until no request could be created
            
            while let request = Request(&headerData!) {
                
                Log.atDebug?.log("HTTP Request Header complete", id: logId, type: "SFConnection")

                
                // Log the header of the request
                
                if serverParameters.headerLoggingEnabled.value { headerLogger.record(connection: self, request: request) }
                
                
                // Check if the body is complete
                
                if request.body.count == request.contentLength {
                    
                    // The request is complete, dispatch it to the worker thread
                    
                    workerQueue.async() {
                        [request, unowned self] in
                        self.worker(request)
                    }
                    
                } else {
                
                    if request.body.count < request.contentLength {
                        
                        // The request is incomplete, still the worker thread is started, the worker thread must request the completion of the body.
                        
                        httpRequest = request
                        
                        bodyRemainingBytes = request.contentLength - request.body.count
                        
                        workerQueue.async() {
                            [request, unowned self] in
                            self.worker(request)
                        }
                        
                        break;
                        
                    } else {
                        
                        Log.atEmergency?.log("Coding error", id: logId, type: "SFConnection")
                    }
                }
            }
            
            return true // Continue receiver loop
        
        } else {
            
            
            // The current request is being processed by a worker thread, but its body is incomplete. Write the data to the chunk storage for the worker thread to fetch it.
            
            let chunk: Data
            
            if buffer.count >= bodyRemainingBytes {
                
                
                // The body will be completed with this chunk
                
                chunk = Data(bytes: buffer.baseAddress!, count: bodyRemainingBytes)
                
                
                // The worker thread will fetch the chunk in due time. If there is data left in the buffer after removing the chunk, then this data must be processed before the receiverLoop is started again.
                
                
                // See if there is any data left
                
                let remainingBufferBytes = buffer.count - bodyRemainingBytes

                
                // The previous httpRequest is now considered complete, even if the worker thread has not yet collected the last body chunk.
                
                bodyRemainingBytes = 0
                httpRequest = nil


                // Process any remaining data - if necessary
                
                if remainingBufferBytes > 0 {

                    // Recursive call to take care of possible new requests. Note that new requests will be put on the (serial) worker thread, i.e. any new requests will simply 'sit' until the current request has been dealth with.
                    
                    let newBuffer = UnsafeMutableRawPointer.allocate(byteCount: remainingBufferBytes, alignment: 1)
                    newBuffer.copyMemory(from: buffer.baseAddress!.advanced(by: bodyRemainingBytes), byteCount: remainingBufferBytes)
                    
                    _ = self.processReceivedData(UnsafeBufferPointer<UInt8>(start: newBuffer.assumingMemoryBound(to: UInt8.self), count: remainingBufferBytes))
                }

            } else {
                
                // All the new data is a part of the body currently beiing processed by a worker thread.
                
                chunk = Data(buffer)
            }
            

            // Note that making the chunk available has been kept to the last possible moment. This ensures that all currently received data was processed before the 'get chunk' operation can restart a new receiverLoop.
            
            bodyQueue.async {
                [chunk, unowned self] in
                if self.bodyChunk != nil {
                    Log.atEmergency?.log("Coding error", id: self.logId, type: "SFConnection")
                }
                self.bodyChunk = chunk
            }

            
            // Even if the bodyGetNextChunk starts a new receiverLoop, this is of no importance anymore. There is no more data or processing flow that could be disrupted. The current receiverLoop can simply terminate, even if another is already active.

            return false // Stop the receiver loop
        }
    }
    
    
    /// If not-nil, the next chunk of unprocessed body data.
    
    private var bodyChunk: Data?
    
    
    /// The bytes remaining to be received from the client for the current request body.
    
    private var bodyRemainingBytes = 0
    
    
    /// Returns immediately if body data was received before this call was made. If no data was received, it will return as soon as some data is received. If no data is received at all it will wait for a minimum of the time as specified in the timeout interval.
    ///
    /// This is potentially a blocking call that will suspend the current thread until data is received or the timeout interval elapses.
    ///
    /// The same data will never be offered twice. If the callee needs more data it must make sure to store the data itself as each received byte of body data will only be offered once through this call.
    ///
    /// The transfer of data from a client to the server is chunked: a clients sends data and the server must retrieve this data before the sever will accept new data from the same client. To achieve this, after each received block of data the
    ///
    /// - Parameters:
    ///   - timeout: This time is the maximum time to wait for data to be received.
    ///   - pollingInterval: Check every so much time of there was data received in the intervening time.
    ///
    /// - Returns: Nil if no data was available before the timeout interval elapsed or if the remaining bytes is zero (this constitues a code path error). Othewise a data object is returned with the data that was received so far.
    
    public func bodyGetNextChunk(timeout: TimeInterval, pollingInterval: TimeInterval) -> Data? {

        func pollForData() -> Data? {
            return bodyQueue.sync {
                () -> Data? in
                if bodyChunk != nil {
                    let b = bodyChunk
                    bodyChunk = nil
                    return b
                } else {
                    return nil
                }
            }
        }
        
        
        // The timeout specified in the call to this operation takes precedence over the inactivity timeout.
        
        incrementUsageCount()
        defer { decrementUsageCount() }
        
        let stopAfter = Date().addingTimeInterval(timeout).unixTime
        
        while true {
            if let chunk = pollForData() {
                startReceiverLoop()
                return chunk
            } else if Date().unixTime < stopAfter {
                _ = sleep(pollingInterval)
            } else {
                return nil
            }
        }
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
    
    if serverAdminDomain.blacklist.action(for: remoteAddress) != nil { return nil }
    
    
    // Find a free SFConnection object
    
    let (count, availableConnection) = connectionPool.allocateOrTimeout(serverParameters.maxWaitForPendingConnections.value)
    
    if count > 0 { serverTelemetry.nofAcceptWaitsForConnectionObject.increment() }
    
    guard let connection = availableConnection as? SFConnection else {
        Log.atEmergency?.log("SF Connection could not be allocated, client at \(remoteAddress) will be rejected", id: -1, type: "SFConnection")
        return nil
    }
    
    
    // Increase the allocation counter
    
    connection.incrementAllocationCounter()
    
    
    // Create log entry that can be used to associate this place in the logfile with data from the statistics.
    
    Log.atDebug?.log(
        "Allocating connection object \(connection.objectId) to client from address \(remoteAddress) on socket \(cType.logId) with allocation count \(connection.allocationCount)", id: Int(cType.logId), type: "SFConnection")
    
    
    // Configure the connection
    
    if !connection.prepare(for: cType, remoteAddress: remoteAddress, options: []) {
        Log.atEmergency?.log("Cannot prepare SF connection \(connection.objectId) for reuse", type: "SFConnection")
        connectionPool.free(connection: connection)
        return nil
    }
    
    connection.timeOfAccept = Date().javaDate
    
    
    // Telemetry update
    
    serverTelemetry.nofAcceptedHttpRequests.increment()
    
    
    return connection
}
