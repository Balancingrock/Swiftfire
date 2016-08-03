// =====================================================================================================================
//
//  File:       ServerParameter.swift
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
// v0.9.7 - Added HEADER_LOGGING_ENABLED, MAX_FILE_SIZE_FOR_HEADER_LOGGING,
//          MAX_FILE_SIZE_FOR_ACCESS_LOGGING, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
//        - Added missing parameters from parameter version 1, harmonized names between ParameterIds and ServerParameters
// v0.9.6 - Header update
//        - Merged MAX_NOF_PENDING_CLIENT_MESSAGES and MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
//        - Merged Auto-Startup into Parameters, added configuration of more logging options
// v0.9.4 - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation

enum ServerParameter: String {
    
    case servicePortNumber = "ServicePortNumber"
    case maxNumberOfAcceptedConnections = "MaxNofAcceptedConnections"
    case maxNumberOfPendingConnections = "MaxNofPendingConnections"
    case maxWaitForPendingConnections = "MaxWaitForPendingConnections"
    case clienMessageBufferSize = "ClientMessageBufferSize"
    case httpKeepAliveInactivityTimeout = "HttpKeepAliveInactivityTimeout"
    case httpResponseClientTimeout = "HttpResponseClientTimeout"
    case debugMode = "DebugMode"
    case aslFacilityRecordAtAndAboveLevel = "AslLogLevel"
    case stdoutPrintAtAndAboveLevel = "StdoutLogLevel"
    case fileRecordAtAndAboveLevel = "FileLogLevel"
    case callbackAtAndAboveLevel = "CallbackLogLevel"
    case networkTransmitAtAndAboveLevel = "NetworkLogLevel"
    case networkLogtargetIpAddress = "NetworkLogTargetAddress"
    case networkLogtargetPortNumber = "NetworkLogTargetPort"
    case autoStartup = "AutoStartup"
    case macPortNumber = "MonitoringAndControlPortNumber"
    case macInactivityTimeout = "MacInactivityTimeout"
    case logfileMaxNofFiles = "LogfileMaxNofFiles"
    case logfileMaxSize = "LogfileMaxSize"

    case headerLoggingEnabled = "HeaderLoggingEnabled"
    case maxFileSizeForHeaderLogging = "MaxFileSizeForHeaderLogging"
    case flushHeaderLogfileAfterEachWrite = "FlushHeaderLogfileAfterEachWrite"

    var guiLabel: String {
        switch self {
        case .servicePortNumber: return "HTTP Service Port Number (usually: 80)"
        case .maxNumberOfAcceptedConnections: return "Maximum Number of Client Connections in Parallel"
        case .maxNumberOfPendingConnections: return "Maximum Number of Pending Client Connections"
        case .maxWaitForPendingConnections: return "Maximum Wait for Pending Client Connections"
        case .clienMessageBufferSize: return "Size of the Client Message Buffer in Bytes"
        case .httpKeepAliveInactivityTimeout: return "Inactivity Timeout for accepted connections with 'keep-alive' set to 'true'"
        case .httpResponseClientTimeout: return "Timeout for a client to accept a response"
        case .debugMode: return "Enable more Debug Information to be Logged"
        case .aslFacilityRecordAtAndAboveLevel: return "Send Logging at this -and above- level to the ASL Facility"
        case .stdoutPrintAtAndAboveLevel: return "Send Logging at this -and above- level to stdout (console)"
        case .fileRecordAtAndAboveLevel: return "Send Logging at this -and above- level to the Logfiles"
        case .networkTransmitAtAndAboveLevel: return "Send Logging at this -and above- level to a Network Target"
        case .callbackAtAndAboveLevel: return "Send Logging at this -and above- level to the Callback Targets"
        case .networkLogtargetIpAddress: return "The Network Target IP Address for Logging"
        case .networkLogtargetPortNumber: return "The Network Target Port for logging"
        case .autoStartup: return "Goto 'Running' on application start"
        case .macPortNumber: return "Number of M&C port (on next start, if saved)"
        case .macInactivityTimeout: return "Close M&C connection after it was inactive for this long"
        case .logfileMaxNofFiles: return "Maximum number of logfiles"
        case .logfileMaxSize: return "Maximum size of a logfile"
            
        case .headerLoggingEnabled: return "Enables logging of the full HTTP header"
        case .maxFileSizeForHeaderLogging: return "Maximum File Size of a Header Logfile"
        case .flushHeaderLogfileAfterEachWrite: return "Forces a file-write after each received HTTP header"
        }
    }

    func validateStringValue(value: String?) -> String? {
        
        guard let v = value else { return "No value present" }
        
        switch self {
            
        case .servicePortNumber,
             .networkLogtargetIpAddress,
             .networkLogtargetPortNumber,
             .macPortNumber:
            
            return nil
            
            
        case .maxNumberOfAcceptedConnections,
             .maxNumberOfPendingConnections,
             .maxWaitForPendingConnections,
             .clienMessageBufferSize,
             .httpKeepAliveInactivityTimeout,
             .logfileMaxNofFiles,
             .logfileMaxSize,
             .maxFileSizeForHeaderLogging,
             .httpResponseClientTimeout,
             .macInactivityTimeout:
            
            if let iv = Int(v) {
                if v == iv.description { return nil }
                return "Invalid characters in integer"
            } else {
                return "Cannot convert \(v) to an integer"
            }
            
            
        case .aslFacilityRecordAtAndAboveLevel,
             .stdoutPrintAtAndAboveLevel,
             .fileRecordAtAndAboveLevel,
             .callbackAtAndAboveLevel,
             .networkTransmitAtAndAboveLevel:
            
            if let iv = Int(v) {
                if v != iv.description { return "Invalid characters in integer" }
                if iv < 0 && iv > 8 { return "Level should be in range 0..8" }
                return nil
            } else {
                return "Cannot convert \(v) to an integer"
            }
            
            
        case .debugMode,
             .autoStartup,
             .headerLoggingEnabled,
             .flushHeaderLogfileAfterEachWrite:
            
            if let _ = Bool(v) {
                return nil
            } else {
                return "Cannot convert \(v) to a boolean.\nExpected one of: 0, 1, false, true, no, yes"
            }
        }
    }

    static let all: Array<ServerParameter> = [.servicePortNumber, .maxNumberOfAcceptedConnections, .maxNumberOfPendingConnections, .maxWaitForPendingConnections, .clienMessageBufferSize, .httpKeepAliveInactivityTimeout, .httpResponseClientTimeout, .debugMode, .aslFacilityRecordAtAndAboveLevel, .stdoutPrintAtAndAboveLevel, .fileRecordAtAndAboveLevel, .callbackAtAndAboveLevel, .networkTransmitAtAndAboveLevel, .networkLogtargetIpAddress, .networkLogtargetPortNumber, .autoStartup, .macPortNumber, .macInactivityTimeout, .logfileMaxSize, .logfileMaxNofFiles, .maxFileSizeForHeaderLogging, .headerLoggingEnabled, .flushHeaderLogfileAfterEachWrite]
}
