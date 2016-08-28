// =====================================================================================================================
//
//  File:       WriteServerParameterCommand.MacCommand.swift
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
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
// v0.9.14 - Initial release
// =====================================================================================================================

import Foundation


extension WriteServerParameterCommand: MacCommand {
    
    
    // MARK: - MacCommand protocol
    
    static func factory(json: VJson?) -> MacCommand? {
        return WriteServerParameterCommand(json: json)
    }
    
    func execute() {
        
        func keepOrUpdate<T: Equatable>(name: String, value: T, setter: (T)->(), getter: () -> T) {
            if value != getter() {
                log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "\(name) updating from \(getter()) to \(value)")
                setter(value)
            } else {
                log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "\(name) new value same as old value: \(value)")
            }
        }
        
        func updateBool(name: String, value: String, setter: (Bool)->(), getter: () -> Bool) {
            if let val = Bool(value) {
                keepOrUpdate(name: name, value: val, setter: setter, getter: getter)
            } else {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "\(name) should contain a Bool value")
            }
        }
        
        func updateInt(name: String, value: String, setter: (Int)->(), getter: () -> Int) {
            if let val = Int(value) {
                keepOrUpdate(name: name, value: val, setter: setter, getter: getter)
            } else {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "\(name) should contain an Int value")
            }
        }
        
        func updateInt32(name: String, value: String, setter: (Int32)->(), getter: () -> Int32) {
            if let val = Int32(value) {
                keepOrUpdate(name: name, value: val, setter: setter, getter: getter)
            } else {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "\(name) should contain an Int32 value")
            }
        }
        
        func updateDouble(name: String, value: String, setter: (Double)->(), getter: () -> Double) {
            if let val = Double(value) {
                keepOrUpdate(name: name, value: val, setter: setter, getter: getter)
            } else {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "\(name) should contain a Double value")
            }
        }
        
        func updateLevel(name: String, value: String, setter: (SwifterLog.Level)->(), getter: () -> SwifterLog.Level) {
            if let intVal = Int(value), let val = SwifterLog.Level(rawValue: intVal) {
                keepOrUpdate(name: name, value: val, setter: setter, getter: getter)
            } else {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "\(name) should contain an Int value convertible to SwifterLog.Level")
            }
        }
        
        
        // Update parameter
        
        switch parameter {
        case .debugMode: updateBool(name: parameter.rawValue, value: value, setter: { parameters.debugMode = $0 }, getter: { parameters.debugMode })
        case .autoStartup: updateBool(name: parameter.rawValue, value: value, setter: { parameters.autoStartup = $0 }, getter: { parameters.autoStartup })
        case .headerLoggingEnabled: updateBool(name: parameter.rawValue, value: value, setter: { parameters.headerLoggingEnabled = $0 }, getter: { parameters.headerLoggingEnabled })
        case .flushHeaderLogfileAfterEachWrite: updateBool(name: parameter.rawValue, value: value, setter: { parameters.flushHeaderLogfileAfterEachWrite = $0 }, getter: { parameters.flushHeaderLogfileAfterEachWrite })
        case .clientMessageBufferSize: updateInt(name: parameter.rawValue, value: value, setter: { parameters.clientMessageBufferSize = $0 }, getter: { parameters.clientMessageBufferSize })
        case .httpKeepAliveInactivityTimeout: updateInt(name: parameter.rawValue, value: value, setter: { parameters.httpKeepAliveInactivityTimeout = $0 }, getter: { parameters.httpKeepAliveInactivityTimeout })
        case .maxNumberOfAcceptedConnections: updateInt(name: parameter.rawValue, value: value, setter: { parameters.maxNofAcceptedConnections = $0 }, getter: { parameters.maxNofAcceptedConnections })
        case .maxNumberOfPendingConnections: updateInt32(name: parameter.rawValue, value: value, setter: { parameters.maxNofPendingConnections = $0 }, getter: { parameters.maxNofPendingConnections })
        case .maxWaitForPendingConnections: updateInt(name: parameter.rawValue, value: value, setter: { parameters.maxWaitForPendingConnections = $0 }, getter: { parameters.maxWaitForPendingConnections })
        case .logfileMaxSize: updateInt(name: parameter.rawValue, value: value, setter: { parameters.logfileMaxSize = $0; log.logfileMaxSizeInBytes = UInt64($0 * 1024) }, getter: { Int(log.logfileMaxSizeInBytes) * 1024 })
        case .logfileMaxNofFiles: updateInt(name: parameter.rawValue, value: value, setter: { parameters.logfileMaxNofFiles = $0; log.logfileMaxNumberOfFiles = $0 }, getter: { log.logfileMaxNumberOfFiles })
        case .maxFileSizeForHeaderLogging: updateInt(name: parameter.rawValue, value: value, setter: { parameters.maxFileSizeForHeaderLogging = $0 }, getter: { parameters.maxFileSizeForHeaderLogging })
        case .httpResponseClientTimeout: updateDouble(name: parameter.rawValue, value: value, setter: { parameters.httpResponseClientTimeout = $0 }, getter: { parameters.httpResponseClientTimeout })
        case .aslFacilityRecordAtAndAboveLevel: updateLevel(name: parameter.rawValue, value: value, setter: { parameters.aslFacilityRecordAtAndAboveLevel = $0; log.aslFacilityRecordAtAndAboveLevel = $0 }, getter: { log.aslFacilityRecordAtAndAboveLevel })
        case .fileRecordAtAndAboveLevel: updateLevel(name: parameter.rawValue, value: value, setter: { parameters.fileRecordAtAndAboveLevel = $0; log.fileRecordAtAndAboveLevel = $0 }, getter: { log.fileRecordAtAndAboveLevel })
        case .callbackAtAndAboveLevel: updateLevel(name: parameter.rawValue, value: value, setter: { parameters.callbackAtAndAboveLevel = $0; log.callbackAtAndAboveLevel = $0 }, getter: { log.callbackAtAndAboveLevel })
        case .networkTransmitAtAndAboveLevel: updateLevel(name: parameter.rawValue, value: value, setter: { parameters.networkTransmitAtAndAboveLevel = $0; log.networkTransmitAtAndAboveLevel = $0 }, getter: { log.networkTransmitAtAndAboveLevel })
        case .stdoutPrintAtAndAboveLevel: updateLevel(name: parameter.rawValue, value: value, setter: { parameters.stdoutPrintAtAndAboveLevel = $0; log.stdoutPrintAtAndAboveLevel = $0 }, getter: { log.stdoutPrintAtAndAboveLevel })
        case .servicePortNumber: keepOrUpdate(name: parameter.rawValue, value: value, setter: { parameters.httpServicePortNumber = $0 }, getter: { parameters.httpServicePortNumber })
        case .macPortNumber: keepOrUpdate(name: parameter.rawValue, value: value, setter: { parameters.macPortNumber = $0 }, getter: { parameters.macPortNumber })
            
        case .networkLogtargetIpAddress:
            keepOrUpdate(
                name: parameter.rawValue,
                value: value,
                setter: {
                    parameters.networkLogtargetIpAddress = $0
                    WriteServerParameterCommand.networkLogTarget.address = $0
                    WriteServerParameterCommand.conditionallySetNetworkLogTarget()
                },
                getter: {
                    log.networkTarget?.address ?? ""
                }
            )
            
        case .networkLogtargetPortNumber:
            keepOrUpdate(
                name: parameter.rawValue,
                value: value,
                setter: {
                    parameters.networkLogtargetPortNumber = $0
                    WriteServerParameterCommand.networkLogTarget.port = $0
                    WriteServerParameterCommand.conditionallySetNetworkLogTarget()
                },
                getter: {
                    log.networkTarget?.port ?? ""
                }
            )
            
        case .macInactivityTimeout: updateDouble(name: parameter.rawValue, value: value, setter: { parameters.macInactivityTimeout = $0 }, getter: { parameters.macInactivityTimeout })
        case .http1_0DomainName: keepOrUpdate(name: parameter.rawValue, value: value, setter: { parameters.http1_0DomainName = $0 }, getter: { parameters.http1_0DomainName })
            
        }
    }
    
    
    // The network target for the logger
    
//    private static var networkLogTarget = SwifterLog.NetworkTarget("","")
    
    
    /// Checks if the networkLogTarget contains two non-empty fields, and if so, tries to connect the logger to the target. After a connection attempt it will empty the fields.
    /// - Returns: True if the connection attempt was made, false otherwise.
    /// - Note: It does not report the sucess/failure of the connection attempt.
    
    @discardableResult
    private static func conditionallySetNetworkLogTarget() -> Bool {
        if networkLogTarget.address.isEmpty { return false }
        if networkLogTarget.port.isEmpty { return false }
        log.connectToNetworkTarget(networkLogTarget)
        log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Setting the network logtarget to: \(networkLogTarget.address):\(networkLogTarget.port)")
        networkLogTarget.address = ""
        networkLogTarget.port = ""
        return true
    }
}
