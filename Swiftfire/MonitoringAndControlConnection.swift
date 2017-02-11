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


// var mac = MonitoringAndControlConnection()


protocol TransferToConsole {
    
    /// Attempts to transfer the given reply to the console. The SW using this call should be written such that success (or failure) becomes appearent to the user asap.
    /// - Note: There is no mechanism to guarantee successful transmission.
    
    func transfer(_ reply: MacMessage?)
}

var toConsole: TransferToConsole?


final class MonitoringAndControlConnection: SwifterSockets.Connection {
    
    
    // The queue on which all processing takes place
    
    let queue = DispatchQueue(label: "Monitoring and Control Queue")
    
    
    // Creates a new instance of the M&C connection.
    
    init(forType type: SwifterSockets.ConnectionType, remoteAddress address: String) {
        
        super.init()
        
        _ = super.prepare(
            forType: type,
            remoteAddress: address,
            options:
                SwifterSockets.Connection.Option.receiverQueue(queue),
                SwifterSockets.Connection.Option.transmitterQueue(queue),
                SwifterSockets.Connection.Option.receiverBufferSize(commandsBufferSize)
            )
        
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
        
        commandsBuffer = UnsafeMutableRawPointer.allocate(bytes: commandsBufferSize, alignedTo: 1)
        commandsBufferStartOfFreeArea = commandsBuffer
    }
    
    
    deinit {
        commandsBuffer.deallocate(bytes: commandsBufferSize, alignedTo: 1)
    }
    
    
    // All possible commands

    private var commandFactories: Array<MacCommandFactory> = []
    

    /// Used internally, calling this operation may lead to aborted transfers and error messages. In order to close the connection use "closeConnection()" instead.
    
    override func _closeConnection() {
        super._closeConnection()
        toConsole = nil
    }
    
    
    // The buffer for incoming data from the console
    
    fileprivate let commandsBufferSize = 17 * 1024
    fileprivate let commandsBuffer: UnsafeMutableRawPointer
    fileprivate var commandsByteCount = 0
    fileprivate var commandsBufferStartOfFreeArea: UnsafeMutableRawPointer

    override func receiveData(_ buffer: UnsafeBufferPointer<UInt8>) -> Bool {
        
        
        // Add the new data to the command buffer
        
        memcpy(commandsBufferStartOfFreeArea, buffer.baseAddress, buffer.count)
        commandsBufferStartOfFreeArea = commandsBufferStartOfFreeArea.advanced(by: buffer.count)
        commandsByteCount += buffer.count
        
        
        // Execute all completely received commands
        
        while let jsonBuffer = VJson.findPossibleJsonCode(start: commandsBuffer, count: commandsByteCount) {
            
            do {
                
                let json = try VJson.parse(buffer: jsonBuffer)
                
                
                var commandExecuted = false
                
                for factory in commandFactories {
                    if let command = factory(json) {
                        command.execute()
                        commandExecuted = true
                        break
                    }
                }
                
                if !commandExecuted {
                    log.atLevelError(id: -1, source: "MacLoop receiveData", message: "Could not create command from JSON code: \(json)")
                }
                
                
                // Remove the processed command from the buffer
                
                let srcPtr = UnsafeRawPointer(jsonBuffer.baseAddress!.advanced(by: jsonBuffer.count))
                let consumedBytes = UnsafeRawPointer(commandsBuffer).distance(to: srcPtr)
                commandsByteCount -= consumedBytes
                commandsBufferStartOfFreeArea = commandsBufferStartOfFreeArea.advanced(by: -consumedBytes)
                memcpy(commandsBuffer, srcPtr, commandsByteCount)
                
                
            } catch let error as VJson.Exception {
                
                if case let .reason(_, incomplete, _) = error {
                    
                    if incomplete {
                        
                        break // This is not necessarily an error, perhaps the rest of the data has not arrived yet
                        
                    } else {
                        
                        log.atLevelError(id: -1, source: "MacLoop receiveData", message: error.description)
                    }
                    
                } else {
                    log.atLevelError(id: -1, source: "MacLoop receiveData", message: "Logic error 1")
                }
                
                
                // Try to recover by emptying the buffer
                
                commandsBufferStartOfFreeArea = commandsBuffer
                commandsByteCount = 0
                
            } catch {
                
                log.atLevelError(id: -1, source: "MacLoop consoleReceieveHandler", message: "Logic error 2")
                
                // Try to recover by emptying the buffer
                
                commandsBufferStartOfFreeArea = commandsBuffer
                commandsByteCount = 0
            }
        }
        
        return true
    }
}

extension MonitoringAndControlConnection: TransferToConsole {
    
    func transfer(_ reply: MacMessage?) {
        if let reply = reply {
            super.transfer(reply.json.code)
        }
    }
}

