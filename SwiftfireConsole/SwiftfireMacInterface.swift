// =====================================================================================================================
//
//  File:       SwiftfireMacInterface.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.12
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/SwiftfireConsole
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
// v0.9.12 - Added TransferToSwiftfire protocol
// v0.9.11 - Merged into Swiftfire project
// v0.9.4  - Header update
//         - Added closeConnection()
// v0.9.2  - Simplified SwiftfireMacInterfaceDelegate to a dual func signature.
// v0.9.1  - Minor change to accomodate a change in SwifterLog
// v0.9.0  - Initial release
// =====================================================================================================================


import Foundation


protocol SwiftfireMacInterfaceDelegate {
    
    /**
     Asks the delegate to display the given error message.
     
     - Parameter swiftfireMacInterface: The originating interface.
     - Parameter message: The error message to be displayed.
     
     - Note: This operation is initiated from a thread that runs asynchrously. It would be prudent to implement a mechanism that only updates the GUI from an end-of-runloop observer.
     */
    
    func swiftfireMacInterface(_ swiftfireMacInterface: SwiftfireMacInterface, message: String)
    
    
    /**
     Allows the delegate to process the received data from a Swiftfire server.
     
     - Parameter swiftfireMacInterface: The originating interface.
     - Parameter reply: The VJson object as received from the server.
     
     - Note: This operation is initiated from a thread that runs (asynchrously) in the background. It is presumed that this will occur while the runloop is paused, but this cannot be guaranteed. It would be prudent to implement a mechanism that only updates a GUI from an end-of-runloop observer.
     */
    
    func swiftfireMacInterface(_ swiftfireMacInterface: SwiftfireMacInterface, reply: VJson)
}


class SwiftfireMacInterface: NSObject, TransferToSwiftfire {

    // The queue for synchronization
    
    let syncQueue = DispatchQueue(label: "SwiftfireMacInterface Sync Queue", attributes: [.serial, .qosUtility])
    
    
    /// Indicates if this M&C interface is operational
    
    var communicationIsEstablished: Bool { return (swiftfireSocket != nil) }
    

    /**
     Attempts to open a connection with the Swiftfire server. If the connection succeeds, it will also start the receiver loop that listens for telemetry and logline updates. If the delegate is set, the delegate will be called for telemetry and logline updates.
     
     - Returns: True if the operation was successful. False otherwise.
     */
    
    @discardableResult
    func openConnectionToAddress(address: String, onPortNumber portNumber: String) -> Bool {
        
        return syncQueue.sync() { [unowned self] () -> Bool in
            
            if self.swiftfireSocket == nil {
                
                let result = SwifterSockets.connectToServer(atAddress: address, atPort: portNumber)
                
                switch result {
                    
                case let .error(msg):
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Connection failed with message: \(msg)")
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
    }
    
    
    /**
     This function attempts to send JSON formatted messages to the Swiftfire server.
  
     - Parameter messages: A list of VJson messages to be sent.
     
     - Returns: True if the status flag "communicationIsEstablished" is set, false otherwise.
     */

    @discardableResult
    func sendMessages(messages: [VJson?]) -> Bool {
        
        let textMessages = messages.flatMap(){ $0?.description }
        
        return sendMessages(messages: textMessages)
    }
    
    @discardableResult
    func transferToSwiftfire(message: String) -> Bool {
        return sendMessages(messages: [message])
    }
    
    /**
     This function attempts to send string formatted messages to the Swiftfire server.
     
     - Parameter address: The IP address of the Swiftfire server.
     - Parameter port: The port number of the Swiftfire server that it is listening for M&C messages.
     - Parameter messages: A list of VJson messages to be sent.
     - Parameter errorDisplay: Some object that can display error messages to the end-user.
     
     - Returns: True if the transfer attempt will be made (asynchronously). False if not. Note that in fact the status flag "communicationIsEstablished" is returned.
     */
    
    @discardableResult
    func sendMessages(messages: [String]) -> Bool {
        
        return syncQueue.sync() { [unowned self] () -> Bool in
            
            
            // Check if a connection has been established
            
            if self.swiftfireSocket != nil {
                
                
                // Transmit the messages
                
                for message in messages {
                    self.toServerQueue.async() {
                        self.transmitMessage(message: message)
                    }
                }
            }
            
            return (self.swiftfireSocket != nil)
        }
    }


    /**
     Initializes a new object with the given delegate. Without a delegate it is only possible to send messages. Without a delegate no errors, telemetry or remote logging will be available.
     
     - Parameter delegate: The delegate.
     */
    
    init(delegate: SwiftfireMacInterfaceDelegate?) {
        self.delegate = delegate
    }
    
    
    // The delegate for the error messages and telemetry updates
    
    private var delegate: SwiftfireMacInterfaceDelegate?
    
    
    // The queues on which the communication attempts are made. It uses the same serial queue as the setParameter and sendCommand functions, hence all user intercations will be send in the sequence they were requested.
    
    private let toServerQueue = DispatchQueue(label: "to-server-queue", attributes: [.serial, .qosUtility])
    private let fromServerQueue = DispatchQueue(label: "from-server-queue", attributes: [.serial, .qosUtility])
    
    
    // The socket for the connection to the server
    
    private var swiftfireSocket: Int32?

    
    // The IP Address of the swiftfire server
    
    private var swiftfireIpAddress: String?
    
    
    // The port number of the monitoring and control interface of the Swiftfire server
    
    private var swiftfireMacPortNumber: String?

    
    // Send a message to the server. Execute this function on the server queue only.
    
    private func transmitMessage(message: String) {
        
        if swiftfireSocket != nil {
        
            let transmitResult = SwifterSockets.transmit(toSocket: swiftfireSocket!, string: message, timeout: 2.0, telemetry: nil)
            
            switch transmitResult {
                
            case let .error(message: str):
                
                let message = "Error occured on transmission to Swiftfire M&C connection: \(str)"
                log.atLevelError(id: swiftfireSocket!, source: #file.source(#function, #line), message: message)
                if let d = delegate { d.swiftfireMacInterface(self, message: message) }
                closeConnection()
                
            case .timeout:
                
                let message = "Timeout occured on Swiftfire M&C connection"
                log.atLevelError(id: swiftfireSocket!, source: #file.source(#function, #line), message: message)
                if let d = delegate { d.swiftfireMacInterface(self, message: message) }
                closeConnection()
                
                
            case .ready:
                
                log.atLevelDebug(id: swiftfireSocket!, source: "SwiftfireMacInterface.transmitMessage", message: "Transmitted json code: \(message)")
            

            case .serverClosed:

                let message = "Swiftfire M&C connection unexpectedly closed"
                log.atLevelError(id: swiftfireSocket!, source: #file.source(#function, #line), message: message)
                if let d = delegate { d.swiftfireMacInterface(self, message: message) }
                closeConnection()

                
            case .clientClosed:
                
                let message = "Swiftfire M&C connection closed by Swiftfire"
                log.atLevelError(id: swiftfireSocket!, source: #file.source(#function, #line), message: message)
                if let d = delegate { d.swiftfireMacInterface(self, message: message) }
                closeConnection()
            }
            
        } else {
            
            if lastTransmitErrorMessage.timeIntervalSinceNow < -1.0 {
                let message = "Swiftfire server not connected"
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: message)
                if let d = delegate { d.swiftfireMacInterface(self, message: message) }
                lastTransmitErrorMessage = NSDate()
            }
        }
    }

    private var lastTransmitErrorMessage: NSDate = NSDate.distantPast
    
    
    // Starts the receiver loop
    
    private func startReceiverLoop() {
        
        fromServerQueue.async() { [unowned self] in
            
            
            // Make the transfer operation globally available
            
            toSwiftfire = self
            
            
            // Start receiving
            
            RECEIVER_LOOP: while self.swiftfireSocket != nil {
            
                let jsonEndDetector = SwifterSockets.JsonEndDetector()
                var receivedData = Data()
                
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
                    if let d = self.delegate { d.swiftfireMacInterface(self, message: "Connection to Swiftfire closed with message: '\(message)'") }
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
        
        let SOURCE = "SwiftfireMacInterface.processReceivedData"
        
        PROCESS_LOOP: while true {
            
            var json: VJson?
            
            do {
                
                if data.count == 0 { break PROCESS_LOOP }
                
                // Create the JSON hierarchy
                
                json = try VJson.parse(data: &data)
                
            } catch let error as VJson.Exception {
                
                if case let .reason(_, incomplete, msg) = error {
                    
                    if !incomplete {
                        
                        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Error occured when parsing JSON message: \(msg)")
                        
                        if let d = delegate { d.swiftfireMacInterface(self, message: "Error occured when parsing JSON message: \(msg)") }
                    }
                }
                
                break PROCESS_LOOP
                
                
            } catch {
                
                let message = "Unknown error occured while creating VJson object"
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: message)
                if let d = delegate { d.swiftfireMacInterface(self, message: message) }
                
                break PROCESS_LOOP
            }
            
            
            log.atLevelDebug(id: -1, source: SOURCE, message: "Received JSON code \(json!)")
            
            
            if let d = self.delegate { d.swiftfireMacInterface(self, reply: json!) }
        }
    }
}

