// =====================================================================================================================
//
//  File:       HttpConnection.swift
//  Project:    Swiftfire
//
//  Version:    0.9.5
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
//
// v0.9.5 - Added support for different MIME types of response
// v0.9.2 - Replaced sendXXXX functions with httpErrorResponseWithCode and httpResponseWithCode
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = ((#file as NSString).lastPathComponent as NSString).stringByDeletingPathExtension


// To allow buffer capture for transmissions

private var bufferCapture: Int = 0


/// Holds all data that is associated with an HTTP Connection.

class HttpConnection {
    
    
    /**
     Any process that services a HTTP-Request must monitor this flag and close the connection (and terminate itself) when this flag is set to 'true'.
     
     This flag is used to achieve some kind of gracefull performance degradation in case of a system overload. An overload is characterized by an inability of Swiftfire to accept HTTP Connection requests in time (See AcceptConnectionRequests and the ap_MaxWaitForWaitingHttpConnections). When this condition arises the "abortProcessing" flag of the oldest connection will be set to 'true'. However nothing else will be done by AcceptConnectionRequests. The process that services the request must monitor this flag and terminate itself to free up this connection.
     
     It is of course possible that under very heavy loads this may result in an inability to complete any request. For now that is deemed acceptable, but this must be evaluated in a future release for improvement. ***I*** (1)
     */
    
    var abortProcessing = false
    
    
    /**
     The socket descriptor to use for sending and receiving. Once the connection is closed, the socket is set to nil.
     
     By default a connection is kept open until either the client closes it or the time out as specified in ap_HttpKeepAliveInactivityTimeout expires.
     
     This value is set when the client connection is accepted in AcceptAndDispatch. It is read and set to nil during either ReceiveAndDispatch or ProcessHttpMessage.
     */
    
    var socket: Int32?
    
    
    /**
     The ID to be used when logging. It is normally set to the socket id, but when the socket ID is no longer available it defaults to -1.
     */
    
    var logId: Int32 { return socket ?? -1 }
    
    
    /// The IP address of the client
    
    var clientIp = "Unknown"
    
    
    /// The port number of the client
    
    var clientPort = "Unknown"
    
    
    /// The time when this connection was accepted
    
    var timeOfAccept: NSDate = NSDate()
    
    
    /// Accessor for the first message completeness
    
    var firstMessageIsComplete: Bool { return messageBuffer.firstMessageIsComplete }
    
    
    /// The dispatch queue on wich the connections receive data from the client
    
    let receiverQueue = dispatch_queue_create("Receiver", DISPATCH_QUEUE_SERIAL)
    
    
    /// The dispatch queue on which connections transmit data to the client

    let transmitterQueue = dispatch_queue_create("Transmitter", DISPATCH_QUEUE_SERIAL)

    
    /// The dispatch queue on which connections process the data from the client
    
    let workerQueue = dispatch_queue_create("Worker", DISPATCH_QUEUE_SERIAL)
    
    
    /// The file manager to be used for this connection object
    
    let filemanager = NSFileManager()
    
    
    /// The size of the send buffer at OS level, set during socket accept
    
    var maxSendBufferSize: Int?

    
    
    // MARK: - For HttpConnection.DataEndDetector
    
    
    /// The decoded HTTP request header
    
    var httpHeader: HttpHeader?
    

    /// The data received from a client.

    var messageBuffer = HttpMessageBuffer(sizeInBytes: Parameters.asInt(ParameterId.MAX_CLIENT_MESSAGE_SIZE) * Parameters.asInt(ParameterId.MAX_NOF_PENDING_CLIENT_MESSAGES))

    
    // MARK: - For the forwarding function
    
    
    /// The socket on which to forward incoming requests from the client
    
    var forwardingSocket: Int32?
    
    
    // The queue on which received replies will be send to our client
    
    var forwardingReceiverQueue = dispatch_queue_create("ForwardingReceiverQueue", DISPATCH_QUEUE_SERIAL)

}


// Auxillary functions to transfer data

extension HttpConnection {

    
    /**
     Transfer the data pointed at by bytePointer to the client, for a number of count bytes.
     - Note: The data buffer contents is not copied and hence the callee should not manipuate its contents after calling this operation.
     - Returns: true if the transfer was successful, false if not.
     */

    func transferToClient(buffer: UInt8Buffer) {
        
        guard buffer.fill > 0 else { return }

        guard let socket = self.socket else {
            log.atLevelError(id: logId, source: #file.source(#function, #line), message: "Socket already closed")
            return
        }
        
        SwifterSockets.transmitAsync(
            transmitterQueue,
            socket: socket,
            buffer: buffer.ptr,
            timeout: Double(Parameters.asInt(ParameterId.HTTP_RESPONSE_CLIENT_TIMEOUT)),
            telemetry: nil,
            postProcessor: {
                
                (socket, telemetry) -> Void in
            
                guard let result = telemetry.result else {
                    log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Could not retrieve result from telemetry")
                    return
                }
                
                switch result {
                
                case .READY:
                    
                    log.atLevelDebug(id: socket, source: "HttpConnection.transferToClient", message: "Transferred \(telemetry.bytesTransferred ?? -1) bytes"); break
                
                    
                case .SERVER_CLOSED:
                    
                    log.atLevelDebug(id: socket, source: "HttpConnection.transferToClient", message: "Connection was closed by server"); break

                    
                case .CLIENT_CLOSED:
                    
                    log.atLevelDebug(id: socket, source: "HttpConnection.transferToClient", message: "Connection was closed by client"); break

                
                case .TIMEOUT:
                    
                    log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Timeout transmitting reply")
                
                    
                case let .ERROR(msg):
                    
                    log.atLevelError(id: socket, source: #file.source(#function, #line), message: msg)
                    bufferCapture = buffer.fill // Dummy assignment to enforce buffer capture
                }
        })
    }
    
    
    /// Close the connection and free this connection object.
    
    func closeConnection() {
        
        // To prevent closing a connection while there is a transmission going on, push the closing on the transmitter queue
        
        dispatch_async(transmitterQueue,  {
            
            [unowned self] in
            
            
            let id = self.logId
            
            
            // Close
            
            if self.socket != nil {
                SwifterSockets.closeSocket(self.socket!)
                self.socket = nil
            } else {
                log.atLevelInfo(id: id, source: #file.source(#function, #line), message: "Trying to close a closed connection")
                return
            }
            
            
            // Record the duration
            
            let now = NSDate()
            let duration = now.timeIntervalSinceDate(self.timeOfAccept)
            let message = "Duration from accept to close: \(duration * 1000.0) mSec"
            log.atLevelInfo(id: id, source: SOURCE + ".closeConnection", message: message)
            
            
            // Close a potential forwarding socket
            
            if self.forwardingSocket != nil { SwifterSockets.closeSocket(self.forwardingSocket) }
            self.forwardingSocket = nil
            
            
            // Clean out old stuff so a new client can use this object
            
            self.messageBuffer = HttpMessageBuffer(sizeInBytes: Parameters.asInt(ParameterId.MAX_CLIENT_MESSAGE_SIZE) * Parameters.asInt(ParameterId.MAX_NOF_PENDING_CLIENT_MESSAGES))
            self.httpHeader = nil
            self.maxSendBufferSize = nil
            self.abortProcessing = false
            
            
            // Free this connection object
            
            httpConnectionPool.free(self)
        })
    }
}


// Helpers for the creation of messages to the client

extension HttpConnection {

    /**
     Builds a buffer with a HTTP error response in it. The response will contain an error code, and can contain a specified error message as well.
     
     - Parameter code: The HTTP Response Code to be included in the header.
     - Parameter message: The HTML code to be included as visible message to the client. Note that any text should be enclosed in (at a minimum) a paragraph (<p>...</p>).
     
     - Returns: The buffer with the response.
     
     - Note: If the message contains characters that cannot be converted to an UTF8 string, then the response will not contain any visible data.
     */
    
    func httpErrorResponseWithCode(code: HttpResponseCode, andMessage message: String? = nil) -> UInt8Buffer {
        
        let message = message ?? "HTTP Request rejected with: \(code.rawValue)"
        
        let body =
            "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">" + CRLF +
                "<html><head><title>\(code.rawValue)</title></head>" + CRLF +
                "<body>\(message)</body></html>" + CRLF
        
        let bodyData = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) ?? NSData()
        
        let response = httpResponseWithCode(code, mimeType: MIME_TYPE_HTML, andBody: bodyData)
        
        return response
    }
    
    
    /**
     Builds a buffer with a HTTP response.
     
     - Parameter code: The code to be used in the header.
     - Parameter andBody: The body to be included.
     
     - Return: A buffer with the response.
     */
    
    func httpResponseWithCode(code: HttpResponseCode, mimeType: String, andBody body: NSData) -> UInt8Buffer {
        
        let header = "HTTP/1.1 " + code.rawValue + CRLF +
            "Date: \(NSDate())" + CRLF +
            "Server: Swiftfire/\(Parameters.version)" + CRLF +
            "Content-Type: \(mimeType); charset=UTF-8" + CRLF +
            "Content-Length: \(body.length)" + CRLFCRLF
        
        let headerData = header.dataUsingEncoding(NSUTF8StringEncoding)
        
        return UInt8Buffer(buffers: headerData, body)
    }
}