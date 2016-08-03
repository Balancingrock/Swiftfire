// =====================================================================================================================
//
//  File:       main.swift
//  Project:    Swiftfire
//
//  Version:    0.9.12
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
import CoreData


// Every thread that runs for more than a few milliseconds should poll this variable and terminate itself when it finds that this flag is 'true'.

var quitSwiftfire: Bool = false


// Purpose: Set default logging levels to gain some output if anything goes wrong before the log levels are set to the application values

log.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level.notice
log.fileRecordAtAndAboveLevel = SwifterLog.Level.none
log.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
log.callbackAtAndAboveLevel = SwifterLog.Level.none
log.networkTransmitAtAndAboveLevel = SwifterLog.Level.none


// ====================================================
// Load parameters and domains from file (if available)
// ====================================================

Parameters.restore()

if !domains.restore()  {
    log.atLevelEmergency(id: -1, source: "Main", message: "Swiftfire terminated because the default domains could not be read")
    sleep(5)
    exit(EXIT_FAILURE)
}


// =======================================
// Start of application: Configure logging
// =======================================

log.fileRecordAtAndAboveLevel = Parameters.fileRecordAtAndAboveLevel
log.logfileDirectoryPath = FileURLs.applicationLogDir!.path!
log.logfileMaxNumberOfFiles = Parameters.logfileMaxNofFiles
log.logfileMaxSizeInBytes = UInt64(Parameters.logfileMaxSize) * 1024

log.aslFacilityRecordAtAndAboveLevel = Parameters.aslFacilityRecordAtAndAboveLevel
log.stdoutPrintAtAndAboveLevel = Parameters.stdoutPrintAtAndAboveLevel
log.callbackAtAndAboveLevel = Parameters.callbackAtAndAboveLevel

log.networkTransmitAtAndAboveLevel = Parameters.networkTransmitAtAndAboveLevel
if (Parameters.networkLogtargetIpAddress != "") && (Parameters.networkLogtargetPortNumber != "") {
    let nettar = SwifterLog.NetworkTarget(address: Parameters.networkLogtargetIpAddress, port: Parameters.networkLogtargetPortNumber)
    log.connectToNetworkTarget(nettar)
}


// ======================================
// Configure callback for log information
// ======================================

class LogForewarder: SwifterlogCallbackProtocol {
    
    // Purpose: To send the logging information to the Console if a console is attached.
    
    // Note that this function is only called if the callback levels of the logger are set accordingly.
    
    func logInfo(_ time: Date, level: SwifterLog.Level, source: String, message: String) {
        if let console = toConsole {
            let logline = LogLine(time: time as Date, level: level, source: source, message: message)
            console.transferToConsole(message: logline.json.description)
        }
    }
}

let logforewarder = LogForewarder()

log.registerCallback(logforewarder)
    

// =========================================================================
// Show the paremeter settings and available domains in the log destinations
// =========================================================================

// Purpose: To provide an audit trail of the settings under which Swiftfire operates.

Parameters.logParameterSettings(atLevel: .notice)
domains.writeToLog(atLevel: .notice)


// =========================================================
// Initialize the port for the Command and Control interface
// =========================================================

log.atLevelNotice(id: -1, source: "Main", message: "Initializing M&C loop")

let result: SwifterSockets.SetupServerReturn = SwifterSockets.setupServer(
    onPort: Parameters.macPortNumber,
    maxPendingConnectionRequest: 1)

switch result {
    
case let SwifterSockets.SetupServerReturn.socket(socket):
    
    log.atLevelNotice(id: -1, source: "Main", message: "Listening for M&C connections")

    
    // Setup the Monotoring and control loop
    
    let mac = MonitoringAndControl()


    // Autostart http server if necessary
    
    if Parameters.autoStartup { ServerStartCommand().execute() }

    
    // Start the monitoring and control loop (this function returns when the M&C loop ends)
    
    mac.acceptAndReceiveLoop(onSocket: socket)
    
    
    // Cleanup
    
    SwifterSockets.closeSocket(socket)
    
    statistics.save()
    
    HttpHeader.closeHeaderLoggingFile()
    
    log.atLevelNotice(id: -1, source: "Main", message: "Swiftfire terminated normally")
    
    
    // Give other tasks time to complete

    sleep(10)

    exit(EXIT_SUCCESS)
    
    
case let SwifterSockets.SetupServerReturn.error(errstr):
    
    log.atLevelEmergency(id: -1, source: "Main", message: "Swiftfire terminated with error '\(errstr)'")

    sleep(10)
    
    exit(EXIT_FAILURE)
}


// === End ===
