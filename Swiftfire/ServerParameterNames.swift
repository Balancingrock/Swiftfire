// =====================================================================================================================
//
//  File:       ServerParameterNames.swift
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
// v0.9.14 - Added http1_0DomainName
//         - Renamed to ServerParameterNames.swift
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.7  - Added HEADER_LOGGING_ENABLED, MAX_FILE_SIZE_FOR_HEADER_LOGGING,
//           MAX_FILE_SIZE_FOR_ACCESS_LOGGING, FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE
//         - Added missing parameters from parameter version 1, harmonized names between ParameterIds and ServerParameters
// v0.9.6  - Header update
//         - Merged MAX_NOF_PENDING_CLIENT_MESSAGES and MAX_CLIENT_MESSAGE_SIZE into CLIENT_MESSAGE_BUFFER_SIZE
//         - Merged Auto-Startup into Parameters, added configuration of more logging options
// v0.9.4  - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation

enum ServerParameterName: String {
    
    case servicePortNumber = "ServicePortNumber"
    case maxNumberOfAcceptedConnections = "MaxNofAcceptedConnections"
    case maxNumberOfPendingConnections = "MaxNofPendingConnections"
    case maxWaitForPendingConnections = "MaxWaitForPendingConnections"
    case clientMessageBufferSize = "ClientMessageBufferSize"
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
    case http1_0DomainName = "Http1_0DomainName"

    static let all: Array<ServerParameterName> = [.servicePortNumber, .maxNumberOfAcceptedConnections, .maxNumberOfPendingConnections, .maxWaitForPendingConnections, .clientMessageBufferSize, .httpKeepAliveInactivityTimeout, .httpResponseClientTimeout, .debugMode, .aslFacilityRecordAtAndAboveLevel, .stdoutPrintAtAndAboveLevel, .fileRecordAtAndAboveLevel, .callbackAtAndAboveLevel, .networkTransmitAtAndAboveLevel, .networkLogtargetIpAddress, .networkLogtargetPortNumber, .autoStartup, .macPortNumber, .macInactivityTimeout, .logfileMaxSize, .logfileMaxNofFiles, .maxFileSizeForHeaderLogging, .headerLoggingEnabled, .flushHeaderLogfileAfterEachWrite, .http1_0DomainName]
}
