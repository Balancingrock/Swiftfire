// =====================================================================================================================
//
//  File:       SwiftfireMacInterface.swift
//  Project:    SwiftfireConsole
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// v0.9.14 - Improved reply processing
//         - Fixed bug that could corrupt received data
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Added TransferToSwiftfire protocol
// v0.9.11 - Merged into Swiftfire project
// v0.9.4  - Header update
//         - Added closeConnection()
// v0.9.2  - Simplified SwiftfireMacInterfaceDelegate to a dual func signature.
// v0.9.1  - Minor change to accomodate a change in SwifterLog
// v0.9.0  - Initial release
// =====================================================================================================================


import Foundation


var smi = SwiftfireMacInterface()


protocol TransferToSwiftfire {
    
    /// Attempts to transfer the given reply to the console. The SW using this call should be written such that success (or failure) becomes appearent to the user asap.
    /// - Note: There is no mechanism to guarantee successful transmission.
    
    func transfer(_ command: MacMessage?)
}

var toSwiftfire: TransferToSwiftfire?


final class SwiftfireMacInterface: NSObject, TransferToSwiftfire {
    

    // All reply factories must be registered at startup
    
    private var replyFactories: Array<MacReplyFactory> = []

    
    override init() {
        replyFactories.append(ReadDomainsReply.factory)
        replyFactories.append(ReadServerParameterReply.factory)
        replyFactories.append(ReadServerTelemetryReply.factory)
        replyFactories.append(ClosingMacConnection.factory)
        replyFactories.append(ReadStatisticsReply.factory)
        replyFactories.append(ReadBlacklistReply.factory)
    }
    
    
    /// Indicates if this M&C interface is operational
    
    var communicationIsEstablished: Bool { return (swiftfireSocket != nil) }
    

    /**
     Attempts to open a connection with the Swiftfire server. If the connection succeeds, it will also start the receiver loop.
     
     - Returns: True if the operation was successful. False otherwise.
     */
    
    @discardableResult
    func openConnectionToAddress(address: String, onPortNumber portNumber: String) -> Bool {
        
        return toServerQueue.sync() { [unowned self] () -> Bool in
            
            if self.swiftfireSocket == nil {
                
                let result = SwifterSockets.connectToServer(atAddress: address, atPort: portNumber)
                
                switch result {
                    
                case let .error(msg):
                    showErrorInKeyWindow(message: "Connection failed with message: \(msg)")
                    return false
                    
                case let .socket(socket):
                    self.swiftfireSocket = socket
                    self.startReceiverLoop()
                    return true
                }
                
            } else {
                
                return true
            }
        }
    }


    /**
     Closes the connection to the Swiftfire Server.
     */
    
    func closeConnection() {
        SwifterSockets.closeSocket(swiftfireSocket)
        swiftfireSocket = nil
        toSwiftfire = nil
    }
    
    func transfer(_ command: MacMessage?) {
        guard let command = command else { return }
        return transmit(message: command.json.code)
    }
    
    
    // The queues on which the communication attempts are made. It uses the same serial queue as the setParameter and sendCommand functions, hence all user interactions will be send in the sequence they were requested.
    
    private let toServerQueue = DispatchQueue(label: "to-server-queue")
    private let fromServerQueue = DispatchQueue(label: "from-server-queue")
    
    
    // The socket for the connection to the server
    
    private var swiftfireSocket: Int32?

    
    // The IP Address of the swiftfire server
    
    private var swiftfireIpAddress: String?
    
    
    // The port number of the monitoring and control interface of the Swiftfire server
    
    private var swiftfireMacPortNumber: String?

    
    // The time of the last transmission error
    
    private var lastTransmitErrorMessage: Date = Date.distantPast

    
    // Send a message to the server.
    
    private func transmit(message: String) {
        toServerQueue.async() {
            
            [unowned self] in
            
            if self.swiftfireSocket != nil {
                
                let transmitResult = SwifterSockets.transmit(toSocket:  self.swiftfireSocket!, string: message, timeout: 2.0, telemetry: nil)
                
                switch transmitResult {
                    
                case let .error(message: str):
                    
                    let message = "Error occured on transmission to Swiftfire M&C connection: \(str)"
                    log.atLevelError(id:  self.swiftfireSocket!, source: #file.source(#function, #line), message: message)
                    showErrorInKeyWindow(message: message)
                    self.closeConnection()
                    
                case .timeout:
                    
                    let message = "Timeout occured on Swiftfire M&C connection"
                    log.atLevelError(id:  self.swiftfireSocket!, source: #file.source(#function, #line), message: message)
                    showErrorInKeyWindow(message: message)
                    self.closeConnection()
                    
                    
                case .ready:
                    
                    log.atLevelDebug(id:  self.swiftfireSocket!, source: "SwiftfireMacInterface.transmitMessage", message: "Transmitted json code: \(message)")
                    
                    
                case .serverClosed:
                    
                    let message = "Swiftfire M&C connection unexpectedly closed"
                    log.atLevelError(id:  self.swiftfireSocket!, source: #file.source(#function, #line), message: message)
                    showErrorInKeyWindow(message: message)
                    self.closeConnection()
                    
                    
                case .clientClosed:
                    
                    let message = "Swiftfire M&C connection closed by Swiftfire"
                    log.atLevelError(id:  self.swiftfireSocket!, source: #file.source(#function, #line), message: message)
                    showErrorInKeyWindow(message: message)
                    self.closeConnection()
                }
                
            } else {
                
                if  self.lastTransmitErrorMessage.timeIntervalSinceNow < -1.0 {
                    let message = "Swiftfire server not connected"
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: message)
                    showErrorInKeyWindow(message: message)
                    self.lastTransmitErrorMessage = Date()
                }
            }
        }
    }
    
    
    private func startReceiverLoop() {
        
        fromServerQueue.async() { [unowned self] in
            
            
            // Make the transfer operation globally available
            
            toSwiftfire = self
            

            // The buffer to contain all received data
            
            var receivedData = Data()

            
            // Start receiving
            
            RECEIVER_LOOP: while self.swiftfireSocket != nil {
                
                let jsonEndDetector = SwifterSockets.JsonEndDetector()
                
                let result = SwifterSockets.receiveData(fromSocket: self.swiftfireSocket!, timeout: 5.0, dataEndDetector: jsonEndDetector, telemetry: nil)
                
                switch result {
                    
                case .bufferFull:
                    // This should not be possible
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unexpected BUFFER_FULL received")
                    break RECEIVER_LOOP
                    
                case let .clientClosed(data: data) where data is Data:
                    receivedData.append(data as! Data)
                    if receivedData.count > 0 { self.processReceivedData(data: &receivedData) }
                    self.closeConnection()
                    break RECEIVER_LOOP
                    
                case let .serverClosed(data: data) where data is Data:
                    receivedData.append(data as! Data)
                    if receivedData.count > 0 { self.processReceivedData(data: &receivedData) }
                    self.closeConnection()
                    break RECEIVER_LOOP
                    
                case let .error(message: message):
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Connection to Swiftfire closed with message: '\(message)'")
                    showErrorInKeyWindow(message: "Connection to Swiftfire closed with message: '\(message)'")
                    break RECEIVER_LOOP
                    
                case let .ready(data: data) where data is Data:
                    receivedData.append(data as! Data)
                    log.atLevelDebug(id: -1, source: "SwiftfireMacInterface.startReceiverLoop", message: "Received a total of \(receivedData.count) bytes")
                    self.processReceivedData(data: &receivedData)
                    log.atLevelDebug(id: -1, source: "SwiftfireMacInterface.startReceiverLoop", message: "Unprocessed: \(receivedData.count) bytes")
                    
                case .timeout:
                    // Simply try again...
                    break
                    
                default:
                    // This should not be possible
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unexpected 'default' executed")
                }
            }
            
            
            // Transmitter is no longer available either
            
            toSwiftfire = nil
        }
    }
    
    
    // Get a telemetry value from the server. Execute this function on the server queue only.
    
    private func processReceivedData(data: inout Data) {
        
        PROCESS_LOOP: while true {
            
            do {
                
                if data.count == 0 { break PROCESS_LOOP }
                
                let json = try VJson.parse(data: &data)
                
                if let logLineMessage = LogLineReply(json: json) {
                    
                    logLineMessage.process()
                    
                } else {
                    
                    log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Received: \(json.code)")

                    var replyProcessed = false

                    for factory in replyFactories {
                        if let reply = factory(json) {
                            // Dispatch all processing to the main queue, such that no GUI update conflict occur.
                            DispatchQueue.main.sync { reply.process() }
                            replyProcessed = true
                            break
                        }
                    }
                    
                    if !replyProcessed {
                        
                        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Message was not recognized: \(json.code)")
                        showErrorInKeyWindow(message: "Message from Swiftfire was not processed. See error log.")
                    }
                }
                
            } catch let error as VJson.Exception {
                
                if case let .reason(_, incomplete, msg) = error, !incomplete {
                    
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Error occured when parsing JSON message: \(msg)")
                    showErrorInKeyWindow(message: "Error parsing received JSON message from Swiftfire. See error log.")

                    // Try to recover by emptying all data
                    data.removeAll()
                }
                
                break PROCESS_LOOP
                
                
            } catch {
                
                let message = "Unknown error occured while creating VJson object"
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: message)
                showErrorInKeyWindow(message: message)

                // Try to recover by emptying all data
                data.removeAll()

                break PROCESS_LOOP
            }
        }
    }
}

