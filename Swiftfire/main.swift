// =====================================================================================================================
//
//  File:       main.swift
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
// v0.9.7 - Added closing of header logging file on normal termination
//        - Changed logging of parameters and domains to occur after the setup of the logger
// v0.9.6 - Header update
//        - Merged Startup into Parameters
// v0.9.3 - Added serverTelemetry
// v0.9.1 - Minor changes to accommodate changes in SwifterSockets and SwifterLog
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// The queue on which Swiftfire will accept client connection requests

let acceptQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)


// When this variable is set to 'true' the monitoring and control loop will terminate and thereby terminate Swiftfire

var abortMacLoop: Bool = false


// The server telemetry

let serverTelemetry = ServerTelemetry()


// The available domains

var domains: Domains = Domains()


// ====================================================
// Load parameters and domains from file (if available)
// ====================================================

if !Parameters.restore() {
    log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Swiftfire terminated because the default parameters could not be determined")
    sleep(5)
    exit(EXIT_FAILURE)
}

if !domains.restore()  {
    log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Swiftfire terminated because the default domains could not be read")
    sleep(5)
    exit(EXIT_FAILURE)
}


// =======================================
// Start of application: Configure logging
// =======================================

log.logfileDirectoryPath = FileURLs.applicationLogDir!.path!

if let threshold = SwifterLog.Level(rawValue: Parameters.asInt(.ASL_FACILITY_RECORD_AT_AND_ABOVE_LEVEL)) {
    log.aslFacilityRecordAtAndAboveLevel = threshold
}

if let threshold = SwifterLog.Level(rawValue: Parameters.asInt(.FILE_RECORD_AT_AND_ABOVE_LEVEL)) {
    log.fileRecordAtAndAboveLevel = threshold
}

if Parameters.asString(.LOGFILES_FOLDER) != "" {
    log.logfileDirectoryPath = Parameters.asString(.LOGFILES_FOLDER)
}

log.logfileMaxNumberOfFiles = Parameters.asInt(.LOGFILE_MAX_NOF_FILES)

log.logfileMaxSizeInBytes = UInt64(Parameters.asInt(.LOGFILE_MAX_SIZE) * 1024)

if let threshold = SwifterLog.Level(rawValue: Parameters.asInt(.STDOUT_PRINT_AT_AND_ABOVE_LEVEL)) {
    log.stdoutPrintAtAndAboveLevel = threshold
}

if let threshold = SwifterLog.Level(rawValue: Parameters.asInt(.CALLBACK_AT_AND_ABOVE_LEVEL)) {
    log.callbackAtAndAboveLevel = threshold
}

if let threshold = SwifterLog.Level(rawValue: Parameters.asInt(.NETWORK_TRANSMIT_AT_AND_ABOVE_LEVEL)) {
    log.networkTransmitAtAndAboveLevel = threshold
}

if (Parameters.asString(.NETWORK_LOGTARGET_IP_ADDRESS) != "") && (Parameters.asString(.NETWORK_LOGTARGET_PORT_NUMBER) != "") {
    log.connectToNetworkTarget(address: Parameters.asString(.NETWORK_LOGTARGET_IP_ADDRESS), port: Parameters.asString(.NETWORK_LOGTARGET_PORT_NUMBER))
}


// ======================================
// Configure callback for log information
// ======================================

class LogForewarder: SwifterlogCallbackProtocol {
    func logInfo(time: NSDate, level: SwifterLog.Level, source: String, message: String) {
        let logline = LogLine(time: time, level: level, source: source, message: message)
        mac.transferMessage(logline.json)
    }
}

let logforewarder = LogForewarder()

log.registerCallback(logforewarder)


// =========================================================================
// Show the paremeter settings and available domains in the log destinations
// =========================================================================

Parameters.logParameterSettings()
domains.logDomains()


// =========================================================
// Initialize the port for the Command and Control interface
// =========================================================

log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Initializing M&C loop")

let result: SwifterSockets.InitServerReturn = SwifterSockets.initServer(
    port: Parameters.asString(.MAC_PORT_NUMBER),
    maxPendingConnectionRequest: 1)

switch result {
    
case let SwifterSockets.InitServerReturn.SOCKET(socket):
    
    log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Listening for M&C connections")
    
    
    // This function returns when the M&C loop ends
    
    mac.acceptAndReceiveLoop(socket)
    
    SwifterSockets.closeSocket(socket)
    
    HttpHeader.closeHeaderLoggingFile()
    
    
    // Give other tasks time to complete
    
    sleep(10)
    
    log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Swiftfire terminated normally")
    
    exit(EXIT_SUCCESS)
    
    
case let SwifterSockets.InitServerReturn.ERROR(errstr):
    
    log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Swiftfire terminated with error '\(errstr)'")
    
    exit(EXIT_FAILURE)
}


// === End ===