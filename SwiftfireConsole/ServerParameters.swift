// =====================================================================================================================
//
//  File:       ServerParameters.swift
//  Project:    SwiftfireConsole
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

typealias ValidateStringValueFunction = (String?) -> String?

func validateAsBool(_ value: String?) -> String? {
    guard let value = value, !value.isEmpty else {
        return "Empty value not allowed"
    }
    if let _ = Bool(value) {
        return nil
    } else {
        return "Cannot convert '\(value)' to a boolean.\nExpected one of: 0, 1, false, true, no, yes"
    }
}

func validateAsString(_ value: String?) -> String? {
    guard let value = value, !value.isEmpty else {
        return "Empty value not allowed"
    }
    return value
}

func validateAsInteger(_ value: String?) -> String? {
    guard let value = value, !value.isEmpty else {
        return "Empty value not allowed"
    }
    if let iv = Int(value) {
        if value == iv.description { return nil }
        return "Invalid characters in integer"
    } else {
        return "Cannot convert '\(value)' to an integer"
    }
}

func validateAsDouble(_ value: String?) -> String? {
    guard let value = value, !value.isEmpty else {
        return "Empty value not allowed"
    }
    if let iv = Double(value) {
        if value == iv.description { return nil }
        return "Invalid characters in double"
    } else {
        return "Cannot convert '\(value)' to a double"
    }
}

func validateAsLogLevel(_ value: String?) -> String? {
    guard let value = value, !value.isEmpty else {
        return "Empty value not allowed"
    }
    if let iv = Int(value) {
        if value != iv.description { return "Invalid characters in integer" }
        if iv < 0 && iv > 8 { return "Level should be in range 0..8" }
        return nil
    } else {
        return "Cannot convert '\(value)' to an integer"
    }
}

struct ServerParameter {
    let name: ServerParameterName // Used in the commands between Swiftfire and the Console, also used in fetch requests.
    let label: String // Used as the description for the parameter in the ServerParametersWindow
    let sequence: Int16 // Determines the row in which this parameter will be displayed (0 = top, Int16'max = bottom)
    let validation: ValidateStringValueFunction
}

let serverParameterArray: Array<ServerParameter> = [
    ServerParameter(
        name: ServerParameterName.macPortNumber,
        label: "Number of M&C port (on next start, if saved)",
        sequence: 100,
        validation: validateAsString),
    ServerParameter(
        name: ServerParameterName.macInactivityTimeout,
        label: "Close M&C connection after it was inactive for this long",
        sequence: 110,
        validation: validateAsDouble),
    ServerParameter(
        name: ServerParameterName.servicePortNumber,
        label: "HTTP Service Port Number (usually: 80)",
        sequence: 300,
        validation: validateAsString),
    ServerParameter(
        name: ServerParameterName.maxNumberOfAcceptedConnections,
        label: "Maximum Number of Client Connections in Parallel",
        sequence: 310,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.maxNumberOfPendingConnections,
        label: "Maximum Number of Pending Client Connections",
        sequence: 320,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.maxWaitForPendingConnections,
        label: "Maximum Wait for Pending Client Connections",
        sequence: 330,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.clientMessageBufferSize,
        label: "Size of the Client Message Buffer in Bytes",
        sequence: 340,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.httpKeepAliveInactivityTimeout,
        label: "Inactivity Timeout for accepted connections with 'keep-alive' set to 'true'",
        sequence: 350,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.httpResponseClientTimeout,
        label: "Timeout for a client to accept a response",
        sequence: 360,
        validation: validateAsDouble),
    ServerParameter(
        name: ServerParameterName.autoStartup,
        label: "Goto 'Running' on application start",
        sequence: 400,
        validation: validateAsBool),
    ServerParameter(
        name: ServerParameterName.debugMode,
        label: "Enable more Debug Information to be Logged",
        sequence: 500,
        validation: validateAsBool),
    ServerParameter(
        name: ServerParameterName.aslFacilityRecordAtAndAboveLevel,
        label: "Send Logging at this -and above- level to the ASL Facility",
        sequence: 600,
        validation: validateAsLogLevel),
    ServerParameter(
        name: ServerParameterName.stdoutPrintAtAndAboveLevel,
        label: "Send Logging at this -and above- level to stdout (console)",
        sequence: 700,
        validation: validateAsLogLevel),
    ServerParameter(
        name: ServerParameterName.fileRecordAtAndAboveLevel,
        label: "Send Logging at this -and above- level to the Logfiles",
        sequence: 800,
        validation: validateAsLogLevel),
    ServerParameter(
        name: ServerParameterName.logfileMaxNofFiles,
        label: "Maximum number of logfiles",
        sequence: 810,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.logfileMaxSize,
        label: "Maximum size of a logfile",
        sequence: 820,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.callbackAtAndAboveLevel,
        label: "Send Logging at this -and above- level to the console",
        sequence: 900,
        validation: validateAsLogLevel),
    ServerParameter(
        name: ServerParameterName.networkTransmitAtAndAboveLevel,
        label: "Send Logging at this -and above- level to a Network Target",
        sequence: 1000,
        validation: validateAsLogLevel),
    ServerParameter(
        name: ServerParameterName.networkLogtargetIpAddress,
        label: "The Network Target IP Address for Logging",
        sequence: 1010,
        validation: validateAsString),
    ServerParameter(
        name: ServerParameterName.networkLogtargetPortNumber,
        label: "The Network Target Port for logging",
        sequence: 1020,
        validation: validateAsString),
    ServerParameter(
        name: ServerParameterName.headerLoggingEnabled,
        label: "Enables logging of the full HTTP header",
        sequence: 1100,
        validation: validateAsBool),
    ServerParameter(
        name: ServerParameterName.maxFileSizeForHeaderLogging,
        label: "Maximum File Size of a Header Logfile",
        sequence: 1110,
        validation: validateAsInteger),
    ServerParameter(
        name: ServerParameterName.flushHeaderLogfileAfterEachWrite,
        label: "Forces a file-write after each received HTTP header",
        sequence: 1200,
        validation: validateAsBool),
    ServerParameter(
        name: ServerParameterName.http1_0DomainName,
        label: "Maps HTTP 1.0 requests to a domain specification",
        sequence: 1210,
        validation: validateAsString)
]

let serverParameterDictionary: Dictionary<String, ServerParameter> = {
    var tmp: Dictionary<String, ServerParameter> = [:]
    for p in serverParameterArray { tmp[p.name.rawValue] = p }
    return tmp
}()
