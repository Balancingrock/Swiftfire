// =====================================================================================================================
//
//  File:       Parameters.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// 0.10.7 - Added adminSiteRoot
//        - Removed SWIFTFIRE_VERSION
// 0.10.6 - Renamed to ServerParameters
//        - Added ServerParameterNames
// 0.10.5 - Increased version number
//        - Fixed bug where the logfileMaxNofFiles returned the logfileMaxSize
// 0.10.2 - Increasing version due to xcode 8.3 changes in SwiftfireConsole
// 0.10.1 - Fixed warnings from Xcode 8.3
// 0.10.0 - Slight modification of description
// 0.9.18 - Updated version number
//        - Added httpsServicePortNumber
//        - Renamed servicePortNumber to httpServicePortNumber
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Added http1_0DomainName
//        - Restructured to singleton instead of statics
//        - Upgraded to Xcode 8 beta 6
// 0.9.13 - Simplified implementation
//        - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.12 - Updated version number
// 0.9.11 - Updated version number
// 0.9.10 - Updated version number
// 0.9.9  - Updated version number
// 0.9.8  - Updated version number
// 0.9.7  - Changed initial value of HTTP_KEEP_ALIVE_INACTIVITY_TIMEOUT to 1 second
//        - Added HEADER_LOGGING_ENABLED, MAX_FILE_SIZE_FOR_HEADER_LOGGING, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
//        - Slightly optimized code to upgrade to new parameter file version
//        - Added function to upgrade to parameter version 2
//        - Moved M&C support for the server parameters to this file
// 0.9.6  - Header update & version number update
//        - Merged MAX_NOF_PENDING_CLIENT_MESSAGES with MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
//        - Merged AutoStartup into this file
// 0.9.5  - Updated version number
// 0.9.4  - Updated version number
// 0.9.3  - Updated version number
// 0.9.2  - Updated version number
// 0.9.0  - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog


public final class ServerParameters: CustomStringConvertible {

    
    /// When this variable is "true" additional code is executed to generate (a lot of) debug information
    ///
    /// - Note: This variable is independant of the logging levels
    ///
    /// Debug: false
    
    public let debugMode = NamedBoolValue(
        name: "DebugMode",
        about: "Will generate extra debug information when true",
        value: false,
        resetValue: false)
    
    
    /// This is the port number upon which http requests will be accepted
    ///
    /// Default: 6678

    public let httpServicePortNumber = NamedStringValue(
        name: "HttpServicePortNumber",
        about: "The port number on which HTTP requests will be accepted",
        value: "6678",
        resetValue: "6678")

    
    /// This is the port number upon which https requests will be accepted
    ///
    /// Default: 6679
    
    public let httpsServicePortNumber = NamedStringValue(
        name: "HttpsServicePortNumber",
        about: "The port number on which HTTPS requests will be accepted",
        value: "6679",
        resetValue: "6679")
    
    
    /// This is the maximum number of (parralel) http connection requests that Swiftfire accepts. Any more than this will become pending.
    ///
    /// Default: 20

    public let maxNofAcceptedConnections = NamedIntValue(
        name: "MaxNofAcceptedConnections",
        about: "The maximum number of concurrent HTTP and/or HTTPS requests accepted",
        value: 20,
        resetValue: 20)
    
    
    /// This is the maximum number of http connection requests that are kept pending. Any more than this and will be rejected.
    ///
    /// Default: 20

    public let maxNofPendingConnections = NamedIntValue(
        name: "MaxNofPendingConnections",
        about: "The maximum number of HTTP and HTTPS requests accepted",
        value: 20,
        resetValue: 20)
    
    
    /// This is the maximum time a pending connection request is kept waiting before it is rejected.
    ///
    /// Default: 30 [Seconds]

    public let maxWaitForPendingConnections = NamedIntValue(
        name: "MaxWaitForPendingConnections",
        about: "The maximum duration for a request to be kept pending [Sec]",
        value: 30,
        resetValue: 30)
    
    
    /// The maximum size of a http message that can be received from client.
    ///
    /// Default: 32 * 1024 [bytes]

    public let clientMessageBufferSize = NamedIntValue(
        name: "ClientMessageBufferSize",
        about: "The maximum size of a HTTP(S) request message [bytes]",
        value: 32 * 1024,
        resetValue: 32 * 1024)
    
    
    /// When a HTTP request has the "keep alive" option set, the connection will remain open for this time after the last data block was processed from that client.
    ///
    /// Default: 500 [mSec]

    public let httpKeepAliveInactivityTimeout = NamedIntValue(
        name: "HttpKeepAliveInactivityTimeout",
        about: "The time a keep-alive request will be honoured [mSec]",
        value: 500,
        resetValue: 500)
    
    
    /// When data has to be transferred to a client, this is the timeout for the transmit operation.
    ///
    /// Default: 10 [Sec]

    public let httpResponseClientTimeout = NamedIntValue(
        name: "HttpResponseClientTimeout",
        about: "The timeout for replies to a client [Sec]",
        value: 10,
        resetValue: 10)
    
    
    /// When the M&C connection has been established, it will remain locked to the given connection until no activity has been detected for this amount of time. Note that when a console periodically retrieves telemetry, that interval should be shorter than this inactvity timeout or else another console could take over. Time is in seconds.
    ///
    /// Default: 600 [Sec]
    
    public let macInactivityTimeout = NamedIntValue(
        name: "MacInactivityTimeout",
        about: "Close the M&C connection when inactive for this long [Sec]",
        value: 600,
        resetValue: 600)
    
    
    /// When set to true the http server will automatically be started upon start of the application. Note that domains should be defined and active for this to have any effect.
    ///
    /// Default: True

    public let autoStartup = NamedBoolValue(
        name: "AutoStartup",
        about: "When 'true', the HTTP/S servers will be started on application boot.",
        value: true,
        resetValue: true)
    
    
    /// The port number on which Swiftfire will listen for M&C connections.
    ///
    /// Default: 2043
    
    public let macPortNumber = NamedStringValue(
        name: "MonitoringAndControlPortNumber",
        about: "The port number on which M&C connections will be accepted.",
        value: "2043",
        resetValue: "2043")
    

    /// The ASL threshold, logging information at this level (or above) will be written to the ASL Facility
    ///
    /// Default: 2 = SwifterLog.Level.notice

    public let aslFacilityRecordAtAndAboveLevel = NamedIntValue(
        name: "AslLogLevel",
        about: "The minimum loglevel for entries written to the ASL [0..8].",
        value: 2,
        resetValue: 2)
    
    
    /// The stdout threshold, logging information at this level (or above) will be written to stdout (terminal/xcode console)
    ///
    /// Default: 8 = SwifterLog.Level.none
    
    public let stdoutPrintAtAndAboveLevel = NamedIntValue(
        name: "StdoutLogLevel",
        about: "The minimum loglevel for entries written to STDOUT [0..8].",
        value: 8,
        resetValue: 8)
    
    
    /// The callback threshold, logging information at this level (or above) will be send to the Swiftfire Console
    ///
    /// Default: 8 = SwifterLog.Level.none

    public let callbackAtAndAboveLevel = NamedIntValue(
        name: "CallbackLogLevel",
        about: "The minimum loglevel for the callback destination(s) [0..8].",
        value: 8,
        resetValue: 8)
    
    
    /// The file logging threshold, logging information at this level (or above) will be written to the logfile.
    ///
    /// Default: 8 = SwifterLog.Level.none

    public let fileRecordAtAndAboveLevel = NamedIntValue(
        name: "FileLogLevel",
        about: "The minimum loglevel for entries written to file [0..8].",
        value: 8,
        resetValue: 8)
    
    
    /// The maximum size of a single logfile (in kbytes)
    ///
    /// 1000 [KByte]

    public let logfileMaxSize = NamedIntValue(
        name: "LogfileMaxSize",
        about: "The (about) maximum size of a single longfile [KByte].",
        value: 1000,
        resetValue: 1000)
    
    
    /// The maximum number of logfiles that will be kept in the logfile directory
    ///
    /// Default: 20

    public let logfileMaxNofFiles = NamedIntValue(
        name: "LogfileMaxNofFiles",
        about: "The maximum number of logfiles.",
        value: 20,
        resetValue: 20)
    
    
    /// The network target threshold, logging information at this level (or above) will be sent to the network destination.
    ///
    /// Default: 8 = SwifterLog.Level.none

    public let networkTransmitAtAndAboveLevel = NamedIntValue(
        name: "NetworkLogLevel",
        about: "The minimum loglevel for the network destination [0..8].",
        value: 8,
        resetValue: 8)
    
    
    /// The IP Address for the network logging target
    ///
    /// Default = ""
    
    public let networkLogtargetIpAddress = NamedStringValue(
        name: "NetworkLogTargetAddress",
        about: "The IP address for a network log destination.",
        value: "",
        resetValue: "")
    
    
    /// The port number for the network logging target
    ///
    /// Default = ""
    
    public let networkLogtargetPortNumber = NamedStringValue(
        name: "NetworkLogTargetPort",
        about: "The port number for a network log destination.",
        value: "",
        resetValue: "")
    
    
    /// Enables/Disables logging of all request headers
    ///
    /// Default: false

    public let headerLoggingEnabled = NamedBoolValue(
        name: "HeaderLoggingEnabled",
        about: "Enables/Disables header logging at the server wide level.",
        value: false,
        resetValue: false)
    
    
    /// The maximum file size for header logging (in kbytes)
    ///
    /// Default: 1000 [KByte]

    public let maxFileSizeForHeaderLogging = NamedIntValue(
        name: "MaxFileSizeForHeaderLogging",
        about: "The (about) maximum filesize for the server wide headerlog file. [KByte]",
        value: 1000,
        resetValue: 1000)
    
    
    /// Synchronize the header logging file after each write
    ///
    /// Default: false

    public let flushHeaderLogfileAfterEachWrite = NamedBoolValue(
        name: "FlushHeaderLogfileAfterEachWrite",
        about: "Ensures that the header logfile is written to disk after each entry.",
        value: false,
        resetValue: false)

    
    /// The domain name for http 1.0 requests
    ///
    /// Default: ""
    
    public let http1_0DomainName = NamedStringValue(
        name: "Http1_0DomainName",
        about: "The domain for HTTP(S) 1.0 requests",
        value: "",
        resetValue: "")
    
    
    /// The cache size of the SFDocument cache in MB
    ///
    /// Default: 100 [MByte]
    
    public let sfDocumentCacheSize = NamedIntValue(
        name: "SFDocumentCacheSize",
        about: "The size of the SF document cache size [MB]",
        value: 100,
        resetValue: 100)
    
    
    /// The root of the server admin site
    ///
    /// Default: None.
    
    public let adminSiteRoot = NamedStringValue(
        name: "ServerAdminSiteRoot",
        about: "The root directory for the server admin site",
        value: "",
        resetValue: "")
    
    
    /// All parameters
    
    public private(set) var all: Array<NamedValueProtocol> = []
    
    
    /// Create a new object.

    public init() {
        
        // Note: No literal array used because of compilation times.

        all.append(httpServicePortNumber)
        all.append(httpsServicePortNumber)
        all.append(maxNofAcceptedConnections)
        all.append(maxNofPendingConnections)
        all.append(maxWaitForPendingConnections)
        all.append(clientMessageBufferSize)
        all.append(httpKeepAliveInactivityTimeout)
        all.append(httpResponseClientTimeout)
        all.append(debugMode)
        all.append(aslFacilityRecordAtAndAboveLevel)
        all.append(stdoutPrintAtAndAboveLevel)
        all.append(fileRecordAtAndAboveLevel)
        all.append(callbackAtAndAboveLevel)
        all.append(networkTransmitAtAndAboveLevel)
        all.append(networkLogtargetIpAddress)
        all.append(networkLogtargetPortNumber)
        all.append(autoStartup)
        all.append(macPortNumber)
        all.append(macInactivityTimeout)
        all.append(logfileMaxSize)
        all.append(logfileMaxNofFiles)
        all.append(maxFileSizeForHeaderLogging)
        all.append(headerLoggingEnabled)
        all.append(flushHeaderLogfileAfterEachWrite)
        all.append(http1_0DomainName)
        all.append(sfDocumentCacheSize)
        all.append(adminSiteRoot)
    }
    
    
    /// Updates the parameter values from the parameter-defaults.json file if that file exists. It only updates those values that are found in the defaults file. All other parameters remain at their hard-coded default values. Parameters found in the defaults file that are not (no longer?) used will be flagged as errors in the log.
    
    public func restore(fromFile url: URL) -> FunctionResult<String> {
                
        
        // Does the parameter defaults file exist?
        
        guard url.isFileURL && FileManager.default.fileExists(atPath: url.path) else {
            return .success("No 'parameter-defaults.json' file present, starting with hard coded defaults.")
        }

        
        // Parse the parameter defaults file
        
        guard let json = try? VJson.parse(file: url) else {
            return .error(message: "Could not retrieve JSON code from parameter-defaults file.")
        }

        
        // Update the parameters
        
        var message = ""
        for item in all {
            if let strval = (json|item.name)?.stringValue {
                if item.setValue(strval) {
                    json.remove(childrenWith: item.name)
                } else {
                    message += "Failed to set value for \(item.name) to \(strval)\n"
                }
            } else {
                message += "Missing value for \(item.name)\n"
            }
        }
        if message != "" { return .error(message: message) }
            
        if json.nofChildren != 0 {
            return .error(message: "Superfluous items in source: \(json.code)")
        }

        
        return .success(message)
    }
    
    
    /// Save the parameter dictionary contents to the 'domains-default.json' file.

    public func save(toFile url: URL) {
        
        let json = VJson()
        all.forEach({
            json[$0.name] &= $0.stringValue
        })
        json.save(to: url)
    }
    
    
    public var description: String {
        var str = "Parameters:\n"
        str += all.map({ " \($0.name) = \($0.stringValue)" }).joined(separator: "\n")
        return str
    }
}
