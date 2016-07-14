// =====================================================================================================================
//
//  File:       MonitoringAndControl.swift
//  Project:    Swiftfire
//
//  Version:    0.9.12
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


let mac = MonitoringAndControl()


// The queue on which Swiftfire will accept client connection requests

let acceptQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)


// When this variable is set to 'true' the monitoring and control loop will terminate and thereby terminate Swiftfire

var abortMacLoop: Bool = false


final class MonitoringAndControl: TransferToConsole {
    
    // Prevent more instantiations
    
    private init() {}
    

    // This queue is used for transfer of messages to a SwiftfireConsole

    private var transferQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

    
    // This is the socket used for communication with a console
    
    private var socket: Int32 = -1
    

    // The network target for the logger
    
    private var networkLogTarget = SwifterLog.NetworkTarget("","")
    
    
    /// Checks if the networkLogTarget contains two non-empty fields, and if so, tries to connect the logger to the target. After a connection attempt it will empty the fields.
    /// - Returns: True if the connection attempt was made, false otherwise.
    /// - Note: It does not report the sucess/failure of the connection attempt.
    
    private func conditionallySetNetworkLogTarget() -> Bool {
        if networkLogTarget.address.isEmpty { return false }
        if networkLogTarget.port.isEmpty { return false }
        log.connectToNetworkTarget(networkLogTarget)
        networkLogTarget.address = ""
        networkLogTarget.port = ""
        return true
    }
    
    
    /**
     Accepts and executes incoming M&C connection requests cq messages.

     - Parameter socketDescriptor: The socket descriptor of the socket on which the application is listening for M&C messages.
     */

    func acceptAndReceiveLoop(acceptOnSocket: Int32) {
        
        let SOURCE = "MonitoringAndControl.acceptAndReceiveLoop"
        
        
        // Check for autostart
        
        if Parameters.asBool(.AUTO_STARTUP) { doServerStartCommand() }
        
        
        // For the data received via the M&C server.
        
        let buffer = NSMutableData()
        
        
        // ================================
        // Start the "endless' command loop
        // ================================
        
        MAC_LOOP: while true {
            
            
            // =======================================
            // Wait for an incoming connection request
            // =======================================
            
            let acceptResult = SwifterSockets.acceptNoThrow(acceptOnSocket, abortFlag: &abortMacLoop, abortFlagPollInterval: 5, timeout: nil, telemetry: nil)
            
            switch acceptResult {
                
            case .ABORTED:
                
                // The stopAccepting variable has been set to true, the user wants to abort.
                
                break MAC_LOOP
                
                
            case let .ACCEPTED(aSocket):
                
                // A connection request has been honoured, start reading the request.
                
                socket = aSocket
                
                
            case .CLOSED:
                
                // An error occured, log it and try to ignore it
                
                log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Socket closed during accept")
                continue

                
            case let .ERROR(message):
                
                // An error occured, log it and try to ignore it
                
                log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Error during accept '\(message)'")
                continue
                
                
            case .TIMEOUT:
                
                // This should not be possible
                
                log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Programming error: A timeout occured on accept, this should not be possible")
                continue
                
            }
            
            log.atLevelNotice(id: acceptOnSocket, source: #file.source(#function, #line), message: "Accepted M&C connection")
            
            
            // =================================
            // Connection to console is now open
            // =================================
            
            toConsole = self
            
            
            // ========================
            // Receive data from client
            // ========================
            
            RECEIVE_LOOP: while socket >= 0 {
                
                
                // Expect JSON formatted messages
                
                let jsonEndDetector = SwifterSockets.JsonEndDetector()
                
                
                // Set the timeout to infinite if it is 0
                
                let ptimeout = Parameters.pdict[.MAC_INACTIVITY_TIMEOUT] as! Double
                let timeout: NSTimeInterval = (ptimeout == 0) ? Double.infinity : ptimeout
                
                
                // Start receiving
                
                let result = SwifterSockets.receiveNSData(socket, timeout: timeout, dataEndDetector: jsonEndDetector, telemetry: nil)
                
                
                // Determine what happend
                
                switch result {
                    
                case let .READY(data) where data is NSData:
                    
                    if (data as! NSData).length > 0 {
                        
                        // Add data to the data buffer
                        
                        buffer.appendData(data as! NSData)
                        
                        if Parameters.asBool(.DEBUG_MODE) {
                            log.atLevelDebug(
                                id: socket,
                                source: SOURCE,
                                message: "Received JSON message(s): \(String(data: data as! NSData, encoding: NSUTF8StringEncoding) ?? "Could not interpret received data as a string in utf8")")
                        }
                        
                        processReceivedData(buffer)
                    }
                    
                    
                case let .CLIENT_CLOSED(data) where data is NSData:
                    
                    if (data as! NSData).length > 0 {
                        
                        // Add data to the data buffer
                        
                        buffer.appendData(data as! NSData)
                        
                        if Parameters.asBool(.DEBUG_MODE) {
                            log.atLevelDebug(
                                id: socket,
                                source: SOURCE,
                                message: "Received JSON message(s): \(String(data: data as! NSData, encoding: NSUTF8StringEncoding) ?? "Could not interpret received data as a string in utf8")")
                        }
                        
                        processReceivedData(buffer)
                    }
                    
                    log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Monitoring and Control Connection closed by client")
                    
                    break RECEIVE_LOOP
                    
                    
                case .TIMEOUT:
                    
                    // A timeout occured, log a message
                    
                    log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Closing Monitoring and Control Connection due to inactivity")
                    
                    transferToConsole(ClosingMacConnection().json.description)
                    
                    sleep(1) // Give the transfer some time
                    
                    break RECEIVE_LOOP
                    
                    
                case let .ERROR(message: msg):
                    
                    // An error occured, log its message
                    
                    log.atLevelError(id: socket, source: #file.source(#function, #line), message: msg)
                    
                    
                case .BUFFER_FULL: fallthrough
                default:
                    
                    // These type of returns should be impossible, log that it happened and ignore
                    
                    log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Unknown error while receiving JSON message on the M&C interface")
                }
            }
            
            // ===========================================
            // Connection to console is no longer possible
            // ===========================================
            
            toConsole = nil

            
            // Close the socket on which the data was received.
            
            SwifterSockets.closeSocket(socket)
            
            socket = -1
            
        } // End ACCEPT_LOOP
    }
    
    
    /**
     This function extracts the json data from the received data, executes it and returns potential results back to the M&C Interface.
     - Parameter buffer: The buffer containing the received data.
     - Parameter socket:
     */
    
    private func processReceivedData(buffer: NSMutableData) {
        
        var json: VJson
        
        while buffer.length > 0 {
            
            do {
                
                // Note: If a JSON hierarchy is read, it is also removed from the buffer
                
                json = try VJson.parse(buffer)
                
                
                // Execute the command
                
                executeCommandInMessage(json)
                    
            } catch let error as VJson.Exception {
                
                if case let .REASON(_, incomplete, _) = error {
                    
                    if incomplete {
                        
                        break // This is not necessarily an error, perhaps the rest of the data has not arrived yet
                        
                    } else {
                        
                        log.atLevelError(id: socket, source: #file.source(#function, #line), message: error.description)
                    }
                    
                } else {
                    log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Logic error 1")
                }
                
                
                // Try to recover by emptying the buffer
                
                buffer.setData(NSData())
                
            } catch {
                
                log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Logic error 2")
                
                // Try to recover by emptying the buffer
                
                buffer.setData(NSData())
            }
        }
    }
    
    private func executeCommandInMessage(message: VJson) {
        
        if let command = ReadDomainTelemetryCommand(json: message) { doReadDomainTelemetryCommand(command) }
        else if let command = ReadServerParameterCommand(json: message) { Parameters.doReadServerParameterCommand(socket, command:command) }
        else if let command = ReadServerTelemetryCommand(json: message) { doReadServerTelemetryCommand(command) }
        else if let command = WriteServerParameterCommand(json: message) { Parameters.doWriteServerParameterCommand(socket, command: command) }
        else if let command = CreateDomainCommand(json: message) { doCreateDomainCommand(command) }
        else if let command = RemoveDomainCommand(json: message) { doRemoveDomainCommand(command) }
        else if let command = UpdateDomainCommand(json: message) { doUpdateDomainCommand(command) }
        else if let command = ReadDomainsCommand(json: message) { doReadDomainsCommand(command) }
        else if let command = ResetDomainTelemetryCommand(json: message) { doResetDomainTelemetryCommand(command) }
        else if let command = ReadStatisticsCommand(json: message) { command.execute() }
        else if let command = UpdatePathPartCommand(json: message) { command.execute() }
        else if let command = UpdateClientCommand(json: message) { command.execute() }
        else if ServerQuitCommand(json: message) != nil { doServerQuitCommand() }
        else if ServerStartCommand(json: message) != nil { doServerStartCommand() }
        else if ServerStopCommand(json: message) != nil { doServerStopCommand() }
        else if let command = DeltaCommand(json: message) { doDeltaCommand(command) }
        else if RestoreDomainsCommand(json: message) != nil { doRestoreDomainsCommand() }
        else if SaveDomainsCommand(json: message) != nil { doSaveDomainsCommand() }
        else if RestoreServerParametersCommand(json: message) != nil { doRestoreServerParametersCommand() }
        else if SaveServerParametersCommand(json: message) != nil { doSaveServerParametersCommand() }
        else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Could not create command from JSON code: \(message)")
        }
    }

    private func doResetDomainTelemetryCommand(command: ResetDomainTelemetryCommand) {
        
        guard let domain = domains.domainForName(command.domainName) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "No domain available with name = \(command.domainName)")
            return
        }
        
        domain.telemetry.reset()
        
        let reply = ReadDomainTelemetryReply(domainName: domain.name, domainTelemetry: domain.telemetry)
        
        transferToConsole(reply.json.description)
    }

    private func doReadDomainTelemetryCommand(command: ReadDomainTelemetryCommand) {
        
        guard let domain = domains.domainForName(command.domainName) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "No domain available with name = \(command.domainName)")
            return
        }
        
        let reply = ReadDomainTelemetryReply(domainName: domain.name, domainTelemetry: domain.telemetry)
        
        transferToConsole(reply.json.description)
    }
    
    private func doCreateDomainCommand(command: CreateDomainCommand) {
        
        // Check if this domain already exists
        guard domains.domainForName(command.domainName) == nil else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Domain name already exists (\(command.domainName as String))")
            return
        }
        
        let domain = Domain()
        domain.name = command.domainName
        
        domains.add(domain)
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Added new domain with \(domain))")
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Number of domains: \(domains.count)")
    }
    
    private func doRemoveDomainCommand(command: RemoveDomainCommand) {
        
        if domains.remove(command.domainName) {
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "REMOVE-DOMAIN Removed domain '\(command.domainName)')")
        } else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "REMOVE-DOMAIN NAME does not exist (\(command.domainName))")
        }
    }
    
    private func doUpdateDomainCommand(command: UpdateDomainCommand) {
        
        guard domains.contains(command.oldDomainName) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN no domain present with name \(command.oldDomainName)")
            return
        }
        
        if domains.update(command.oldDomainName, withDomain: command.newDomain) {
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN updated domain \(command.oldDomainName) to \(command.newDomain))")
            return
        } else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN failed")
        }
    }
    
    private func doReadDomainsCommand(command: ReadDomainsCommand) {
    
        let reply = ReadDomainsReply(domains: domains)
        
        transferToConsole(reply.json.description)
    }
    
    private func doServerQuitCommand() {
        
        // Stop the http server if it is running
        
        if httpServerIsRunning() {
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Stopping Swiftfire")
            
            stopAcceptAndDispatch()
        }
        
        
        // Wait a little to give the stop command time to run through the system
        
        sleep(5)
        
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Quitting Swiftfire")
        
        
        // Now quit the server
        
        abortMacLoop = true
    }
    
    private func doServerStartCommand() {

        
        // If the server is running, don't do anything
        
        if httpServerIsRunning() { return }
        
        
        // Start the server
        
        do {
            
            // Reset available connections
            
            httpConnectionPool.create()
            
            
            // Initialize the server
            
            let acceptSocket = try SwifterSockets.initServerOrThrow(port: Parameters.asString(.SERVICE_PORT_NUMBER), maxPendingConnectionRequest: Int32(Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS)))
            
            
            // Start accepting connection requests
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Starting Accept and Dispatch loop")
            
            dispatch_async(acceptQueue, {
                acceptAndDispatch(acceptSocket)
                log.atLevelNotice(id: acceptSocket, source: #file.source(#function, #line) + ".AcceptAndDispatch", message: "Stopped Accept and Dispatch loop")
                SwifterSockets.closeSocket(acceptSocket)
            })
            
        } catch let error as SwifterSockets.InitServerException {
            
            log.atLevelError(id: 0, source: #file.source(#function, #line), message: error.description)
            
        } catch {
            
            log.atLevelError(id: 0, source: #file.source(#function, #line), message: "Programming error")
        }
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "START completed")
    }
    
    private func doServerStopCommand() {
        
        // Only if the server is not already stopped
        
        if httpServerIsRunning() {
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Stopping Swiftfire")
            
            stopAcceptAndDispatch()
        }
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "STOP completed")
    }
    
    
    private func doReadServerTelemetryCommand(command: ReadServerTelemetryCommand) {
        
        switch command.telemetryItem {
            
            
        case .NOF_ACCEPTED_HTTP_REQUESTS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptedHttpRequests = \(serverTelemetry.nofAcceptedHttpRequests.intValue)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofAcceptedHttpRequests.intValue)
            
            transferToConsole(reply.json.description)
            

        case .NOF_ACCEPT_WAITS_FOR_CONNECTION_OBJECT:
             
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptWaitsForConnectionObject = \(serverTelemetry.nofAcceptWaitsForConnectionObject.intValue)")
             
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofAcceptWaitsForConnectionObject.intValue)
             
            transferToConsole(reply.json.description)
            
             
        case .NOF_HTTP_400_REPLIES:
             
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp400Replies = \(serverTelemetry.nofHttp400Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofHttp400Replies.intValue)

            transferToConsole(reply.json.description)
             
        case .NOF_HTTP_502_REPLIES:
             
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp502Replies = \(serverTelemetry.nofHttp502Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofHttp502Replies.intValue)
            
            transferToConsole(reply.json.description)
            
             
        case .SERVER_STATUS:
             
            let rs = httpServerIsRunning()
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, at_RunningStatus = \(rs)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: (rs ? "Running" : "Not Running"))
            
            transferToConsole(reply.json.description)
            
             
        case .SERVER_VERSION:
             
             log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_Version = \(Parameters.version)")
             
             let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: Parameters.version)

             transferToConsole(reply.json.description)
        }
    }

    
    private func doDeltaCommand(command: DeltaCommand) {
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "DELTA start")

        if command.delay == 0 { return }
        sleep(UInt32(min(command.delay, 10))) // Never more than 10 seconds
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "DELTA completed")
    }
    
    private func doRestoreDomainsCommand() {
        
        domains.restore()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "RESTORE_DOMAINS completed")
    }
    
    private func doRestoreServerParametersCommand() {
        
        Parameters.restore()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "RESTORE_PARAMETERS completed")
    }

    private func doSaveDomainsCommand() {
        
        domains.save()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "SAVE_DOMAINS completed")
    }

    private func doSaveServerParametersCommand() {
        
        Parameters.save()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "SAVE_PARAMETERS completed")
    }
    
/*    func transferMessage(json: VJson?) {
        if json == nil { return }
        if socket == -1 { return }
        dispatch_async(transferQueue, { self._transferMessage(json!.description)})
    }*/
    
    private func _transferMessage(message: String) {
        if socket == -1 { return }
        SwifterSockets.transmit(socket, string: message, timeout: 1.0, telemetry: nil)
    }
    
    func transferToConsole(message: String) -> Bool {
        if socket == -1 { return false }
        dispatch_async(transferQueue, { self._transferMessage(message)})
        return true
    }
}
