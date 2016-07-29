// =====================================================================================================================
//
//  File:       Parameters.swift
//  Project:    Swiftfire
//
private let VERSION = "0.9.12"
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
// v0.9.12 - Updated version number
// v0.9.11 - Updated version number
// v0.9.10 - Updated version number
// v0.9.9  - Updated version number
// v0.9.8  - Updated version number
// v0.9.7  - Changed initial value of HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT to 1 second
//         - Added HEADER_LOGGING_ENABLED, MAX_FILE_SIZE_FOR_HEADER_LOGGING, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
//         - Slightly optimized code to upgrade to new parameter file version
//         - Added function to upgrade to parameter version 2
//         - Moved M&C support for the server parameters to this file
// v0.9.6  - Header update & version number update
//         - Merged MAX_NOF_PENDING_CLIENT_MESSAGES with MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
//         - Merged AutoStartup into this file
// v0.9.5  - Updated version number
// v0.9.4  - Updated version number
// v0.9.3  - Updated version number
// v0.9.2  - Updated version number
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation


private typealias JsonReadAccess = (VJson) -> Any?

enum ParameterId: String {
    
    // When adding a parameter you must do four things:
    // 1) Add the parameter as a case
    // 2) Add the parameter to the static property 'jsonAccess'
    // 3) Add the parameter to the static property 'all'
    // 4) Add the default value to upgradeParameterDictionaryToVersionXXX
    
    // Version 1
    case PARAMETER_DEFAULTS_FILE_VERSION = "ParameterDefaultsFileVersion"
    case DEBUG_MODE = "DebugMode"
    case SERVICE_PORT_NUMBER = "ServicePortNumber"
    case MAX_NOF_ACCEPTED_CONNECTIONS = "MaxNumberOfAcceptedConnections"
    case MAX_NOF_PENDING_CONNECTIONS = "MaxNumberOfPendingConnections"
    case MAX_WAIT_FOR_PENDING_CONNECTIONS = "MaxWaitForPendingConnections"
    case CLIENT_MESSAGE_BUFFER_SIZE = "ClienMessageBufferSize"
    case HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT = "HttpKeepAliveInactivityTimeout"
    case HTTP_RESPONSE_CLIENT_TIMEOUT = "HttpResponseClientTimeout"
    case MAC_INACTIVITY_TIMEOUT = "MacInactivityTimeout"
    case AUTO_STARTUP = "AutoStartup"
    case MAC_PORT_NUMBER = "MonitoringAndControlPortNumber"
    case ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL = "AslFacilityRecordAtAndAboveLevel"
    case STDOUT_PRINT_AT_AND_ABOVE_LEVEL = "StdoutPrintAtAndAboveLevel"
    case CALLBACK_AT_AND_ABOVE_LEVEL = "CallbackAtAndAboveLevel"
    case FILE_RECORD_AT_AND_ABOVE_LEVEL = "FileRecordAtAndAboveLevel"
    case LOGFILE_MAX_SIZE = "LogfileMaxSize"
    case LOGFILE_MAX_NOF_FILES = "LogfileMaxNofFiles"
    case NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL = "NetworkTransmitAtAndAboveLevel"
    case NETWORK_LOGTARGET_IP_ADDRESS = "NetworkLogtargetIpAddress"
    case NETWORK_LOGTARGET_PORT_NUMBER = "NetworkLogtargetPortNumber"
    
    // Version 2
    case HEADER_LOGGING_ENABLED = "HeaderLoggingEnabled"
    case MAX_FILE_SIZE_FOR_HEADER_LOGGING = "MaxFileSizeForHeaderLogging"
    case FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE = "FlushHeaderLogfileAfterEachWrite"
    
    static func from(serverParameter: ServerParameter) -> ParameterId {
        switch serverParameter {
        //   .PARAMETER_DEFAULTS_FILE_VERSION is not writeable
        case .DEBUG_MODE: return .DEBUG_MODE
        case .SERVICE_PORT_NUMBER: return .SERVICE_PORT_NUMBER
        case .MAX_NOF_ACCEPTED_CONNECTIONS: return .MAX_NOF_ACCEPTED_CONNECTIONS
        case .MAX_NOF_PENDING_CONNECTIONS: return .MAX_NOF_PENDING_CONNECTIONS
        case .MAX_WAIT_FOR_PENDING_CONNECTIONS: return .MAX_WAIT_FOR_PENDING_CONNECTIONS
        case .CLIENT_MESSAGE_BUFFER_SIZE: return .CLIENT_MESSAGE_BUFFER_SIZE
        case .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT: return .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT
        case .HTTP_RESPONSE_CLIENT_TIMEOUT: return .HTTP_RESPONSE_CLIENT_TIMEOUT
        case .MAC_INACTIVITY_TIMEOUT: return .MAC_INACTIVITY_TIMEOUT
        case .AUTO_STARTUP: return .AUTO_STARTUP
        case .MAC_PORT_NUMBER: return .MAC_PORT_NUMBER
        case .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL: return .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL
        case .STDOUT_PRINT_AT_AND_ABOVE_LEVEL: return .STDOUT_PRINT_AT_AND_ABOVE_LEVEL
        case .CALLBACK_AT_AND_ABOVE_LEVEL: return .CALLBACK_AT_AND_ABOVE_LEVEL
        case .FILE_RECORD_AT_AND_ABOVE_LEVEL: return .FILE_RECORD_AT_AND_ABOVE_LEVEL
        case .LOGFILE_MAX_SIZE: return .LOGFILE_MAX_SIZE
        case .LOGFILE_MAX_NOF_FILES: return .LOGFILE_MAX_NOF_FILES
        case .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL: return .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL
        case .NETWORK_LOGTARGET_IP_ADDRESS: return .NETWORK_LOGTARGET_IP_ADDRESS
        case .NETWORK_LOGTARGET_PORT_NUMBER: return .NETWORK_LOGTARGET_PORT_NUMBER
            
        // Version 2
        case .HEADER_LOGGING_ENABLED: return .HEADER_LOGGING_ENABLED
        case .MAX_FILE_SIZE_FOR_HEADER_LOGGING: return .MAX_FILE_SIZE_FOR_HEADER_LOGGING
        case .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE: return .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
        }
    }
    
    private var jsonRead: JsonReadAccess {
        
        switch self {
            
        case .DEBUG_MODE,
             .AUTO_STARTUP,
             .HEADER_LOGGING_ENABLED,
             .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            // These are the Bool parameters
            
            return { (json: VJson) -> Any? in json.boolValue }
            
            
        case .PARAMETER_DEFAULTS_FILE_VERSION,
             .MAX_NOF_PENDING_CONNECTIONS,
             .MAX_NOF_ACCEPTED_CONNECTIONS,
             .MAX_WAIT_FOR_PENDING_CONNECTIONS,
             .CLIENT_MESSAGE_BUFFER_SIZE,
             .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT,
             .HTTP_RESPONSE_CLIENT_TIMEOUT,
             .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL,
             .STDOUT_PRINT_AT_AND_ABOVE_LEVEL,
             .CALLBACK_AT_AND_ABOVE_LEVEL,
             .FILE_RECORD_AT_AND_ABOVE_LEVEL,
             .LOGFILE_MAX_SIZE,
             .LOGFILE_MAX_NOF_FILES,
             .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL,
             .MAX_FILE_SIZE_FOR_HEADER_LOGGING:
            
            // These are the Int parameters
            
            return { (json: VJson) -> Any? in json.integerValue }
            
            
        case .SERVICE_PORT_NUMBER,
             .MAC_PORT_NUMBER,
             .NETWORK_LOGTARGET_IP_ADDRESS,
             .NETWORK_LOGTARGET_PORT_NUMBER:
            
            // These are the String parameters
            
            return { (json: VJson) -> Any? in json.stringValue }
            
            
        case .MAC_INACTIVITY_TIMEOUT:
            
            // These are the Double parameters
            
            return { (json: VJson) -> Any? in json.doubleValue }
        }
    }
    
    private func jsonWrite(val: Any) -> VJson {
        
        switch self {
            
        case .DEBUG_MODE,
             .AUTO_STARTUP,
             .HEADER_LOGGING_ENABLED,
             .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            // These are the Bool parameters
            
            return VJson(val as? Bool, name: self.rawValue)
            
            
        case PARAMETER_DEFAULTS_FILE_VERSION,
             .MAX_NOF_PENDING_CONNECTIONS,
             .MAX_NOF_ACCEPTED_CONNECTIONS,
             .MAX_WAIT_FOR_PENDING_CONNECTIONS,
             .CLIENT_MESSAGE_BUFFER_SIZE,
             .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT,
             .HTTP_RESPONSE_CLIENT_TIMEOUT,
             .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL,
             .STDOUT_PRINT_AT_AND_ABOVE_LEVEL,
             .CALLBACK_AT_AND_ABOVE_LEVEL,
             .FILE_RECORD_AT_AND_ABOVE_LEVEL,
             .LOGFILE_MAX_NOF_FILES,
             .LOGFILE_MAX_SIZE,
             .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL,
             .MAX_FILE_SIZE_FOR_HEADER_LOGGING:
            
            // These are the Int parameters
            
            return VJson(val as? Int, name: self.rawValue)
            
            
        case .SERVICE_PORT_NUMBER,
             .MAC_PORT_NUMBER,
             .NETWORK_LOGTARGET_IP_ADDRESS,
             .NETWORK_LOGTARGET_PORT_NUMBER:
            
            // These are the String parameters
            
            return VJson(val as? String, name: self.rawValue)
            
            
        case .MAC_INACTIVITY_TIMEOUT:
            
            // These are the Double parameters
            
            return VJson(val as? Double, name: self.rawValue)
        }
    }
    
    static var all: Array<ParameterId> = [.AUTO_STARTUP, .MAC_PORT_NUMBER, .DEBUG_MODE, .PARAMETER_DEFAULTS_FILE_VERSION, .MAX_NOF_PENDING_CONNECTIONS, .MAX_NOF_ACCEPTED_CONNECTIONS, .MAX_WAIT_FOR_PENDING_CONNECTIONS, .CLIENT_MESSAGE_BUFFER_SIZE, .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT, .HTTP_RESPONSE_CLIENT_TIMEOUT, .SERVICE_PORT_NUMBER, .MAC_INACTIVITY_TIMEOUT, .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL, .STDOUT_PRINT_AT_AND_ABOVE_LEVEL, .CALLBACK_AT_AND_ABOVE_LEVEL, .FILE_RECORD_AT_AND_ABOVE_LEVEL, .LOGFILE_MAX_SIZE, .LOGFILE_MAX_NOF_FILES, .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL, .NETWORK_LOGTARGET_IP_ADDRESS, .NETWORK_LOGTARGET_PORT_NUMBER, .HEADER_LOGGING_ENABLED, .MAX_FILE_SIZE_FOR_HEADER_LOGGING, .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE]
}


final class Parameters {

    
    // No instantiations
    
    private init() {}
    
    
    // The dictionary in which the parameters are stored
    
    typealias ParameterDictionary = Dictionary<ParameterId, Any>

    
    /// The containers for all parameters
    
    static var pdict: ParameterDictionary = [:]

    static func asInt(p: ParameterId) -> Int {
        if let v = pdict[p] as? Int { return v }
        return 0
    }
    
    static func asString(p: ParameterId) -> String {
        if let v = pdict[p] as? String { return v }
        return ""
    }
    
    static func asBool(p: ParameterId) -> Bool {
        if let v = pdict[p] as? Bool { return v }
        return false
    }
    
    static func asDouble(p: ParameterId) -> Double {
        if let v = pdict[p] as? Double { return v }
        return 0.0
    }
    
    
    /// The version number of Swiftfire
    
    static let version = VERSION // Always hard coded, never read from the parameter defaults file
    
    
    // The current version number of the parameter-defaults file
    
    private static var parameterDefaultsFileVersion = 2
    
    
    /**
     Reads the parameter values from the parameter-defaults.json file.
     
     If the parameter file does not exist, it will not be created. Instead the hard coded defaults will be used.
     
     If the parameter file is for an older version of Parameters then that parameter file will be updated to the latest version. The new parameters will contain the hard coded defaults.
     
     If the parameter file is for a newer version of Parameters then an attempt to use it will be made. For those parameters for which this fails, the hard coded defaults will be used.
     
     If any parameter is not readable from the parameter file, but the parameter file itself does exists, then Swiftfire will fail to launch.
     
     - Returns: 'true' if the application can start, false if the start must be aborted.
     */
    
    static func restore() -> Bool {
                
        // Does the parameter defaults file exist?
        
        guard FileURLs.exists(FileURLs.parameterDefaults) else {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "No 'parameter-defaults.json' file present, starting with hard coded defaults.")
            updateParameterDictionary()
            logParameterSettings()
            return true
        }

        
        // Extract the JSON hierarchy from the parameter defaults file
        
        var json: VJson
        do {
            json = try VJson.parse(FileURLs.parameterDefaults!)
        } catch let error as VJson.Exception {
            log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Could not retrieve JSON code from parameter-defaults file. Error = \(error).")
            return false
        } catch let error as NSError {
            log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Could not retrieve JSON code from parameter-defaults file. Error = \(error).")
            return false
        } catch {
            log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Could not retrieve JSON code from parameter-defaults file. Unspecified error.")
            return false
        }
        
        
        // Read the parameter values from the JSON hierarchy into a parameter dictionary object
        
        pdict = readParameterDictionaryFrom(json)
        
        
        // If the dictionary is not at the current version try to upgrade it
        
        if let fileVersion = pdict[.PARAMETER_DEFAULTS_FILE_VERSION] as? Int {
            if fileVersion < parameterDefaultsFileVersion {
                updateParameterDictionary()
            } else if fileVersion > parameterDefaultsFileVersion {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Error in parameter-defaults file, version number is too high. ( > \(parameterDefaultsFileVersion))")
                return false
            }
        }
        
        
        // Verify that all parameters are present
        
        var complete = true
        for p in ParameterId.all {
            if pdict[p] == nil {
                log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Missing parameter in parameter-defaults file: \(p.rawValue).")
                complete = false
            }
        }
        if !complete { return false }
        
        
        // Success
        
        return true
    }
    
    
    private static func readParameterDictionaryFrom(json: VJson) -> ParameterDictionary {

        var pd = ParameterDictionary()
        
        for p in ParameterId.all {
            
            if let v = p.jsonRead(json[p.rawValue]) {
            
                pd[p] = v
            
            } else {
            
                log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Could not read \(p.rawValue) from parameter defaults file")
            }
        }
        
        return pd
    }
    
    
    private static func updateParameterDictionary() {
        
        if pdict[.PARAMETER_DEFAULTS_FILE_VERSION] == nil {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Initializing the parameter dictionary to version 1")
            initParameterDictionary()
        }
        
        var version = asInt(.PARAMETER_DEFAULTS_FILE_VERSION)
        while version < parameterDefaultsFileVersion {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Updating the settings file to version \(version)")
            switch (version) {
            case 1: upgradeToVersion2()
            default: log.atLevelCritical(source: #file.source(#function, #line), message: "Missing code to upgrade parameters to version \(version)")
            }
            version = asInt(.PARAMETER_DEFAULTS_FILE_VERSION)
        }
    }
    
    
    // Creates the original default values for the parameter dictionary
    
    private static func initParameterDictionary() {
        
        pdict[.PARAMETER_DEFAULTS_FILE_VERSION] = 1
        
        
        // When this variable is "true" additional code will be executed to generate debug information
        // Note: This variable is independant of the logging levels!

        pdict[.DEBUG_MODE] = false
        
        
        // This is the number of TCP connection negotiations that are allowed (before they are accepted)
        // Note: when the MAX_NUMBER_OF_PENDING_CONNECTIONS has been reached, new connections will be rejected.
        
        pdict[.MAX_NOF_PENDING_CONNECTIONS] = 20
        
        
        /// This is the port number upon which new connection requests will be accepted
        
        pdict[.SERVICE_PORT_NUMBER] = "6678"

        
        /// This is the maximum number of parralel connection requests we can handle.
        /// More than this, and the new connection requests will have to wait before they are accepted.
        
        pdict[.MAX_NOF_ACCEPTED_CONNECTIONS] = 20
        
        
        /// This is the maximum time a connection request is kept waiting before it is rejected.
        
        pdict[.MAX_WAIT_FOR_PENDING_CONNECTIONS] = 30
        
                
        /// The maximum size of a http message that can be received from client. (Sets the size of the receiver buffer)
        
        pdict[.CLIENT_MESSAGE_BUFFER_SIZE] = 100000
        
        
        /// When a HTTP request has the "keep alive" option set, the connection will remain open for this time after the last data block was processed from that client.
        
        pdict[.HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT] = 1 // 1 second
        
        
        /// When data has to be transferred to a client, this is the timeout for the transmit operation.
        
        pdict[.HTTP_RESPONSE_CLIENT_TIMEOUT] = 10 // 10 seconds
        
        
        /// When the M&C connection has been established, it will remain locked to the given connection until no activity has been detected for this amount of time. Note that when a console periodically retrieves telemetry, that interval should be shorter than this inactvity timeout or else another console could take over. Time is in seconds.
        
        pdict[.MAC_INACTIVITY_TIMEOUT] = 600.0
        
        
        /// When set to true, Swiftfire will enter "Running" automatically.
        
        pdict[.AUTO_STARTUP] = false
        
        
        /// The port number on which Swiftfire will listen for M&C connections.
        
        pdict[.MAC_PORT_NUMBER] = "2043"
        
        
        /// For SwifterLog ASL threshold
        
        pdict[.ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL] = SwifterLog.Level.NONE.rawValue
        
        
        /// For the SwifterLog stdout threshold
        
        pdict[.STDOUT_PRINT_AT_AND_ABOVE_LEVEL] = SwifterLog.Level.NONE.rawValue
        
        
        /// For the SwifterLog callback threshold
        
        pdict[.CALLBACK_AT_AND_ABOVE_LEVEL] = SwifterLog.Level.NONE.rawValue
        
        
        /// For the SwifterLog file threshold
        
        pdict[.FILE_RECORD_AT_AND_ABOVE_LEVEL] = SwifterLog.Level.NOTICE.rawValue
        
        
        /// For the SwifterLog maximum number of logfiles
        
        pdict[.LOGFILE_MAX_NOF_FILES] = 20
        
        
        /// For the SwifterLog maximum logfile size (in kbytes)
        
        pdict[.LOGFILE_MAX_SIZE] = 1000 // 1MB
        
        
        /// For the SwifterLog network target threshold
        
        pdict[.NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL] = SwifterLog.Level.NONE.rawValue

        
        /// The IP address for the logging network target
        
        pdict[.NETWORK_LOGTARGET_IP_ADDRESS] = "" // i.e. none
        
        
        /// The Port number for the logging network target
        
        pdict[.NETWORK_LOGTARGET_PORT_NUMBER] = "" // I.e. none
    }
    
    private static func upgradeToVersion2() {
        
        /// Enables/Disables logging of all request headers
        
        pdict[.HEADER_LOGGING_ENABLED] = false
        

        /// The maximum file size for header logging (in kbytes)
        
        pdict[.MAX_FILE_SIZE_FOR_HEADER_LOGGING] = 1000 // 1 MB
        
        
        /// Synchronize the header logging file after each write
        
        pdict[.FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE] = false
        
        
        /// Update the version to 2
        
        pdict[.PARAMETER_DEFAULTS_FILE_VERSION] = 2
    }
    
    
    /**
     Save the parameter dictionary contents to the 'domains-default.json' file.
     */

    static func save() {
        
        if let file = FileURLs.parameterDefaults {
            
            let json = VJson()
        
            for p in ParameterId.all {
                json.add(p.jsonWrite(pdict[p]), forName: p.rawValue)
            }
            
            json.save(file)
        
        } else {
        
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not save parameters to file")
        }
    }
    
    
    static func logParameterSettings() {
        
        log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Swiftfire Version Number: \(Parameters.version)")

        for p in ParameterId.all {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "\(p.rawValue): \(pdict[p]!)")
        }
    }
    
    
    // MARK: - Support for Monitoring & Control
    
    static func doReadServerParameterCommand(socket: Int32, command: ReadServerParameterCommand) {
        
        func createBoolReply(parameter: ServerParameter) -> VJson {
            let parameterId = ParameterId.from(parameter)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, \(parameterId.rawValue) = \(Parameters.asBool(parameterId))")
            return ReadServerParameterReply(parameter: parameter, value: Parameters.asBool(parameterId)).json
        }
        
        func createStringReply(parameter: ServerParameter) -> VJson {
            let parameterId = ParameterId.from(parameter)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, \(parameterId.rawValue) = \(Parameters.asString(parameterId))")
            return ReadServerParameterReply(parameter: parameter, value: Parameters.asString(parameterId)).json
        }

        func createIntReply(parameter: ServerParameter) -> VJson {
            let parameterId = ParameterId.from(parameter)
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, \(parameterId.rawValue) = \(Parameters.asInt(parameterId))")
            return ReadServerParameterReply(parameter: parameter, value: Parameters.asInt(parameterId)).json
        }


        switch command.parameter {
            
        case .DEBUG_MODE,
             .AUTO_STARTUP,
             .HEADER_LOGGING_ENABLED,
             .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            toConsole?.transferToConsole(createBoolReply(command.parameter).description)
            
            
        case .SERVICE_PORT_NUMBER,
             .MAC_PORT_NUMBER:
            
            toConsole?.transferToConsole(createStringReply(command.parameter).description)
            
            
        case .CLIENT_MESSAGE_BUFFER_SIZE,
             .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT,
             .MAX_NOF_ACCEPTED_CONNECTIONS,
             .MAX_NOF_PENDING_CONNECTIONS,
             .MAX_WAIT_FOR_PENDING_CONNECTIONS,
             .LOGFILE_MAX_NOF_FILES,
             .LOGFILE_MAX_SIZE,
             .MAX_FILE_SIZE_FOR_HEADER_LOGGING,
             .HTTP_RESPONSE_CLIENT_TIMEOUT,
             .MAC_INACTIVITY_TIMEOUT:
            
            toConsole?.transferToConsole(createIntReply(command.parameter).description)
            
            
        case .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL:
            
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.aslFacilityRecordAtAndAboveLevel = \(log.aslFacilityRecordAtAndAboveLevel.rawValue)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(
                    parameter: command.parameter,
                    value: log.aslFacilityRecordAtAndAboveLevel.rawValue
                ).json.description
            )
        
            
        case .FILE_RECORD_AT_AND_ABOVE_LEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.logfileRecordAtAndAboveLevel = \(log.fileRecordAtAndAboveLevel.rawValue)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(
                    parameter: command.parameter,
                    value: log.fileRecordAtAndAboveLevel.rawValue
                    ).json.description
            )
            
            
        case .STDOUT_PRINT_AT_AND_ABOVE_LEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.stdoutPrintAtAndAboveLevel = \(log.stdoutPrintAtAndAboveLevel.rawValue)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(parameter: command.parameter, value: log.stdoutPrintAtAndAboveLevel.rawValue).json.description
            )
            
            
        case .CALLBACK_AT_AND_ABOVE_LEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.callbackTransmitAtAndAboveLevel = \(log.callbackAtAndAboveLevel.rawValue)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(parameter: command.parameter, value: log.callbackAtAndAboveLevel.rawValue).json.description
            )
            
            
        case .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL:
            
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTransmitAtAndAboveLevel = \(log.networkTransmitAtAndAboveLevel.rawValue)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(parameter: command.parameter, value: log.networkTransmitAtAndAboveLevel.rawValue).json.description
            )
            
            
        case .NETWORK_LOGTARGET_IP_ADDRESS:
            
            let dest = log.networkTarget?.address ?? "Not set"
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTarget.address = \(dest)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(parameter: command.parameter, value: dest).json.description
            )
            
            
        case .NETWORK_LOGTARGET_PORT_NUMBER:
            
            let port = log.networkTarget?.port ?? "0"
            log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Reading, log.networkTarget.port = \(port)")
            
            toConsole?.transferToConsole(
                ReadServerParameterReply(parameter: command.parameter, value: port).json.description
            )
        }
    }

    
    // The network target for the logger
    
    private static var networkLogTarget = SwifterLog.NetworkTarget("","")
    
    
    /// Checks if the networkLogTarget contains two non-empty fields, and if so, tries to connect the logger to the target. After a connection attempt it will empty the fields.
    /// - Returns: True if the connection attempt was made, false otherwise.
    /// - Note: It does not report the sucess/failure of the connection attempt.
    
    private static func conditionallySetNetworkLogTarget() -> Bool {
        if networkLogTarget.address.isEmpty { return false }
        if networkLogTarget.port.isEmpty { return false }
        log.connectToNetworkTarget(networkLogTarget)
        log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Setting the network logtarget to: \(networkLogTarget.address):\(networkLogTarget.port)")
        networkLogTarget.address = ""
        networkLogTarget.port = ""
        return true
    }
    
    static func doWriteServerParameterCommand(socket: Int32, command: WriteServerParameterCommand) {
        
        func updateBool(parameter: ParameterId, newValue: Bool) {
            if newValue != Parameters.asBool(parameter) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Write: \(parameter.rawValue) updating from \(Parameters.asBool(parameter)) to \(newValue)")
                Parameters.pdict[parameter] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "Write: \(parameter.rawValue) new value same as old value: \(newValue)")
            }
        }
        
        func updateInt(parameter: ParameterId, newValue: Int) {
            if newValue != Parameters.asInt(parameter) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asInt(parameter)) to \(newValue)")
                Parameters.pdict[parameter] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as old value: \(newValue)")
            }
        }
        
        func updateDouble(parameter: ParameterId, newValue: Double) {
            if newValue != Parameters.asDouble(parameter) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asDouble(parameter)) to \(newValue)")
                Parameters.pdict[parameter] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as old value: \(newValue)")
            }
        }

        func updateString(parameter: ParameterId, newValue: String) {
            if newValue != Parameters.asString(parameter) {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) updating from \(Parameters.asString(parameter)) to \(newValue)")
                Parameters.pdict[parameter] = newValue
            } else {
                log.atLevelNotice(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value same as old value: \(newValue)")
            }
        }

        
        // Update parameter

        switch command.parameter {
            

        case .DEBUG_MODE,
             .AUTO_STARTUP,
             .HEADER_LOGGING_ENABLED,
             .FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE:
            
            // For the booleans
            
            guard let newValue = command.boolValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a BOOL value")
                return
            }
            
            updateBool(ParameterId.from(command.parameter), newValue: newValue)
            
            
        case .CLIENT_MESSAGE_BUFFER_SIZE,
             .HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT,
             .MAX_NOF_ACCEPTED_CONNECTIONS,
             .MAX_NOF_PENDING_CONNECTIONS,
             .MAX_WAIT_FOR_PENDING_CONNECTIONS,
             .LOGFILE_MAX_SIZE,
             .LOGFILE_MAX_NOF_FILES,
             .MAX_FILE_SIZE_FOR_HEADER_LOGGING,
             .HTTP_RESPONSE_CLIENT_TIMEOUT:
            
            // For the integers
            
            guard let newValue = command.intValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a Int value")
                return
            }
            
            updateInt(ParameterId.from(command.parameter), newValue: newValue)
            
            
        case .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL,
             .FILE_RECORD_AT_AND_ABOVE_LEVEL,
             .CALLBACK_AT_AND_ABOVE_LEVEL,
             .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL,
             .STDOUT_PRINT_AT_AND_ABOVE_LEVEL:
            
            // For the SwifterLog.Level
            
            guard let level = command.intValue, let newLevel = SwifterLog.Level(rawValue: level) else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) new value should be in range 0..8, found \(command.intValue)")
                return
            }
            
            updateInt(ParameterId.from(command.parameter), newValue: newLevel.rawValue)
            
            
        case .SERVICE_PORT_NUMBER,
             .MAC_PORT_NUMBER,
             .NETWORK_LOGTARGET_IP_ADDRESS,
             .NETWORK_LOGTARGET_PORT_NUMBER:
            
            // For the Strings
            
            updateString(ParameterId.from(command.parameter), newValue: command.value)
            
            
        case .MAC_INACTIVITY_TIMEOUT:
            
            guard let newValue = command.doubleValue else {
                log.atLevelWarning(id: socket, source: #file.source(#function, #line), message: "\(command.parameter.rawValue) should contain a NUMBER value")
                return
            }

            // For the Doubles
            
            updateDouble(ParameterId.from(command.parameter), newValue: newValue)
        }
        
        
        // Perform actions where necessary
        
        switch command.parameter {
            
        case .ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL:
            
            log.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level(rawValue: Parameters.asInt(.ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL))!

        case .FILE_RECORD_AT_AND_ABOVE_LEVEL:
            
            log.fileRecordAtAndAboveLevel = SwifterLog.Level(rawValue: Parameters.asInt(.FILE_RECORD_AT_AND_ABOVE_LEVEL))!
            
        case .CALLBACK_AT_AND_ABOVE_LEVEL:
            
            log.callbackAtAndAboveLevel = SwifterLog.Level(rawValue: Parameters.asInt(.CALLBACK_AT_AND_ABOVE_LEVEL))!
            
        case .NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL:
            
            log.networkTransmitAtAndAboveLevel = SwifterLog.Level(rawValue: Parameters.asInt(.NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL))!

        case .STDOUT_PRINT_AT_AND_ABOVE_LEVEL:
            
            log.stdoutPrintAtAndAboveLevel = SwifterLog.Level(rawValue: Parameters.asInt(.STDOUT_PRINT_AT_AND_ABOVE_LEVEL))!

        case .NETWORK_LOGTARGET_IP_ADDRESS:
            
            networkLogTarget.address = Parameters.asString(.NETWORK_LOGTARGET_IP_ADDRESS)
            conditionallySetNetworkLogTarget()

        case .NETWORK_LOGTARGET_PORT_NUMBER:

            networkLogTarget.port = Parameters.asString(.NETWORK_LOGTARGET_PORT_NUMBER)
            conditionallySetNetworkLogTarget()

        default: break
        }
    }

}

// == End of file ==