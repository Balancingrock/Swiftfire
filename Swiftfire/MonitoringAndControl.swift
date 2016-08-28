// =====================================================================================================================
//
//  File:       MonitoringAndControl.swift
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
// v0.9.14 - Upgraded to Xcode 8 beta 6
//         - Upgraded Command and Reply processing for Swiftfire resp SwiftfireConsole
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Added TransferToConsole protocol compliance
// v0.9.11 - Moved declaration of abortMacLoop and acceptQueue to here (from main.swift)
//         - Added ReadStatisticsCommand
//         - Updated for VJson 0.9.8
// v0.9.7  - Added HEADER_LOGGING_ENABLED, MAX_FILE_SIZE_FOR_HEADER_LOGGING, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
//         - Added missing HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT
//         - Moved doWriteServerParameterCommand and doReadServerParameterCommand processing to Parameters
//         - Added 1 second delay after transmitting closing-connection.
// v0.9.6  - Header update
//         - Added transmission of "ClosingMacConnection" upon timeout for the M&C connection
//         - Added ResetDomainTelemetry
//         - Merged Startup into Parameters
// v0.9.5  - Fixed bug that revented domain creation
// v0.9.4  - Changed according to new command & reply definitions
// v0.9.3  - Removed no longer existing server telemetry
// v0.9.0  - Initial release
// =====================================================================================================================


import Foundation


var mac = MonitoringAndControl()


protocol TransferToConsole {
    
    /// Attempts to transfer the given reply to the console. The SW using this call should be written such that success (or failure) becomes appearent to the user asap.
    /// - Note: There is no mechanism to guarantee successful transmission.
    
    func transfer(_ reply: MacMessage?)
}

var toConsole: TransferToConsole?


final class MonitoringAndControl: TransferToConsole {
    
    
    // Singleton

    fileprivate init() {
        commandFactories.append(ReadDomainsCommand.factory)
        commandFactories.append(ReadServerParameterCommand.factory)
        commandFactories.append(ReadServerTelemetryCommand.factory)
        commandFactories.append(WriteServerParameterCommand.factory)
        commandFactories.append(SaveServerParametersCommand.factory)
        commandFactories.append(RestoreServerParametersCommand.factory)
        commandFactories.append(CreateDomainCommand.factory)
        commandFactories.append(RemoveDomainCommand.factory)
        commandFactories.append(UpdateDomainCommand.factory)
        commandFactories.append(SaveDomainsCommand.factory)
        commandFactories.append(RestoreDomainsCommand.factory)
        commandFactories.append(ServerQuitCommand.factory)
        commandFactories.append(ServerStartCommand.factory)
        commandFactories.append(ServerStopCommand.factory)
        commandFactories.append(DeltaCommand.factory)
        commandFactories.append(ResetDomainTelemetryCommand.factory)
        commandFactories.append(ReadStatisticsCommand.factory)
        commandFactories.append(UpdatePathPartCommand.factory)
        commandFactories.append(UpdateClientCommand.factory)
        commandFactories.append(ModifyBlacklistCommand.factory)
        commandFactories.append(ReadBlacklistCommand.factory)
        commandFactories.append(SaveBlacklistCommand.factory)
        commandFactories.append(RestoreBlacklistCommand.factory)
    }
    
    
    // All possible commands

    private var commandFactories: Array<MacCommandFactory> = []
    
    //func addFactory(_ factory: MacCommandFactory) { commandFactories.append(factory) }
    
    
    // This queue is used for transfer of messages to a SwiftfireConsole

    private let transferQueue: DispatchQueue = DispatchQueue(
        label: "Transfer queue",
        qos: .utility,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil)

    
    // This is the socket used for communication with a console
    
    private var macSocket: Int32?
    
    
    /// Accepts and executes incoming M&C connection requests cq messages.

    func acceptAndReceiveLoop(onSocket acceptMacSocket: Int32) {

        
        // For the data received via the M&C server.
        
        var buffer = Data()
        
        
        // ================================
        // Start the "endless' command loop
        // ================================
        
        MAC_LOOP: while !quitSwiftfire {
            
            
            // =======================================
            // Wait for an incoming connection request
            // =======================================
            
            log.atLevelDebug(id: acceptMacSocket, source: "MacLoop Accept")
            let acceptResult = SwifterSockets.acceptNoThrow(onSocket: acceptMacSocket, abortFlag: &quitSwiftfire, abortFlagPollInterval: 5, timeout: nil, telemetry: nil)
            
            switch acceptResult {
                
            case .aborted:
                
                // The quitSwiftfire variable has been set to true, the user wants to abort.
                log.atLevelNotice(id: acceptMacSocket, source: "MacLoop Accept", message: "Aborted")

                break MAC_LOOP
                
                
            case let .accepted(aSocket):
                
                // A connection request has been honoured, start reading the request.
                log.atLevelNotice(id: acceptMacSocket, source: "MacLoop Accept", message: "Accepted")
                
                macSocket = aSocket
                
                
            case .closed:
                
                // An error occured, log it and repeat the accept statement
                log.atLevelError(id: acceptMacSocket, source: "MacLoop Accept", message: "Closed")

                continue

                
            case let .error(message):
                
                // An error occured, log it and repeat the accept statement
                log.atLevelError(id: acceptMacSocket, source: "MacLoop Accept", message: "Error: \(message)")
                
                continue
                
                
            case .timeout:
                
                // An error occured, log it and repeat the accept statement
                log.atLevelError(id: acceptMacSocket, source: "MacLoop Accept", message: "Programming Error:")
                
                continue
                
            }
            
            
            // =================================
            // Connection to console is now open
            // =================================
            
            toConsole = self
            
            
            // ========================
            // Receive data from client
            // ========================
            
            RECEIVE_LOOP: while true {
                
                
                
                // Expect JSON formatted messages
                
                let jsonEndDetector = SwifterSockets.JsonEndDetector()
                
                
                // Set the inactivity detectors
                
                let inactivityLimit = parameters.macInactivityTimeout
                var inactivitySigma: TimeInterval = 0
                let inactivityDelta: TimeInterval = 5
                
                
                // Start receiving
                
                let result = SwifterSockets.receiveData(fromSocket: macSocket!, timeout: inactivityDelta, dataEndDetector: jsonEndDetector, telemetry: nil)
                
                
                // Determine what happend
                
                switch result {
                    
                case let .ready(data) where data is Data:
                    
                    if (data as! Data).count > 0 {
                        
                        buffer.append(data as! Data)
                        
                        log.atLevelDebug(
                            id: macSocket!,
                            source: "MacLoop Receive",
                            message: "Ready: \(String(data: data as! Data, encoding: String.Encoding.utf8) ?? "Could not interpret received data as a string in utf8")")
                        
                        process(data: &buffer)
                        
                    } else {
                        log.atLevelNotice(id: macSocket!, source: "MacLoop Receive", message: "Ready with no data")
                    }
                    
                    
                    // There has been activity
                    
                    inactivitySigma = 0
                    
                    
                case let .clientClosed(data) where data is Data:
                    
                    if (data as! Data).count > 0 {
                        
                        buffer.append(data as! Data)
                        
                        log.atLevelDebug(
                            id: macSocket!,
                            source: "MacLoop Receive",
                            message: "Client Closed: \(String(data: data as! Data, encoding: String.Encoding.utf8) ?? "Could not interpret received data as a string in utf8")")
                        
                        process(data: &buffer)
                    }
                    
                    log.atLevelNotice(id: macSocket!, source: "MacLoop Receive", message: "Client Closed")
                    
                    break RECEIVE_LOOP
                    
                    
                case .timeout:
                    
                    // A timeout occured, this is part of the nominal process.
                    // Quit Swiftfire if requested
                    
                    if quitSwiftfire {
                    
                        log.atLevelNotice(id: macSocket!, source: "MacLoop Receive", message: "Timeout (Stopping MacLoop, sending ClosingMacConnection")
                    
                        transfer(message: ClosingMacConnection().json.description)
                    
                        sleep(1) // Give the transfer some time
                    
                        break RECEIVE_LOOP
                    }
                    
                    
                    // Check if the inactivity timeout has expired
                    
                    if inactivitySigma >= inactivityLimit {
                        
                        log.atLevelNotice(id: macSocket!, source: "MacLoop Receive", message: "Timeout (Stopping MacLoop, sending ClosingMacConnection")
                        
                        transfer(message: ClosingMacConnection().json.description)
                        
                        sleep(1) // Give the transfer some time

                        break RECEIVE_LOOP
                    }

                    
                    // Go again (no activity)
                    
                    inactivitySigma += inactivityDelta
                    
                    
                case let .error(message: msg):
                    
                    // An error occured, log its message
                    
                    log.atLevelError(id: macSocket!, source: "MacLoop Receive", message: "Error: \(msg)")
                    
                    
                    // Go again (does not count as activity)
                    
                    inactivitySigma += inactivityDelta

                    
                case .bufferFull:
                
                    // Should be impossible
                    
                    log.atLevelError(id: macSocket!, source: "MacLoop Receive", message: "Buffer Full (Programming Error")

                    
                    // Go again (counts as activity)
                    
                    inactivitySigma = 0
                    
                    
                case .serverClosed:
                    
                    // Should be impossible
                    
                    log.atLevelError(id: macSocket!, source: "MacLoop Receive", message: "Server Closed (Programming Error)")

                    
                    // Go again (does not count as activity)
                    
                    inactivitySigma += inactivityDelta

                    
                default:
                    
                    // Should be impossible
                    
                    switch result {
                    case .ready:
                        log.atLevelError(id: macSocket!, source: "MacLoop Receive", message: "Ready without Data (Programming Error")
                    case .clientClosed:
                        log.atLevelError(id: macSocket!, source: "MacLoop Receive", message: "Client Closed withour Data (Programming Error")
                    default:
                        log.atLevelError(id: macSocket!, source: "MacLoop Receive", message: "Default in default (Programming Error")
                    }
                    
                    
                    // Go again (does not count as activity)
                    
                    inactivitySigma += inactivityDelta
                }
            }
            
            // ===========================================
            // Connection to console is no longer possible
            // ===========================================
            
            toConsole = nil

            
            // Close the socket on which the data was received.
            
            SwifterSockets.closeSocket(macSocket)
            
            macSocket = nil
            
        } // End ACCEPT_LOOP
    }
    
    
    /**
     This function extracts the json data from the received data, executes it and returns potential results back to the M&C Interface.
     - Parameter buffer: The buffer containing the received data.
     - Parameter socket:
     */
    
    private func process(data: inout Data) {
        
        var json: VJson
        
        while data.count > 0 {
            
            do {
                
                // Note: If a JSON hierarchy is read, it is also removed from the buffer
                
                json = try VJson.parse(data: &data)
                
                
                var commandExecuted = false
                
                for factory in commandFactories {
                    if let command = factory(json) {
                        command.execute()
                        commandExecuted = true
                        break
                    }
                }
                
                if !commandExecuted {
                    log.atLevelError(id: -1, source: "MacLoop Execute Command", message: "Could not create command from JSON code: \(json)")
                }
                
            } catch let error as VJson.Exception {
                
                if case let .reason(_, incomplete, _) = error {
                    
                    if incomplete {
                        
                        break // This is not necessarily an error, perhaps the rest of the data has not arrived yet
                        
                    } else {
                        
                        log.atLevelError(id: -1, source: "MacLoop ProcessReceivedData", message: error.description)
                    }
                    
                } else {
                    log.atLevelError(id: -1, source: "MacLoop ProcessReceivedData", message: "Logic error 1")
                }
                
                
                // Try to recover by emptying the buffer
                
                data = Data()
                
            } catch {
                
                log.atLevelError(id: -1, source: "MacLoop ProcessReceivedData", message: "Logic error 2")
                
                // Try to recover by emptying the buffer
                
                data = Data()
            }
        }
    }
    
    func transfer(_ reply: MacMessage?) {
        guard let reply = reply else { return }
        if macSocket != nil {
            transferQueue.async() { self.transfer(message: reply.json.code)}
        }
    }

    private func transfer(message: String) {
        if let socket = macSocket {
            SwifterSockets.transmit(toSocket: socket, string: message, timeout: 1.0, telemetry: nil)
        }
    }
}
