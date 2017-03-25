// =====================================================================================================================
//
//  File:       main.swift
//  Project:    Swiftfire
//
//  Version:    0.9.18
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
// 0.9.18  - Renames Start command to Run
//         - Header update
//         - Replaced log with Log?
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


/// Stops the startup process.

fileprivate func emergencyExit(_ message: String) -> Never {
    Log.atEmergency?.log(id: -1, source: "Main", message: message)
    sleep(2) // Give the logger some time to do its work
    fatalError(message)
}


// Every thread that runs for more than a few milliseconds should poll this variable and terminate itself when it finds that this flag is 'true'.

var quitSwiftfire: Bool = false


// Set default logging levels to gain some output if anything goes wrong before the log levels are set to the application values

Log.theLogger.aslFacilityRecordAtAndAboveLevel = SwifterLog.Level.none
Log.theLogger.fileRecordAtAndAboveLevel = SwifterLog.Level.none
Log.theLogger.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
Log.theLogger.callbackAtAndAboveLevel = SwifterLog.Level.none
Log.theLogger.networkTransmitAtAndAboveLevel = SwifterLog.Level.none


// =======================================
// Initialize the configuration parameters
// =======================================

let parameters = Parameters()

guard let parameterDefaultFile = FileURLs.parameterDefaultsFile else { emergencyExit("Could not construct parameter defaults filename") }

switch parameters.restore(fromFile: parameterDefaultFile) {
case let .error(message):   emergencyExit(message)
case let .success(message): Log.atNotice?.log(id: -1, source: "Main", message: message)
}

Log.atNotice?.log(id: -1, source: "Main", message: "Configuration parameters values:\n\(parameters)")


// =================
// Configure logging
// =================

guard let applicationLoggingDirectory = FileURLs.applicationLogDir?.path else { emergencyExit("Could not construct application log directory") }

Log.theLogger.logfileDirectoryPath = applicationLoggingDirectory

Log.theLogger.fileRecordAtAndAboveLevel = parameters.fileRecordAtAndAboveLevel
Log.theLogger.logfileDirectoryPath = FileURLs.applicationLogDir!.path
Log.theLogger.logfileMaxNumberOfFiles = parameters.logfileMaxNofFiles
Log.theLogger.logfileMaxSizeInBytes = UInt64(parameters.logfileMaxSize) * 1024

Log.theLogger.aslFacilityRecordAtAndAboveLevel = parameters.aslFacilityRecordAtAndAboveLevel
Log.theLogger.stdoutPrintAtAndAboveLevel = parameters.stdoutPrintAtAndAboveLevel
Log.theLogger.callbackAtAndAboveLevel = parameters.callbackAtAndAboveLevel

Log.theLogger.networkTransmitAtAndAboveLevel = parameters.networkTransmitAtAndAboveLevel
if (parameters.networkLogtargetIpAddress != "") && (parameters.networkLogtargetPortNumber != "") {
    let nettar = SwifterLog.NetworkTarget(address: parameters.networkLogtargetIpAddress, port: parameters.networkLogtargetPortNumber)
    Log.theLogger.connectToNetworkTarget(nettar)
}

Log.atNotice?.log(id: -1, source: "Main", message: "Logging configured")


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

Log.theLogger.registerCallback(logforewarder)

Log.atNotice?.log(id: -1, source: "Main", message: "Remote console logging set up (not started)")


// ===============================================
// Initialize the server level blacklisted clients
// ===============================================

let serverBlacklist = Blacklist()

guard let serverBlacklistFile = FileURLs.serverBlacklistFile else { emergencyExit("Could not construct server blacklist file") }

switch serverBlacklist.restore(fromFile: serverBlacklistFile) {
case let .error(message):   emergencyExit(message)
case let .success(message): Log.atNotice?.log(id: -1, source: "Main", message: message)
}


// =========================
// Initialize the statistics
// =========================

let statistics = Statistics()

guard let statisticsFile = FileURLs.statisticsFile else { emergencyExit("Statistics file could not be constructed") }

switch statistics.restore(fromFile: statisticsFile) {
case let .error(message): emergencyExit(message)
case .success: break
}

Log.atNotice?.log(id: -1, source: "Main", message: "Server statistics loaded.")


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

guard let defaultDomainsFile = FileURLs.domainDefaultsFile else { emergencyExit("Default domains file could not be constructed") }

switch domains.restore(fromFile: defaultDomainsFile) {
case let .error(message): emergencyExit(message)
case let .success(message): Log.atNotice?.log(id: -1, source: "Main", message: message)
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


// ===================================
// Prepare for the HTTP & HTTPS server
// ===================================

let httpServerAcceptQueue = DispatchQueue(
    label: "HTTP Server Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

let httpsServerAcceptQueue = DispatchQueue(
    label: "HTTPS Server Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

var httpServer: SwifterSockets.TipServer?
var httpsServer: SecureSockets.SslServer?


// =========================================================
// Make sure certificates are present for the M&C connection
// =========================================================

if (!FileURLs.exists(url: FileURLs.sslConsoleServerCertificateFile) || !FileURLs.exists(url: FileURLs.sslConsoleServerPrivateKeyFile)) {
    switch generateKeyAndCertificate(privateKeyLocation: FileURLs.sslConsoleServerPrivateKeyFile, certificateLocation: FileURLs.sslConsoleServerCertificateFile) {
    case .error(let message): emergencyExit(message)
    case .success: Log.atNotice?.log(id: -1, source: "Main", message: "Certificate and private key for console connection generated")
    }
} else {
    Log.atNotice?.log(id: -1, source: "Main", message: "Certificate and private key files for console connection present")
}


// Create the CTX that will be used

guard let macCtx = ServerCtx() else { emergencyExit("Cannot create server context for console connection") }


// Set the certificate & private key

if case let .error(message) = macCtx.usePrivateKey(file: EncodedFile(path: FileURLs.sslConsoleServerPrivateKeyFile!.path, encoding: .pem)) {
    emergencyExit(message)
}

if case let .error(message) = macCtx.useCertificate(file: EncodedFile(path: FileURLs.sslConsoleServerCertificateFile!.path, encoding: .pem)) {
    emergencyExit(message)
}


// Verify the validity duration of the certificate

guard let macCert: X509 = X509(ctx: macCtx) else { emergencyExit("Could not extract certificate store from console context") }

fileprivate let today = Date().javaDate

if today < macCert.validNotBefore { emergencyExit("Console certificate in \(FileURLs.sslConsoleServerCertificateFile!.path) is not yet valid") }
if today > macCert.validNotAfter  { emergencyExit("Console certificate in \(FileURLs.sslConsoleServerCertificateFile!.path) is no longer valid") }

fileprivate let validForDays = (macCert.validNotAfter - today)/(24 * 60 * 60 * 1000)

Log.atInfo?.log(id: -1, source: "Main", message: "Server certificate for console interface is valid for \(validForDays) more days")


// Check that there is a trusted console certificate

var consoleServerCertificateFound = false
if let urls = try? FileManager.default.contentsOfDirectory(at: FileURLs.sslConsoleTrustedClientsDir!, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) {
    for url in urls {
        // If a certificate file format is found, then load it and check its validity period
        if url.pathExtension.compare("pem", options: String.CompareOptions.caseInsensitive, range: nil, locale: nil) == ComparisonResult.orderedSame {
            // Load the file into a certificate store
            guard let ctx = ServerCtx() else { emergencyExit("Failed to create context for trusted console certificates check") }
            if case let .error(message) = ctx.useCertificate(file: EncodedFile(path: url.path, encoding: .pem)) {
                Log.atWarning?.log(id: -1, source: "Main", message: "Failed to load trusted console certificate at \(url.path)")
            } else {
                if let cert = X509(ctx: ctx) {
                    if today < cert.validNotBefore {
                        Log.atWarning?.log(id: -1, source: "Main", message: "Trusted console certificate in \(url.path) is not yet valid")
                    } else if today > cert.validNotAfter {
                        Log.atWarning?.log(id: -1, source: "Main", message: "Trusted console certificate in \(url.path) is no longer valid")
                    } else {
                        let validForDays = (macCert.validNotAfter - today)/(24 * 60 * 60 * 1000)
                        Log.atInfo?.log(id: -1, source: "Main", message: "Trusted console certificate in \(url.path) is valid for \(validForDays) more days")
                        consoleServerCertificateFound = true
                    }
                }
            }
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


// The thread for the process that communicates with the console (mac).

private let macAcceptQueue = DispatchQueue(
    label: "M&C Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)


// Create a container for the certificate and private key

guard let macCertKeyContainer = CertificateAndPrivateKeyFiles(pemCertificateFile: FileURLs.sslConsoleServerCertificateFile!.path, pemPrivateKeyFile: FileURLs.sslConsoleServerPrivateKeyFile!.path) else { emergencyExit("Could not create console server certificate & private key container") }


// Create the server

let macServer = SslServer()
_ = macServer.setOptions(
    .port(parameters.macPortNumber),
    .maxPendingConnectionRequests(1),
    .acceptQueue(macAcceptQueue),
    .connectionObjectFactory(macConnectionFactory),
    .acceptLoopDuration(10),
    .errorHandler(macErrorHandler),
    .trustedClientCertificates([FileURLs.sslConsoleTrustedClientsDir!.path]),
    .serverCtx(macCtx)
)


// =====================================
// Start the monitoring and control loop
// =====================================

switch macServer.start() {
    
case let .error(message):
    
    Log.atEmergency?.log(id: -1, source: "Main", message: "Swiftfire terminated with error '\(message)'")
    
    sleep(10)
    
    exit(EXIT_FAILURE)
    
    
case .success:
    
    Log.atNotice?.log(id: -1, source: "Main", message: "Listening for M&C connections")
    
    // ==================================
    // Autostart servers if necessary
    // ==================================
    
    if parameters.autoStartup {
        HttpServerRunCommand().execute()
        HttpsServerRunCommand().execute()
    }
    
    
    // Wait for the 'quit' command
    
    while !quitSwiftfire { sleep(2) }
    
    
    // Cleanup
    
    statistics.save(toFile: FileURLs.statisticsFile!)
    Log.atNotice?.log(id: -1, source: "Main", message: "Saved server statistics")
    
    headerLogger?.close()
    Log.atNotice?.log(id: -1, source: "Main", message: "Closed header logging file")
    
    if let url = FileURLs.serverBlacklistFile {
        serverBlacklist.save(toFile: url)
        Log.atNotice?.log(id: -1, source: "Main", message: "Saved server blacklist")
    }
    
    switch domains.serverShutdown() {
    case .error(let message): Log.atError?.log(id: -1, source: "Main", message: "Error while shutting down the domains:\n\(message)")
    case .success: break;
    }
    
    switch domains.save(toFile: FileURLs.domainDefaultsFile!) {
    case .error(let message): Log.atError?.log(id: -1, source: "Main", message: "Error while saving the domains:\n\(message)")
    case .success: Log.atNotice?.log(id: -1, source: "Main", message: "Saved domains")
    }
    
    Log.atNotice?.log(id: -1, source: "Main", message: "Swiftfire terminated normally")
    
    
    // Give other tasks time to complete
    
    sleep(10)
    
    exit(EXIT_SUCCESS)
}


// === End ===
