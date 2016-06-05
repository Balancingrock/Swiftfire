// =====================================================================================================================
//
//  File:       MonitoringAndControl.swift
//  Project:    Swiftfire
//
//  Version:    0.9.7
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
// v0.9.7 - Added HEADER_LOGGING_ENABLED, ACCESS_LOGGING_ENABLED, MAX_FILE_SIZE_FOR_HEADER_LOGGING,
//          MAX_FILE_SIZE_FOR_ACCESS_LOGGING, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
// v0.9.6 - Header update
//        - Added transmission of "ClosingMacConnection" upon timeout for the M&C connection
//        - Added ResetDomainTelemetry
//        - Merged Startup into Parameters
// v0.9.5 - Fixed bug that revented domain creation
// v0.9.4 - Changed according to new command & reply definitions
// v0.9.3 - Removed no longer existing server telemetry
// v0.9.0 - Initial release
// =====================================================================================================================


import Foundation


let mac = MonitoringAndControl()


final class MonitoringAndControl {
    
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
                    
                    transferMessage(ClosingMacConnection().json)
                    
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
                
                json = try VJson.createJsonHierarchy(buffer)
                
                
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
        else if let command = ReadServerParameterCommand(json: message) { doReadServerParameterCommand(command) }
        else if let command = ReadServerTelemetryCommand(json: message) { doReadServerTelemetryCommand(command) }
        else if let command = WriteServerParameterCommand(json: message) { doWriteServerParameterCommand(command) }
        else if let command = CreateDomainCommand(json: message) { doCreateDomainCommand(command) }
        else if let command = RemoveDomainCommand(json: message) { doRemoveDomainCommand(command) }
        else if let command = UpdateDomainCommand(json: message) { doUpdateDomainCommand(command) }
        else if let command = ReadDomainsCommand(json: message) { doReadDomainsCommand(command) }
        else if let command = ResetDomainTelemetryCommand(json: message) { doResetDomainTelemetryCommand(command) }
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
        
        transferMessage(reply.json)
    }

    private func doReadDomainTelemetryCommand(command: ReadDomainTelemetryCommand) {
        
        guard let domain = domains.domainForName(command.domainName) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "No domain available with name = \(command.domainName)")
            return
        }
        
        let reply = ReadDomainTelemetryReply(domainName: domain.name, domainTelemetry: domain.telemetry)
        
        transferMessage(reply.json)
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
        
        transferMessage(reply.json)
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
    
    private func doReadServerParameterCommand(command: ReadServerParameterCommand) {
        
        switch command.parameter {
            
        case .DEBUG_MODE:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, debugMode = \(Parameters.asBool(.DEBUG_MODE))")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: Parameters.asBool(.DEBUG_MODE))
            
            transferMessage(reply.json)
            
            
        case .SERVICE_PORT_NUMBER:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, servicePortNumber = \(Parameters.asString(.SERVICE_PORT_NUMBER))")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: Parameters.asString(.SERVICE_PORT_NUMBER))
            
            transferMessage(reply.json)
            
            
        case .CLIENT_MESSAGE_BUFFER_SIZE:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, clientMessageBufferSize = \(Parameters.asInt(.CLIENT_MESSAGE_BUFFER_SIZE))")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: Parameters.asInt(.CLIENT_MESSAGE_BUFFER_SIZE))
            
            transferMessage(reply.json)
            
            
        case .MAX_NOF_ACCEPTED_CONNECTIONS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_MaxNumberOfAcceptedConnections = \(Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS))")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS))
            
            transferMessage(reply.json)
            
            
        case .MAX_NOF_PENDING_CONNECTIONS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_MaxNumberOfPendingConnections = \(Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS))")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS))
            
            transferMessage(reply.json)
            
            
        case .MAX_WAIT_FOR_PENDING_CONNECTIONS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_MaxWaitForPendingConnections = \(Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS))")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS))
            
            transferMessage(reply.json)
            
            
        case .ASL_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.aslFacilityRecordAtAndAboveLevel = \(log.aslFacilityRecordAtAndAboveLevel.rawValue)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: log.aslFacilityRecordAtAndAboveLevel.rawValue)
            
            transferMessage(reply.json)
            
            
        case .FILE_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.logfileRecordAtAndAboveLevel = \(log.fileRecordAtAndAboveLevel.rawValue)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: log.fileRecordAtAndAboveLevel.rawValue)
            
            transferMessage(reply.json)

            
        case .STDOUT_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.stdoutPrintAtAndAboveLevel = \(log.stdoutPrintAtAndAboveLevel.rawValue)")

            let reply = ReadServerParameterReply(parameter: command.parameter, value: log.stdoutPrintAtAndAboveLevel.rawValue)
            
            transferMessage(reply.json)
            
            
        case .CALLBACK_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.callbackTransmitAtAndAboveLevel = \(log.callbackAtAndAboveLevel.rawValue)")

            let reply = ReadServerParameterReply(parameter: command.parameter, value: log.callbackAtAndAboveLevel.rawValue)
            
            transferMessage(reply.json)
            
            
        case .NETWORK_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTransmitAtAndAboveLevel = \(log.networkTransmitAtAndAboveLevel.rawValue)")

            let reply = ReadServerParameterReply(parameter: command.parameter, value: log.networkTransmitAtAndAboveLevel.rawValue)
            
            transferMessage(reply.json)
            
            
        case .NETWORK_LOG_TARGET_ADDRESS:
            
            let dest = log.networkTarget?.address ?? "Not set"
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTarget.address = \(dest)")

            let reply = ReadServerParameterReply(parameter: command.parameter, value: dest)
            
            transferMessage(reply.json)

            
        case .NETWORK_LOG_TARGET_PORT:
            
            let port = log.networkTarget?.port ?? "0"
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTarget.port = \(port)")

            let reply = ReadServerParameterReply(parameter: command.parameter, value: port)
            
            transferMessage(reply.json)
            
            
        case .AUTO_STARTUP:
            
            let value = Parameters.asBool(.AUTO_STARTUP)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, AUTO_STARTUP = \(value)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: value)
            
            transferMessage(reply.json)

        
        case .MAC_PORT_NUMBER:
            
            let port = Parameters.asString(.MAC_PORT_NUMBER)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, MAC_PORT_NUMBER = \(port)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: port)
            
            transferMessage(reply.json)
            
            
        case .LOGFILE_MAX_NOF_FILES:
            
            let nof = log.logfileMaxNumberOfFiles
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.logfileMaxNumberOfFiles = \(nof)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: nof)
            
            transferMessage(reply.json)

            
        case .LOGFILE_MAX_SIZE:
            
            let nof = Int(log.logfileMaxSizeInBytes)
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.logfileMaxSizeInBytes = \(nof)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: nof)
            
            transferMessage(reply.json)
            
            
        case .LOGFILES_FOLDER:
            
            let folder = log.logfileDirectoryPath ?? ""
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.logfileDirectoryPath = \(folder)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: folder as String)
            
            transferMessage(reply.json)
            
            
        case .MAX_FILE_SIZE_FOR_HEADER_LOGGING:
            
            let value = Parameters.asInt(.MAX_FILE_SIZE_FOR_HEADER_LOGGING)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, MAX_FILE_SIZE_FOR_HEADER_LOGGING = \(value)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: value)
            
            transferMessage(reply.json)
            
            
        case .HEADER_LOGGING_ENABLED:
            
            let value = Parameters.asBool(.HEADER_LOGGING_ENABLED)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, HEADER_LOGGING_ENABLED = \(value)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: value)
            
            transferMessage(reply.json)
            
            
        case .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            let value = Parameters.asBool(.FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE = \(value)")
            
            let reply = ReadServerParameterReply(parameter: command.parameter, value: value)
            
            transferMessage(reply.json)
        }
    }
    
    private func doReadServerTelemetryCommand(command: ReadServerTelemetryCommand) {
        
        switch command.telemetryItem {
            
            
        case .NOF_ACCEPTED_HTTP_REQUESTS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptedHttpRequests = \(serverTelemetry.nofAcceptedHttpRequests.intValue)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofAcceptedHttpRequests.intValue)
            
            transferMessage(reply.json)
            

        case .NOF_ACCEPT_WAITS_FOR_CONNECTION_OBJECT:
             
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptWaitsForConnectionObject = \(serverTelemetry.nofAcceptWaitsForConnectionObject.intValue)")
             
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofAcceptWaitsForConnectionObject.intValue)
             
            transferMessage(reply.json)
            
             
        case .NOF_HTTP_400_REPLIES:
             
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp400Replies = \(serverTelemetry.nofHttp400Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofHttp400Replies.intValue)

            transferMessage(reply.json)
             
        case .NOF_HTTP_502_REPLIES:
             
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp502Replies = \(serverTelemetry.nofHttp502Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: serverTelemetry.nofHttp502Replies.intValue)
            
            transferMessage(reply.json)
            
             
        case .SERVER_STATUS:
             
            let rs = httpServerIsRunning()
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, at_RunningStatus = \(rs)")
            
            let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: (rs ? "Running" : "Not Running"))
            
            transferMessage(reply.json)
            
             
        case .SERVER_VERSION:
             
             log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_Version = \(Parameters.version)")
             
             let reply = ReadServerTelemetryReply(item: command.telemetryItem, value: Parameters.version)

             transferMessage(reply.json)
        }
    }

    private func doWriteServerParameterCommand(command: WriteServerParameterCommand) {
        
        switch command.parameter {
            
        case .ASL_LOGLEVEL:
            
            guard let level = command.intValue, let newLevel = SwifterLog.Level(rawValue: level) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value should be in range 0..8, found \(command.intValue)")
                return
            }
            
            if newLevel != log.aslFacilityRecordAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(log.aslFacilityRecordAtAndAboveLevel) to \(newLevel)")
                log.aslFacilityRecordAtAndAboveLevel = newLevel
                Parameters.pdict[.ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL] = level
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new level same as present level: \(newLevel)")
            }
            
            
        case .DEBUG_MODE:
            
            guard let debugMode = command.boolValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a BOOL value")
                return
            }
            
            if debugMode != Parameters.asBool(.DEBUG_MODE) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asBool(.DEBUG_MODE)) to \(debugMode)")
                Parameters.pdict[.DEBUG_MODE] = debugMode
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new level same as present level: \(Parameters.asBool(.DEBUG_MODE))")
            }
            
            
        case .FILE_LOGLEVEL:
            
            guard let intLevel = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.fileRecordAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(log.fileRecordAtAndAboveLevel) to \(newLevel)")
                log.fileRecordAtAndAboveLevel = newLevel
                Parameters.pdict[.FILE_RECORD_AT_AND_ABOVE_LEVEL] = intLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new level same as present level: \(newLevel)")
            }
            
            
        case .CALLBACK_LOGLEVEL:
            
            guard let intLevel = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.callbackAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(log.callbackAtAndAboveLevel) to \(newLevel)")
                log.callbackAtAndAboveLevel = newLevel
                Parameters.pdict[.CALLBACK_AT_AND_ABOVE_LEVEL] = intLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new level same as present level: \(newLevel)")
            }
            
            
        case .CLIENT_MESSAGE_BUFFER_SIZE:
            
            guard let dbSize = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            if dbSize != Parameters.asInt(.CLIENT_MESSAGE_BUFFER_SIZE) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asInt(.CLIENT_MESSAGE_BUFFER_SIZE)) to \(dbSize)")
                Parameters.pdict[.CLIENT_MESSAGE_BUFFER_SIZE] = dbSize
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as present value: \(dbSize)")
            }
            
            
        case .MAX_NOF_ACCEPTED_CONNECTIONS:
            
            guard let maxConn = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            if maxConn != Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS)) to \(maxConn)")
                Parameters.pdict[.MAX_NOF_ACCEPTED_CONNECTIONS] = maxConn
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as present value: \(maxConn)")
            }
            
            
        case .MAX_NOF_PENDING_CONNECTIONS:
            
            guard let maxPend = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            if maxPend != Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS)) to \(maxPend)")
                Parameters.pdict[.MAX_NOF_PENDING_CONNECTIONS] = Int32(maxPend)
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as present value: \(maxPend)")
            }
            
            
        case .MAX_WAIT_FOR_PENDING_CONNECTIONS:
            
            guard let maxWait = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            if maxWait != Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS)) to \(maxWait)")
                Parameters.pdict[.MAX_WAIT_FOR_PENDING_CONNECTIONS] = maxWait
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as present value: \(maxWait)")
            }
            
            
        case .NETWORK_LOG_TARGET_ADDRESS:
            
            networkLogTarget.address = command.value
            
            let localCopy: SwifterLog.NetworkTarget = networkLogTarget
            Parameters.pdict[.NETWORK_LOGTARGET_IP_ADDRESS] = command.value
            
            if conditionallySetNetworkLogTarget() {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) setting the network target to: \(localCopy.address):\(localCopy.port)")
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updated target address, waiting for port.")
            }
            
            
        case .NETWORK_LOG_TARGET_PORT:
            
            networkLogTarget.port = command.value
            
            let localCopy: SwifterLog.NetworkTarget = networkLogTarget
            Parameters.pdict[.NETWORK_LOGTARGET_PORT_NUMBER] = command.value
            
            if conditionallySetNetworkLogTarget() {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) setting the network target to: \(localCopy.address):\(localCopy.port)")
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updated target port, waiting for address.")
            }
            
            
        case .NETWORK_LOGLEVEL:
            
            guard let intLevel = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.networkTransmitAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(log.networkTransmitAtAndAboveLevel) to \(newLevel)")
                log.networkTransmitAtAndAboveLevel = newLevel
                Parameters.pdict[ParameterId.NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL] = intLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new level same as present level: \(newLevel)")
            }
            
            
        case .SERVICE_PORT_NUMBER:
            
            let portStr = command.value
            
            if portStr != Parameters.asString(.SERVICE_PORT_NUMBER) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asString(.SERVICE_PORT_NUMBER)) to \(portStr)")
                Parameters.pdict[.SERVICE_PORT_NUMBER] = portStr
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as present value: \(portStr)")
            }
            
            
        case .STDOUT_LOGLEVEL:
            
            guard let intLevel = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-STDOUT_LOGLEVEL should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-STDOUT_LOGLEVEL new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.stdoutPrintAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-STDOUT_LOGLEVEL updating from \(log.stdoutPrintAtAndAboveLevel) to \(newLevel)")
                log.stdoutPrintAtAndAboveLevel = newLevel
                Parameters.pdict[ParameterId.STDOUT_PRINT_AT_AND_ABOVE_LEVEL] = intLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-STDOUT_LOGLEVEL new level same as present level: \(newLevel)")
            }
            
            
        case .AUTO_STARTUP:
            
            guard let newValue = command.boolValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-AUTO_STARTUP should contain a BOOL value")
                return
            }
            
            let oldValue = Parameters.asBool(ParameterId.AUTO_STARTUP)
            
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-AUTO_STARTUP updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.AUTO_STARTUP] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-AUTO_STARTUP new value same as present value: \(newValue)")
            }
            
            
        case .MAC_PORT_NUMBER:
            
            let newValue = command.value
            
            let oldValue = Parameters.asString(ParameterId.MAC_PORT_NUMBER)
            
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAC_PORT_NUMBER updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.MAC_PORT_NUMBER] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAC_PORT_NUMBER new value same as present value: \(newValue)")
            }

            
        case .LOGFILES_FOLDER:
            
            let newValue = command.value
            
            let oldValue = log.logfileDirectoryPath ?? ""
            
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-LOGFILES_FOLDER updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.LOGFILES_FOLDER] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-LOGFILES_FOLDER new value same as present value: \(newValue)")
            }
            
            
        case .LOGFILE_MAX_SIZE:
            
            let newValue = command.intValue
            
            let oldValue = Int(log.logfileMaxSizeInBytes)
            
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-LOGFILES_MAX_SIZE updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.LOGFILE_MAX_SIZE] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-LOGFILES_MAX_SIZE new value same as present value: \(newValue)")
            }

            
        case .LOGFILE_MAX_NOF_FILES:
            
            let newValue = command.intValue
            
            let oldValue = log.logfileMaxNumberOfFiles
            
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-LOGFILE_MAX_NOF_FILES updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.LOGFILE_MAX_NOF_FILES] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-LOGFILE_MAX_NOF_FILES new value same as present value: \(newValue)")
            }

            
        case .MAX_FILE_SIZE_FOR_HEADER_LOGGING:
            
            let newValue = command.intValue
            let oldValue = Parameters.asInt(.MAX_FILE_SIZE_FOR_HEADER_LOGGING)
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_FILE_SIZE_FOR_HEADER_LOGGING updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.MAX_FILE_SIZE_FOR_HEADER_LOGGING] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_FILE_SIZE_FOR_HEADER_LOGGING new value same as present value: \(newValue)")
            }
            
            
        case .HEADER_LOGGING_ENABLED:
            
            guard let newValue = command.boolValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-HEADER_LOGGING_ENABLED should contain a BOOL value")
                return
            }
            let oldValue = Parameters.asBool(.HEADER_LOGGING_ENABLED)
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-HEADER_LOGGING_ENABLED updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.HEADER_LOGGING_ENABLED] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-HEADER_LOGGING_ENABLED new value same as present value: \(newValue)")
            }
            
            
        case .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            guard let newValue = command.boolValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE should contain a BOOL value")
                return
            }
            let oldValue = Parameters.asBool(.FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE)
            if oldValue != newValue {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE updating from \(oldValue) to \(newValue)")
                Parameters.pdict[ParameterId.FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE new value same as present value: \(newValue)")
            }
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
    
    func transferMessage(json: VJson?) {
        if json == nil { return }
        if socket == -1 { return }
        dispatch_async(transferQueue, { self._transferMessage(json!)})
    }
    
    private func _transferMessage(json: VJson) {
        if socket == -1 { return }
        SwifterSockets.transmit(socket, string: json.description, timeout: 1.0, telemetry: nil)
    }
}
