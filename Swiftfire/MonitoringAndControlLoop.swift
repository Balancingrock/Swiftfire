// =====================================================================================================================
//
//  File:       MonitoringAndControl.swift
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
        
        if startup.autostart {
            // Simulate start message
            if let startCommand = MacDef.Command.START.jsonHierarchyWithValue(nil) {
                doCommandStart(startCommand)
            }
        }
        
        
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
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Expected an JSON OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Expected 1 child, found \(message.nofChildren)")
            return
        }
        
        guard let commandName = message.arrayValue?[0].nameValue else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Command name not available")
            return
        }

        guard let command = MacDef.Command(rawValue: commandName) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Unknown command name \(commandName)")
            return
        }
        
        switch command {
        case .CREATE: doCommandCreate(message)
        case .QUIT: doCommandQuit(message)
        case .READ:
            
            guard let readResult = doCommandRead(message) else { return }
            let json = VJson.createJsonHierarchy()
            json.addChild(readResult)
            transferMessage(json)
            
        case .REMOVE: doCommandRemove(message)
        case .START: doCommandStart(message)
        case .STOP: doCommandStop(message)
        case .UPDATE: doCommandUpdate(message)
        case .WRITE: doCommandWrite(message)
        case .DELTA: doCommandDelta(message)
        case .RESTORE_DOMAINS: doCommandRestoreDomains(message)
        case .RESTORE_PARAMETERS: doCommandRestoreParameters(message)
        case .SAVE_DOMAINS: doCommandSaveDomains(message)
        case .SAVE_PARAMETERS: doCommandSaveParameters(message)
        }
    }
    
    private func doCommandCreate(message: VJson) {
        
        guard let domain = Domain(json: message[MacDef.Command.CREATE.rawValue][MacDef.CommandCreate.DOMAIN.rawValue]) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "CREATE contains an invalid DOMAIN spec '\(message[MacDef.CommandCreate.DOMAIN.rawValue])'")
            return
        }
        
        // Check if this domain already exists
        guard !domains.contains(domain.name as String) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "CREATE-DOMAIN NAME already exists (\(domain.name as String))")
            return
        }
        
        // Check if the prefix 'www' must be used, and if so, then check if that domain is already exists
        if domain.wwwIncluded.boolValue {
            if domains.contains("www." + (domain.name as String) as String) {
                log.atLevelError(id: socket, source: #file.source(#function, #line), message: "CREATE-DOMAIN www.NAME already exists (\("www." + (domain.name as String)))")
                return
            }
        }
        
        domains.add(domain)
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Added new domain with \(domain))")
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Number of domains: \(domains.count)")

    }
    
    private func doCommandRemove(message: VJson) {
        
        guard let name = message[MacDef.Command.REMOVE.rawValue][MacDef.CommandCreate.DOMAIN.rawValue]["Name"].stringValue?.lowercaseString else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "REMOVE should contain a DOMAIN with a NAME of the STRING type '\(message)'")
            return
        }
        
        if domains.remove(name) {
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "REMOVE-DOMAIN Removed domain '\(name)')")
        } else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "REMOVE-DOMAIN NAME does not exist (\(name))")
        }
    }
    
    private func doCommandUpdate(message: VJson) {
        
        guard let oldDomain = Domain(json: message[MacDef.Command.UPDATE.rawValue][MacDef.CommandUpdate.OLD.rawValue][MacDef.CommandUpdate.DOMAIN.rawValue]) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN could not create old domain from path UPDATE.OLD.DOMAIN")
            return
        }
        
        guard let newDomain = Domain(json: message[MacDef.Command.UPDATE.rawValue][MacDef.CommandUpdate.NEW.rawValue][MacDef.CommandUpdate.DOMAIN.rawValue]) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN could not create new domain from path UPDATE.NEW.DOMAIN")
            return
        }
        
        guard domains.contains(oldDomain.name) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN no domain present with name \(oldDomain.name)")
            return
        }
        
        if domains.update(oldDomain.name, withDomain: newDomain) {
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN updated domain \(oldDomain.name) to \(newDomain))")
            return
        } else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "UPDATE-DOMAIN failed")
        }
    }
    
    private func doCommandQuit(message: VJson) {
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "QUIT should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "QUIT should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.QUIT.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "QUIT should contain a NULL value (with the name Quit)")
            return
        }
        
        
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
    
    private func doCommandStart(message: VJson) {
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "START should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "START should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.START.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "START should contain a NULL value (with the name Start)")
            return
        }
        
        
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
    
    private func doCommandStop(message: VJson) {
      
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "STOP should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "STOP should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.STOP.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "STOP should contain a NULL value (with the name Stop)")
            return
        }
        
        
        // Only if the server is not already stopped
        
        if httpServerIsRunning() {
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Stopping Swiftfire")
            
            stopAcceptAndDispatch()
        }
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "STOP completed")
    }
    
    private func doCommandRead(message: VJson) -> VJson? {
        
        guard let parameterName = message[MacDef.Command.READ.rawValue].stringValue else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "READ should contain a STRING as parameter id")
            return nil
        }

        guard let parameter = MacDef.Parameter(rawValue: parameterName) else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "READ contains unknown parameter id: '\(message[MacDef.Command.READ.rawValue].stringValue)'")
            return nil
        }
        
        switch parameter {
            
        case .DEBUG_MODE:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, debugMode = \(Parameters.asBool(.DEBUG_MODE))")
            return parameter.jsonWithValue(Parameters.asBool(.DEBUG_MODE))

            
        case .SERVICE_PORT_NUMBER:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, servicePortNumber = \(Parameters.asString(.SERVICE_PORT_NUMBER))")
            return parameter.jsonWithValue(Parameters.asString(.SERVICE_PORT_NUMBER))
            
            
        case .MAX_NOF_PENDING_CLIENT_MESSAGES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, maxNofPendingClientMessages = \(Parameters.asInt(.MAX_NOF_PENDING_CLIENT_MESSAGES))")
            return parameter.jsonWithValue(Parameters.asInt(.MAX_NOF_PENDING_CLIENT_MESSAGES))
            
            
        case .MAX_CLIENT_MESSAGE_SIZE:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, maxClientMessageSize = \(Parameters.asInt(.MAX_CLIENT_MESSAGE_SIZE))")
            return parameter.jsonWithValue(Parameters.asInt(.MAX_CLIENT_MESSAGE_SIZE))
            
            
        case .MAX_NOF_ACCEPTED_CONNECTIONS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_MaxNumberOfAcceptedConnections = \(Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS))")
            return parameter.jsonWithValue(Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS))
            
            
        case .MAX_NOF_PENDING_CONNECTIONS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_MaxNumberOfWaitingConnections = \(Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS))")
            return parameter.jsonWithValue(Int(Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS)))
            
            
        case .MAX_WAIT_FOR_PENDING_CONNECTIONS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_MaxWaitForWaitingConnections = \(Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS))")
            return parameter.jsonWithValue(Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS))
            
            
        case .NOF_ACCEPTED_CLIENTS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptedHttpRequests = \(telemetry.nofAcceptedHttpRequests)")
            return parameter.jsonWithValue(telemetry.nofAcceptedHttpRequests.intValue)
            
            
        case .NOF_RECEIVE_TIMEOUTS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofReceiveTimeouts = \(telemetry.nofReceiveTimeouts)")
            return parameter.jsonWithValue(telemetry.nofReceiveTimeouts.intValue)
            
            
        case .NOF_RECEIVE_ERRORS:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofReceiveErrors = \(telemetry.nofReceiveErrors)")
            return parameter.jsonWithValue(telemetry.nofReceiveErrors.intValue)
            
            
        case .NOF_HTTP_400_REPLIES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp400Replies = \(telemetry.nofHttp400Replies)")
            return parameter.jsonWithValue(telemetry.nofHttp400Replies.intValue)
            
            
        case .NOF_HTTP_404_REPLIES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp404Replies = \(telemetry.nofHttp404Replies)")
            return parameter.jsonWithValue(telemetry.nofHttp404Replies.intValue)
            
            
        case .NOF_HTTP_500_REPLIES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp500Replies = \(telemetry.nofHttp500Replies)")
            return parameter.jsonWithValue(telemetry.nofHttp500Replies.intValue)
            
            
        case .NOF_HTTP_501_REPLIES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp501Replies = \(telemetry.nofHttp501Replies)")
            return parameter.jsonWithValue(telemetry.nofHttp501Replies.intValue)
            
            
        case .NOF_HTTP_505_REPLIES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp505Replies = \(telemetry.nofHttp505Replies)")
            return parameter.jsonWithValue(telemetry.nofHttp505Replies.intValue)
            
            
        case .NOF_SUCCESSFUL_HTTP_REPLIES:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, telemetry.nofSuccessfulHttpReplies = \(telemetry.nofSuccessfulHttpReplies)")
            return parameter.jsonWithValue(telemetry.nofSuccessfulHttpReplies.intValue)
            
            
        case .SERVER_STATUS:
            
            let rs = httpServerIsRunning()
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, at_RunningStatus = \(rs)")
            return parameter.jsonWithValue(rs ? "Running" : "Not Running")
            
            
        case .VERSION_NUMBER:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, ap_Version = \(Parameters.version)")
            return parameter.jsonWithValue(Parameters.version)
            
            
        case .ASL_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.aslFacilityRecordAtAndAboveLevel = \(log.aslFacilityRecordAtAndAboveLevel.rawValue)")
            return parameter.jsonWithValue(log.aslFacilityRecordAtAndAboveLevel.rawValue)
            
            
        case .FILE_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.logfileRecordAtAndAboveLevel = \(log.fileRecordAtAndAboveLevel.rawValue)")
            return parameter.jsonWithValue(log.fileRecordAtAndAboveLevel.rawValue)
            
            
        case .STDOUT_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.stdoutPrintAtAndAboveLevel = \(log.stdoutPrintAtAndAboveLevel.rawValue)")
            return parameter.jsonWithValue(log.stdoutPrintAtAndAboveLevel.rawValue)
            
            
        case .CALLBACK_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.callbackTransmitAtAndAboveLevel = \(log.callbackAtAndAboveLevel.rawValue)")
            return parameter.jsonWithValue(log.callbackAtAndAboveLevel.rawValue)
            
            
        case .NETWORK_LOGLEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTransmitAtAndAboveLevel = \(log.networkTransmitAtAndAboveLevel.rawValue)")
            return parameter.jsonWithValue(log.networkTransmitAtAndAboveLevel.rawValue)
            
            
        case .NETWORK_LOG_TARGET_ADDRESS:
            
            let dest = log.networkTarget?.address ?? "Not set"
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTarget.address = \(dest)")
            return parameter.jsonWithValue(dest)

            
        case .NETWORK_LOG_TARGET_PORT:
            
            let port = log.networkTarget?.port ?? "0"
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTarget.port = \(port)")
            return parameter.jsonWithValue(port)
            
            
        case .DOMAINS:
            
            return parameter.jsonWithValue(domains)
        }
    }
    
    
    private func doCommandWrite(message: VJson) {
        
        guard let subject = message[MacDef.Command.WRITE.rawValue].arrayValue?[0] else {
            log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE could not extract parameter name")
            return
        }
        
        guard let parameter = MacDef.Parameter.create(subject.nameValue) else {
            log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE contains unknown parameter id: '\(message.stringValue)'")
            return
        }
        
        switch parameter {
            
        case .ASL_LOGLEVEL:
            
            guard let intLevel = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-ASL_LOGLEVEL should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-ASL_LOGLEVEL new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.aslFacilityRecordAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-ASL_LOGLEVEL updating from \(log.aslFacilityRecordAtAndAboveLevel) to \(newLevel)")
                log.aslFacilityRecordAtAndAboveLevel = newLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-ASL_LOGLEVEL new level same as present level: \(newLevel)")
            }
            
            
        case .DEBUG_MODE:
            
            guard let debugMode = subject.boolValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-DEBUG_MODE should contain a BOOL value")
                return
            }
            
            if debugMode != Parameters.asBool(.DEBUG_MODE) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-DEBUG_MODE updating from \(Parameters.asBool(.DEBUG_MODE)) to \(debugMode)")
                Parameters.pdict[.DEBUG_MODE] = debugMode
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-DEBUG_MODE new level same as present level: \(Parameters.asBool(.DEBUG_MODE))")
            }
            
            
        case .FILE_LOGLEVEL:
            
            guard let intLevel = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-FILE_LOGLEVEL should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-FILE_LOGLEVEL new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.fileRecordAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-FILE_LOGLEVEL updating from \(log.fileRecordAtAndAboveLevel) to \(newLevel)")
                log.fileRecordAtAndAboveLevel = newLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-FILE_LOGLEVEL new level same as present level: \(newLevel)")
            }
            
            
        case .CALLBACK_LOGLEVEL:
            
            guard let intLevel = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-CALLBACK_LOGLEVEL should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-CALLBACK_LOGLEVEL new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.callbackAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-CALLBACK_LOGLEVEL updating from \(log.callbackAtAndAboveLevel) to \(newLevel)")
                log.callbackAtAndAboveLevel = newLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-CALLBACK_LOGLEVEL new level same as present level: \(newLevel)")
            }
            
            
        case .MAX_NOF_PENDING_CLIENT_MESSAGES:
            
            guard let dbSize = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_PENDING_CLIENT_MESSAGES should contain a NUMBER value")
                return
            }
            
            if dbSize != Parameters.asInt(.MAX_NOF_PENDING_CLIENT_MESSAGES) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_PENDING_CLIENT_MESSAGES updating from \(Parameters.asInt(.MAX_NOF_PENDING_CLIENT_MESSAGES)) to \(dbSize)")
                Parameters.pdict[.MAX_NOF_PENDING_CLIENT_MESSAGES] = dbSize
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_PENDING_CLIENT_MESSAGES new value same as present value: \(dbSize)")
            }
            
            
        case .MAX_CLIENT_MESSAGE_SIZE:
            
            guard let dbSize = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_CLIENT_MESSAGE_SIZE should contain a NUMBER value")
                return
            }
            
            if dbSize != Parameters.asInt(.MAX_CLIENT_MESSAGE_SIZE) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_CLIENT_MESSAGE_SIZE updating from \(Parameters.asInt(.MAX_CLIENT_MESSAGE_SIZE)) to \(dbSize)")
                Parameters.pdict[.MAX_CLIENT_MESSAGE_SIZE] = dbSize
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_CLIENT_MESSAGE_SIZE new value same as present value: \(dbSize)")
            }
            
            
        case .MAX_NOF_ACCEPTED_CONNECTIONS:
            
            guard let maxConn = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_ACCEPTED_CONNECTIONS should contain a NUMBER value")
                return
            }
            
            if maxConn != Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_ACCEPTED_CONNECTIONS updating from \(Parameters.asInt(.MAX_NOF_ACCEPTED_CONNECTIONS)) to \(maxConn)")
                Parameters.pdict[.MAX_NOF_ACCEPTED_CONNECTIONS] = maxConn
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_ACCEPTED_CONNECTIONS new value same as present value: \(maxConn)")
            }
            
            
        case .MAX_NOF_PENDING_CONNECTIONS:
            
            guard let maxPend = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_PENDING_CONNECTIONS should contain a NUMBER value")
                return
            }
            
            if maxPend != Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_PENDING_CONNECTIONS updating from \(Parameters.asInt(.MAX_NOF_PENDING_CONNECTIONS)) to \(maxPend)")
                Parameters.pdict[.MAX_NOF_PENDING_CONNECTIONS] = Int32(maxPend)
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_NOF_PENDING_CONNECTIONS new value same as present value: \(maxPend)")
            }
            
            
        case .MAX_WAIT_FOR_PENDING_CONNECTIONS:
            
            guard let maxWait = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_WAIT_FOR_PENDING_CONNECTIONS should contain a NUMBER value")
                return
            }
            
            if maxWait != Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_WAIT_FOR_PENDING_CONNECTIONS updating from \(Parameters.asInt(.MAX_WAIT_FOR_PENDING_CONNECTIONS)) to \(maxWait)")
                Parameters.pdict[.MAX_WAIT_FOR_PENDING_CONNECTIONS] = maxWait
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-MAX_WAIT_FOR_PENDING_CONNECTIONS new value same as present value: \(maxWait)")
            }
            
            
        case .NETWORK_LOG_TARGET_ADDRESS:
            
            guard let address = subject.stringValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOG_TARGET_ADDRESS should contain a STRING value")
                return
            }
            
            networkLogTarget.address = address
            
            let localCopy: SwifterLog.NetworkTarget = networkLogTarget
            
            if conditionallySetNetworkLogTarget() {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOG_TARGET_ADDRESS setting the network target to: \(localCopy.address):\(localCopy.port)")
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOG_TARGET_ADDRESS updated target address, waiting for port.")
            }
            
            
        case .NETWORK_LOG_TARGET_PORT:
            
            guard let port = subject.stringValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOG_TARGET_ADDRESS should contain a STRING value")
                return
            }
            
            networkLogTarget.port = port
            
            let localCopy: SwifterLog.NetworkTarget = networkLogTarget
            
            if conditionallySetNetworkLogTarget() {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOG_TARGET_ADDRESS setting the network target to: \(localCopy.address):\(localCopy.port)")
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOG_TARGET_ADDRESS updated target port, waiting for address.")
            }
            
            
        case .NETWORK_LOGLEVEL:
            
            guard let intLevel = subject.integerValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOGLEVEL should contain a NUMBER value")
                return
            }
            
            guard let newLevel = SwifterLog.Level(rawValue: intLevel) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOGLEVEL new value should be in range 0..8, found \(intLevel)")
                return
            }
            
            if newLevel != log.networkTransmitAtAndAboveLevel {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOGLEVEL updating from \(log.networkTransmitAtAndAboveLevel) to \(newLevel)")
                log.networkTransmitAtAndAboveLevel = newLevel
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-NETWORK_LOGLEVEL new level same as present level: \(newLevel)")
            }
            
            
        case .SERVICE_PORT_NUMBER:
            
            guard let portStr = subject.stringValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "WRITE-SERVICE_PORT_NUMBER should contain a STRING value")
                return
            }
            
            if portStr != Parameters.asString(.SERVICE_PORT_NUMBER) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-SERVICE_PORT_NUMBER updating from \(Parameters.asString(.SERVICE_PORT_NUMBER)) to \(portStr)")
                Parameters.pdict[.SERVICE_PORT_NUMBER] = portStr
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-SERVICE_PORT_NUMBER new value same as present value: \(portStr)")
            }
            
            
        case .STDOUT_LOGLEVEL:
            
            guard let intLevel = subject.integerValue else {
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
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "WRITE-STDOUT_LOGLEVEL new level same as present level: \(newLevel)")
            }
            
        default:
            
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "Missing case for parameter \(parameter.rawValue)")
        }
    }
    
    private func doCommandDelta(message: VJson) {

        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "DELTA should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "DELTA should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard let delta = message[MacDef.Command.DELTA.rawValue].integerValue else {
            log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "DELTA should contain a NUMBER value with the name Delta")
            return
        }
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "DELTA start")

        if delta == 0 { return }
        sleep(UInt32(min(delta, 10))) // Never more than 10 seconds
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "DELTA completed")
    }
    
    private func doCommandRestoreDomains(message: VJson) {
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "RESTORE_DOMAINS should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "RESTORE_DOMAINS should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.RESTORE_DOMAINS.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "RESTORE_DOMAINS should contain a NULL value (with the name RestoreDomains)")
            return
        }
        
        domains.restore()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "RESTORE_DOMAINS completed")
    }
    
    private func doCommandRestoreParameters(message: VJson) {
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "RESTORE_PARAMETERS should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "RESTORE_PARAMETERS should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.RESTORE_PARAMETERS.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "RESTORE_PARAMETERS should contain a NULL value (with the name RestoreParameters)")
            return
        }
        
        Parameters.restore()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "RESTORE_PARAMETERS completed")
    }

    private func doCommandSaveDomains(message: VJson) {
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "SAVE_DOMAINS should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "SAVE_DOMAINS should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.SAVE_DOMAINS.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "SAVE_DOMAINS should contain a NULL value (with the name SaveDomains)")
            return
        }
        
        domains.save()
        
        log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "SAVE_DOMAINS completed")
    }

    private func doCommandSaveParameters(message: VJson) {
        
        guard message.isObject else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "SAVE_PARAMETERS should be an OBJECT")
            return
        }
        
        guard message.nofChildren == 1 else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "SAVE_PARAMETERS should contain 1 child, found \(message.nofChildren)")
            return
        }
        
        guard message[MacDef.Command.SAVE_PARAMETERS.rawValue].isNull else {
            log.atLevelError(id: socket, source: #file.source(#function, #line), message: "SAVE_PARAMETERS should contain a NULL value (with the name SaveParameters)")
            return
        }
        
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
