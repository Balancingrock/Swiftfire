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
// 0.9.15  - General update and switch to frameworks
// 0.9.14  - Added loading of server level blacklisted clients
//         - Upgraded to Xcode 8 beta 6
// 0.9.13  - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.12  - Switched to 'toConsole' protocol (in Comms.swift) for communication with the console.
// 0.9.11  - Moved some global definitions to other files
// 0.9.7   - Added closing of header logging file on normal termination
//         - Changed logging of parameters and domains to occur after the setup of the logger
// 0.9.6   - Header update
//         - Merged Startup into Parameters
// 0.9.3   - Added serverTelemetry
// 0.9.1   - Minor changes to accommodate changes in SwifterSockets and SwifterLog
// 0.9.0   - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// The main operation for the Swiftfire webserver.
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwiftfireCore
import SecureSockets
import SwifterSockets


// Make the optional loglevel loggers easier accessable

typealias Log = SwifterLog


// Every thread that runs for more than a few milliseconds should poll this variable and terminate itself when it finds that this flag is 'true'.

var quitSwiftfire: Bool = false


// Create the logger

let log = SwifterLog.theLogger


// Set default logging levels to gain some output if anything goes wrong before the log levels are set to the application values

log.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level.none
log.fileRecordAtAndAboveLevel = SwifterLog.Level.none
log.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
log.callbackAtAndAboveLevel = SwifterLog.Level.none
log.networkTransmitAtAndAboveLevel = SwifterLog.Level.none


// =======================================
// Initialize the configuration parameters
// =======================================

let parameters = Parameters()

guard let parameterDefaultFile = FileURLs.parameterDefaultsFile else {
    /// If the FileURLs module could not create the filename, something is seriously wrong.
    log.atLevelEmergency(id: -1, source: "Main", message: "Could not construct parameter defaults filename, aborting...")
    sleep(1) // Allow the error messages to percolate through the system
    fatalError("Could not construct parameter defaults filename, aborting...")
}

switch parameters.restore(fromFile: parameterDefaultFile) {
    
case let .error(message):
    log.atLevelEmergency(id: -1, source: "Main", message: message)
    sleep(1) // Allow the error messages to percolate through the system
    fatalError(message)

case let .success(message):
    if !message.isEmpty {
        log.atLevelNotice(id: -1, source: "Main", message: message)
    }
}

log.atLevelNotice(id: -1, source: "Main", message: "Configuration parameters values:\n\(parameters)")


// =================
// Configure logging
// =================

guard let applicationLoggingDirectory = FileURLs.applicationLogDir?.path else {
    /// If the FileURLs module could not create the filename, something is seriously wrong.
    log.atLevelEmergency(id: -1, source: "main", message: "Could not construct application log directory (name), aborting...")
    sleep(1) // Allow the error messages to percolate through the system
    fatalError("Could not construct application log directory (name), aborting...")
}

log.logfileDirectoryPath = applicationLoggingDirectory

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

log.atLevelNotice(id: -1, source: "Main", message: "Logging configured")


// ======================================
// Configure callback for log information
// ======================================

// Purpose: To send the logging information to the Console if a console is attached.

class LogForewarder: SwifterlogCallbackProtocol {
    
    func logInfo(_ time: Date, level: SwifterLog.Level, source: String, message: String) {
        if let mac = mac {
            let logline = LogLine(time: time as Date, level: level, source: source, message: message)
            mac.transfer(LogLineReply(logline))
        }
    }
}

let logforewarder = LogForewarder()

log.registerCallback(logforewarder)

log.atLevelNotice(id: -1, source: "Main", message: "Remote console logging set up (not started)")


// ===============================================
// Initialize the server level blacklisted clients
// ===============================================

let serverBlacklist = Blacklist()

guard let serverBlacklistFile = FileURLs.serverBlacklistFile else {
    log.atLevelEmergency(id: -1, source: "Main", message: "Could not construct server blacklist file, aborting...")
    sleep(1) // Allow the error messages to percolate through the system
    fatalError("Could not construct server blacklist file, aborting...")
}

switch serverBlacklist.restore(fromFile: serverBlacklistFile) {

case let .error(message):
    log.atLevelEmergency(id: -1, source: "Main", message: message)
    sleep(1) // Allow the error messages to percolate through the system
    fatalError(message)

case let .success(message):
    log.atLevelNotice(id: -1, source: "Main", message: message)
}


// =========================
// Initialize the statistics
// =========================

let statistics = Statistics()

guard let statisticsFile = FileURLs.statisticsFile else {
    log.atLevelEmergency(id: -1, source: "Main", message: "Statistics file could not be constructed, aborting...")
    sleep(1) // Allow the error messages to percolate through the system
    fatalError("Statistics file could not be constructed, aborting...")
}

switch statistics.restore(fromFile: statisticsFile) {
case let .error(message):
    log.atLevelEmergency(id: -1, source: "Main", message: message)
case .success: break
}

log.atLevelNotice(id: -1, source: "Main", message: "Server statistics loaded.")


// ========================
// Load the domain services
// ========================

let domainServices = DomainServices()
registerDomainServices()


// ============================
// Setup the Http Header Logger
// ============================

// Note that actuall logging depends on the configuration and may be changed during operation.

let headerLogger = HttpHeaderLogger(inDirectory: FileURLs.headersLogDir)


// ======================
// Initialize the domains
// ======================

let domains = Domains()


// Restore the domains from file

guard let defaultDomainsFile = FileURLs.domainDefaultsFile else {
    log.atLevelEmergency(id: -1, source: "Main", message: "Default domains file could not be constructed, aborting...")
    sleep(1)
    fatalError("Default domains file could not be constructed, aborting...")
}

switch domains.restore(fromFile: defaultDomainsFile) {

case let .error(message):
    log.atLevelEmergency(id: -1, source: "Main", message: message)
    sleep(1)
    fatalError(message)
    
case let .success(message):
    Log.atNotice?.log(id: -1, source: "Main", message: message)
}


// Remove unknown services from the domains

domains.forEach() { $0.removeUnknownServices() }


// log the domain settings

Log.atNotice?.log(id: -1, source: "Main", message: "Domain settings:\n\(domains)")


// ==============================
// Setup the http connection pool
// ==============================

let connectionPool = ConnectionPool()


// ==============================
// Initialize the serverTelemetry
// ==============================

let telemetry = Telemetry()


// =======================
// Prepare the HTTP server
// =======================

private let acceptQueue = DispatchQueue(
    label: "Http Server Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

func httpServerErrorHandler(message: String) {
    Log.atError?.log(id: -1, source: "Main", message: message)
}

let httpServer = SwifterSockets.TipServer(
    .port(parameters.httpServicePortNumber),
    .maxPendingConnectionRequests(Int(parameters.maxNofPendingConnections)),
    .acceptQueue(acceptQueue),
    .connectionObjectFactory(httpConnectionFactory),
    .acceptLoopDuration(2),
    .errorHandler(httpServerErrorHandler))


// =========================================================
// Make sure certificates are present for the M&C connection
// =========================================================

if !FileURLs.exists(url: FileURLs.sslConsoleServerCertificateFile) {
    if case .error(let message) = generateKeyAndCertificate(privateKeyLocation: FileURLs.sslConsoleServerPrivateKeyFile, certificateLocation: FileURLs.sslConsoleServerCertificateFile) {
        Log.atError?.log(id: -1, source: "Main", message: message)
    } else {
        Log.atNotice?.log(id: -1, source: "Main", message: "Console certificate and private key generated")
    }
} else {
    Log.atNotice?.log(id: -1, source: "Main", message: "Console certificate present")
}

var consoleServerCertificateFound = false
if let certs = try? FileManager.default.contentsOfDirectory(at: FileURLs.sslConsoleTrustedClientsDir!, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) {
    for cand in certs {
        if cand.pathExtension.compare("pem", options: String.CompareOptions.caseInsensitive, range: nil, locale: nil) == ComparisonResult.orderedSame {
            consoleServerCertificateFound = true
            break
        }
    }
}
if consoleServerCertificateFound {
    Log.atNotice?.log(id: -1, source: "Main", message: "Trusted Console Certificate(s) present")
} else {
    Log.atError?.log(id: -1, source: "Main", message: "No Trusted Console Certificate found")
}


// ============================================================
// Initialize the port for the Monitoring and Control interface
// ============================================================

Log.atNotice?.log(id: -1, source: "Main", message: "Initializing M&C loop on port \(parameters.macPortNumber)")

private let macAcceptQueue = DispatchQueue(
    label: "M&C Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

let certAndKey = CertificateAndPrivateKeyFiles(pemCertificateFile: FileURLs.sslConsoleServerCertificateFile!.path, pemPrivateKeyFile: FileURLs.sslConsoleServerPrivateKeyFile!.path) {
    message in
    Log.atError?.log(id: -1, source: "Main", message: message)
    sleep(2)
    fatalError(message)
}

let macServer = SslServer()
_ = macServer.setOptions(
    .port(parameters.macPortNumber),
    .maxPendingConnectionRequests(1),
    .acceptQueue(macAcceptQueue),
    .connectionObjectFactory(macConnectionFactory),
    .acceptLoopDuration(10),
    .errorHandler(macErrorHandler),
    .trustedClientCertificates([FileURLs.sslConsoleTrustedClientsDir!.path]),
    .certificateAndPrivateKeyFiles(certAndKey)
)


// =====================================
// Start the monitoring and control loop
// =====================================

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
    
    statistics.save(toFile: FileURLs.statisticsFile!)
    log.atLevelNotice(id: -1, source: "Main", message: "Saved server statistics")
    
    headerLogger?.close()
    log.atLevelNotice(id: -1, source: "Main", message: "Closed header logging file")
    
    if let url = FileURLs.serverBlacklistFile {
        serverBlacklist.save(toFile: url)
        log.atLevelNotice(id: -1, source: "Main", message: "Saved server blacklist")
    }
    
    switch domains.serverShutdown() {
    case .error(let message): log.atLevelError(id: -1, source: "Main", message: "Error while shutting down the domains:\n\(message)")
    case .success: break;
    }
    
    switch domains.save(toFile: FileURLs.domainDefaultsFile!) {
    case .error(let message): log.atLevelError(id: -1, source: "Main", message: "Error while saving the domains:\n\(message)")
    case .success: log.atLevelNotice(id: -1, source: "Main", message: "Saved domains")
    }
    
    log.atLevelNotice(id: -1, source: "Main", message: "Swiftfire terminated normally")
    
    
    // Give other tasks time to complete
    
    sleep(10)
    
    exit(EXIT_SUCCESS)
}


// === End ===
