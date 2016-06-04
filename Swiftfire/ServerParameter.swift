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
// v0.9.6 - Header update
//        - Merged MAX_NOF_PENDING_CLIENT_MESSAGES and MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
//        - Merged Auto-Startup into Parameters, added configuration of more logging options
// v0.9.4 - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation

enum ServerParameter: String {
    
    case SERVICE_PORT_NUMBER = "ServicePortNumber"
    case MAX_NOF_ACCEPTED_CONNECTIONS = "MaxNofAcceptedConnections"
    case MAX_NOF_PENDING_CONNECTIONS = "MaxNofPendingConnections"
    case MAX_WAIT_FOR_PENDING_CONNECTIONS = "MaxWaitForPendingConnections"
    case CLIENT_MESSAGE_BUFFER_SIZE = "ClientMessageBufferSize"
    case DEBUG_MODE = "DebugMode"
    case ASL_LOGLEVEL = "AslLogLevel"
    case STDOUT_LOGLEVEL = "StdoutLogLevel"
    case FILE_LOGLEVEL = "FileLogLevel"
    case CALLBACK_LOGLEVEL = "CallbackLogLevel"
    case NETWORK_LOGLEVEL = "NetworkLogLevel"
    case NETWORK_LOG_TARGET_ADDRESS = "NetworkLogTargetAddress"
    case NETWORK_LOG_TARGET_PORT = "NetworkLogTargetPort"
    case AUTO_STARTUP = "AutoStartup"
    case MAC_PORT_NUMBER = "MonitoringAndControlPortNumber"
    case LOGFILES_FOLDER = "LogfilesFolder"
    case LOGFILE_MAX_NOF_FILES = "LogfileMaxNofFiles"
    case LOGFILE_MAX_SIZE = "LogfileMaxSize"

    case HEADER_LOGGING_ENABLED = "HeaderLoggingEnabled"
    case MAX_FILE_SIZE_FOR_HEADER_LOGGING = "MaxFileSizeForHeaderLogging"
    case MAX_FILE_SIZE_FOR_ACCESS_LOGGING = "MaxFileSizeForAccessLogging"
    case FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE = "FlushHeaderLogfileAfterEachWrite"

    var guiLabel: String {
        switch self {
        case .SERVICE_PORT_NUMBER: return "HTTP Service Port Number (usually: 80)"
        case .MAX_NOF_ACCEPTED_CONNECTIONS: return "Maximum Number of Client Connections in Parallel"
        case .MAX_NOF_PENDING_CONNECTIONS: return "Maximum Number of Pending Client Connections"
        case .MAX_WAIT_FOR_PENDING_CONNECTIONS: return "Maximum Wait for Pending Client Connections"
        case .CLIENT_MESSAGE_BUFFER_SIZE: return "Size of the Client Message Buffer in Bytes"
        case .DEBUG_MODE: return "Enable more Debug Information to be Logged"
        case .ASL_LOGLEVEL: return "Send Logging at this -and above- level to the ASL Facility"
        case .STDOUT_LOGLEVEL: return "Send Logging at this -and above- level to stdout (console)"
        case .FILE_LOGLEVEL: return "Send Logging at this -and above- level to the Logfiles"
        case .NETWORK_LOGLEVEL: return "Send Logging at this -and above- level to a Network Target"
        case .CALLBACK_LOGLEVEL: return "Send Logging at this -and above- level to the Callback Targets"
        case .NETWORK_LOG_TARGET_ADDRESS: return "The Network Target IP Address for Logging"
        case .NETWORK_LOG_TARGET_PORT: return "The Network Target Port for logging"
        case .AUTO_STARTUP: return "Goto 'Running' on application start"
        case .MAC_PORT_NUMBER: return "Number of M&C port (on next start, if saved)"
        case .LOGFILES_FOLDER: return "Folder for logfiles"
        case .LOGFILE_MAX_NOF_FILES: return "Maximum number of logfiles"
        case .LOGFILE_MAX_SIZE: return "Maximum size of a logfile"
            
        case HEADER_LOGGING_ENABLED: return "Enables logging of the full HTTP header"
        case MAX_FILE_SIZE_FOR_HEADER_LOGGING: return "Maximum File Size of a Header Logfile"
        case MAX_FILE_SIZE_FOR_ACCESS_LOGGING: return "Maximum File Size of an Access Logfile"
        case FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE: return "Forces a file-write after each received HTTP header"
        }
    }

    func validateStringValue(value: String?) -> String? {
        
        guard let v = value else { return "No value present" }
        
        switch self {
            
        case .SERVICE_PORT_NUMBER,
             .NETWORK_LOG_TARGET_ADDRESS,
             .NETWORK_LOG_TARGET_PORT,
             .MAC_PORT_NUMBER,
             .LOGFILES_FOLDER:
            
            return nil
            
            
        case .MAX_NOF_ACCEPTED_CONNECTIONS,
             .MAX_NOF_PENDING_CONNECTIONS,
             .MAX_WAIT_FOR_PENDING_CONNECTIONS,
             .CLIENT_MESSAGE_BUFFER_SIZE,
             .LOGFILE_MAX_NOF_FILES,
             .LOGFILE_MAX_SIZE,
             .MAX_FILE_SIZE_FOR_HEADER_LOGGING,
             .MAX_FILE_SIZE_FOR_ACCESS_LOGGING:
            
            if let iv = Int(v) {
                if v == iv.description { return nil }
                return "Invalid characters in integer"
            } else {
                return "Cannot convert \(v) to an integer"
            }
            
            
        case .ASL_LOGLEVEL,
             .STDOUT_LOGLEVEL,
             .FILE_LOGLEVEL,
             .CALLBACK_LOGLEVEL,
             .NETWORK_LOGLEVEL:
            
            if let iv = Int(v) {
                if v != iv.description { return "Invalid characters in integer" }
                if iv < 0 && iv > 8 { return "Level should be in range 0..8" }
                return nil
            } else {
                return "Cannot convert \(v) to an integer"
            }
            
            
        case .DEBUG_MODE,
             .AUTO_STARTUP,
             .HEADER_LOGGING_ENABLED,
             .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            if let _ = Bool(v) {
                return nil
            } else {
                return "Cannot convert \(v) to a boolean.\nExpected one of: 0, 1, false, true, no, yes"
            }
        }
    }

    static let all: Array<ServerParameter> = [.SERVICE_PORT_NUMBER, .MAX_NOF_ACCEPTED_CONNECTIONS, .MAX_NOF_PENDING_CONNECTIONS, .MAX_WAIT_FOR_PENDING_CONNECTIONS, .CLIENT_MESSAGE_BUFFER_SIZE, .DEBUG_MODE, .ASL_LOGLEVEL, .STDOUT_LOGLEVEL, .FILE_LOGLEVEL, .CALLBACK_LOGLEVEL, .NETWORK_LOGLEVEL, .NETWORK_LOG_TARGET_ADDRESS, .NETWORK_LOG_TARGET_PORT, .AUTO_STARTUP, .MAC_PORT_NUMBER, .LOGFILES_FOLDER, .LOGFILE_MAX_SIZE, .LOGFILE_MAX_NOF_FILES, .MAX_FILE_SIZE_FOR_HEADER_LOGGING, .MAX_FILE_SIZE_FOR_ACCESS_LOGGING, .HEADER_LOGGING_ENABLED, .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE]
}