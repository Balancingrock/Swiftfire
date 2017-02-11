// =====================================================================================================================
//
//  File:       main.swift
//  Project:    Swiftfire
//
//  Version:    0.9.15
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
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// v0.9.15 - General update and switch to frameworks
// v0.9.14 - Added loading of server level blacklisted clients
//         - Upgraded to Xcode 8 beta 6
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Switched to 'toConsole' protocol (in Comms.swift) for communication with the console.
// v0.9.11 - Moved some global definitions to other files
// v0.9.7  - Added closing of header logging file on normal termination
//         - Changed logging of parameters and domains to occur after the setup of the logger
// v0.9.6  - Header update
//         - Merged Startup into Parameters
// v0.9.3  - Added serverTelemetry
// v0.9.1  - Minor changes to accommodate changes in SwifterSockets and SwifterLog
// v0.9.0  - Initial release
// =====================================================================================================================


import Foundation
import SwifterLog
import SwifterSockets


// Every thread that runs for more than a few milliseconds should poll this variable and terminate itself when it finds that this flag is 'true'.

var quitSwiftfire: Bool = false


// Purpose: Set default logging levels to gain some output if anything goes wrong before the log levels are set to the application values

log.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level.notice
log.fileRecordAtAndAboveLevel = SwifterLog.Level.none
log.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
log.callbackAtAndAboveLevel = SwifterLog.Level.none
log.networkTransmitAtAndAboveLevel = SwifterLog.Level.none


// =========================
// Initialize the parameters
// =========================

parameters.restore()


// =======================================
// Start of application: Configure logging
// =======================================

log.fileRecordAtAndAboveLevel = parameters.fileRecordAtAndAboveLevel
log.logfileDirectoryPath = FileURLs.applicationLogDir!.path
log.logfileMaxNumberOfFiles = parameters.logfileMaxNofFiles
log.logfileMaxSizeInBytes = UInt64(parameters.logfileMaxSize) * 1024

log.aslFacilityRecordAtAndAboveLevel = parameters.aslFacilityRecordAtAndAboveLevel
log.stdoutPrintAtAndAboveLevel = parameters.stdoutPrintAtAndAboveLevel
log.callbackAtAndAboveLevel = parameters.callbackAtAndAboveLevel

log.networkTransmitAtAndAboveLevel = parameters.networkTransmitAtAndAboveLevel
if (parameters.networkLogtargetIpAddress != "") && (parameters.networkLogtargetPortNumber != "") {
    let nettar = SwifterLog.NetworkTarget(address: parameters.networkLogtargetIpAddress, port: parameters.networkLogtargetPortNumber)
    log.connectToNetworkTarget(nettar)
}


// ======================================
// Configure callback for log information
// ======================================

class LogForewarder: SwifterlogCallbackProtocol {
    
    // Purpose: To send the logging information to the Console if a console is attached.
    
    // Note that this function is only called if the callback levels of the logger are set accordingly.
    
    func logInfo(_ time: Date, level: SwifterLog.Level, source: String, message: String) {
        if let mac = mac {
            let logline = LogLine(time: time as Date, level: level, source: source, message: message)
            mac.transfer(LogLineReply(logline))
        }
    }
}

let logforewarder = LogForewarder()

log.registerCallback(logforewarder)


// ======================================
// Provide an audit trail of the settings
// ======================================

log.atLevelNotice(id: -1, source: "Main", message: "Parameter values initialized to:")
parameters.logParameterSettings(atLevel: .notice)


// ===============================================
// Initialize the server level blacklisted clients
// ===============================================

let serverBlacklist = Blacklist()

if let url = FileURLs.serverBlacklist {
    if serverBlacklist.load(fromFileLocation: url) {
        log.atLevelNotice(id: -1, source: "Main", message: "Server blacklist loaded.")
        serverBlacklist.writeToLog(atLevel: SwifterLog.Level.notice)
    } else {
        if FileManager.default.isReadableFile(atPath: url.path) {
            log.atLevelEmergency(id: -1, source: "Main", message: "Swiftfire terminated because the server blacklist file contains an error")
            sleep(5)
            exit(EXIT_FAILURE)
        } else {
            log.atLevelEmergency(id: -1, source: "Main", message: "No (readable)file for server blacklist found")
        }
    }
} else {
    log.atLevelEmergency(id: -1, source: "Main", message: "Swiftfire terminated because the directory for the server blacklist file could not be found/created")
    sleep(5)
    exit(EXIT_FAILURE)
}


// ======================
// Initialize the domains
// ======================

if !domains.restore()  {
    log.atLevelEmergency(id: -1, source: "Main", message: "Swiftfire terminated because the default domains could not be read")
    sleep(5)
    exit(EXIT_FAILURE)
}

// Audit trail

domains.writeToLog(atLevel: .notice)


// =======================
// Prepare the HTTP server
// =======================

private let acceptQueue = DispatchQueue(
    label: "Http Server Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

let httpServer = SwifterSockets.TipServer(
    .port(parameters.httpServicePortNumber),
    .maxPendingConnectionRequests(Int(parameters.maxNofPendingConnections)),
    .acceptQueue(acceptQueue),
    .connectionObjectFactory(httpConnectionFactory),
    .acceptLoopDuration(2),
    .errorHandler(httpServerErrorHandler))


// =========================================================
// Initialize the port for the Command and Control interface
// =========================================================

log.atLevelNotice(id: -1, source: "Main", message: "Initializing M&C loop")

private let macAcceptQueue = DispatchQueue(
    label: "M&C Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

let macServer = SwifterSockets.TipServer(
    .port(parameters.macPortNumber),
    .maxPendingConnectionRequests(1),
    .acceptQueue(macAcceptQueue),
    .connectionObjectFactory(macConnectionFactory),
    .acceptLoopDuration(10),
    .errorHandler(macErrorHandler))


// Start the monitoring and control loop

switch macServer.start() {
    
case let .error(message):
    
    log.atLevelEmergency(id: -1, source: "Main", message: "Swiftfire terminated with error '\(message)'")
    
    sleep(10)
    
    exit(EXIT_FAILURE)
    
    
case .success:
    
    log.atLevelNotice(id: -1, source: "Main", message: "Listening for M&C connections")
    
    // ==================================
    // Autostart http server if necessary
    // ==================================
    
    if parameters.autoStartup { ServerStartCommand().execute() }
    
    
    // Wait for the 'quit' command
    
    while !quitSwiftfire { sleep(2) }
    
    
    // Cleanup
    
    statistics.save()
    log.atLevelNotice(id: -1, source: "Main", message: "Saved statistics")
    
    HttpHeader.closeHeaderLoggingFile()
    log.atLevelNotice(id: -1, source: "Main", message: "Closed header logging file")
    
    if let url = FileURLs.serverBlacklist {
        serverBlacklist.save(toFileLocation: url)
        log.atLevelNotice(id: -1, source: "Main", message: "Saved server blacklist")
    }
    
    domains.serverShutdown()
    
    log.atLevelNotice(id: -1, source: "Main", message: "Swiftfire terminated normally")
    
    
    // Give other tasks time to complete
    
    sleep(10)
    
    exit(EXIT_SUCCESS)
}


// === End ===
