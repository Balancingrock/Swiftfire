// =====================================================================================================================
//
//  File:       main.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2019 Marinus van der Lugt, All rights reserved.
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
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.0 Raised to v1.0.0, Removed old change log,
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
import SecureSockets
import SwifterSockets


// Make the optional loglevel loggers easier accessable

typealias Log = SwifterLog.Logger


/// Stops the startup process.

fileprivate func emergencyExit(_ message: String) -> Never {
    Log.atEmergency?.log(message)
    _ = Darwin.sleep(2) // Give the logger some time to do its work
    fatalError(message)
}


// Every thread that runs for more than a few milliseconds should poll this variable and terminate itself when it finds that this flag is 'true'.

var quitSwiftfire: Bool = false


// Set default logging levels to gain some output if anything goes wrong before the log levels are set to the application values

Log.singleton.osLogFacilityRecordAtAndAboveLevel = SwifterLog.Level.none
Log.singleton.fileRecordAtAndAboveLevel = SwifterLog.Level.none
Log.singleton.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
Log.singleton.callbackAtAndAboveLevel = SwifterLog.Level.none
Log.singleton.networkTransmitAtAndAboveLevel = SwifterLog.Level.none


// First message

Log.atNotice?.log("Starting Swiftfire webserver")


// =======================================
// Initialize the configuration parameters
// =======================================

let parameters = ServerParameters()

do {
    guard let parameterDefaultFile = StorageUrls.parameterDefaultsFile else {
        emergencyExit("Could not construct parameter defaults filename")
    }
    
    switch parameters.restore(fromFile: parameterDefaultFile) {
    case let .error(message):   emergencyExit(message)
    case let .success(message):
        if !message.isEmpty { Log.atNotice?.log(message) }
    }
    
    parameters.debugMode.value = true
    
    setupParametersDidSetActions()
    
    Log.atDebug?.log("Configuration parameters:\n\n\(parameters)\n")
}


// =================
// Configure logging
// =================

do {
    guard let applicationLogDir = StorageUrls.applicationLogDir?.path else {
        emergencyExit("Could not construct application log directory")
    }
    Log.logfiles.directoryPath = applicationLogDir
    
    guard let fileLoglevel = SwifterLog.Level.factory(parameters.fileRecordAtAndAboveLevel.value) else {
        emergencyExit("Could not construct file loglevel")
    }
    Log.singleton.fileRecordAtAndAboveLevel = fileLoglevel
    
    Log.logfiles.maxNumberOfFiles = parameters.logfileMaxNofFiles.value
    Log.logfiles.maxSizeInBytes = UInt64(parameters.logfileMaxSize.value) * 1024
    
    guard let osLogLoglevel = SwifterLog.Level.factory(parameters.osLogRecordAtAndAboveLevel.value) else {
        emergencyExit("Could not construct asl loglevel")
    }
    Log.singleton.osLogFacilityRecordAtAndAboveLevel = osLogLoglevel
    
    guard let stdoutLoglevel = SwifterLog.Level.factory(parameters.stdoutPrintAtAndAboveLevel.value) else {
        emergencyExit("Could not construct stdout loglevel")
    }
    Log.singleton.stdoutPrintAtAndAboveLevel = stdoutLoglevel
    
    guard let callbackLoglevel = SwifterLog.Level.factory(parameters.callbackAtAndAboveLevel.value) else {
        emergencyExit("Could not construct callout loglevel")
    }
    Log.singleton.callbackAtAndAboveLevel = callbackLoglevel
    
    guard let networkLoglevel = SwifterLog.Level.factory(parameters.networkTransmitAtAndAboveLevel.value) else {
        emergencyExit("Could not construct network loglevel")
    }
    Log.singleton.networkTransmitAtAndAboveLevel = networkLoglevel
    
    let address = parameters.networkLogtargetIpAddress.value
    let port = parameters.networkLogtargetPortNumber.value
    if !address.isEmpty && !port.isEmpty {
        let target = SwifterLog.Network.NetworkTarget(address: address, port: port)
        Log.network.connectToNetworkTarget(target)
    }
    
    Log.atNotice?.log("Logging configured")
}


// ===============================================
// Initialize the server level blacklisted clients
// ===============================================

let serverBlacklist = Blacklist()

do {
    guard let serverBlacklistFile = StorageUrls.serverBlacklistFile else {
        emergencyExit("Could not construct server blacklist file url")
    }

    switch serverBlacklist.restore(from: serverBlacklistFile) {
    case let .error(message):   emergencyExit(message)
    case .success: break
    }
    
    Log.atDebug?.log("Server Blacklist:\n\n\(serverBlacklist)\n")
}


// =========================
// Initialize the statistics
// =========================

/*let statistics = Statistics()

do {
    guard let statisticsFile = StorageUrls.statisticsFile else {
        emergencyExit("Statistics file could not be constructed")
    }
    
    switch statistics.restore(fromFile: statisticsFile) {
    case let .error(message): emergencyExit(message)
    case .success: break
    }
    
    Log.atNotice?.log(message: "Server statistics loaded.", from: Source(id: -1, file: #file, function: #function, line: #line))
}*/


// =================
// Load the services
// =================

let services = Service()

do {
    registerServices()

    Log.atDebug?.log("Registered services:\n\n\(services)\n")
}


// ==================
// Load the functions
// ==================

let functions = Function()

do {
    registerFunctions()

    Log.atDebug?.log("Registered functions:\n\n\(functions)\n")
}


// ============================
// Setup the Http Header Logger
// ============================

let headerLogger: HttpHeaderLogger

do {
    guard let headersLogDir = StorageUrls.headersLogDir else {
        emergencyExit("Headers logging directory could nto be constructed")
    }
    
    headerLogger = HttpHeaderLogger(rootDir: headersLogDir)
    
    Log.atDebug?.log("Created header logging directory in: \(headersLogDir)")
}


// ======================
// Initialize the domains
// ======================

let domains = Domains()

do {
    guard let defaultDomainsFile = StorageUrls.domainDefaultsFile else {
        emergencyExit("Default domains file could not be constructed")
    }
    
    switch domains.restore(fromFile: defaultDomainsFile) {
    case let .error(message): emergencyExit(message)
    case let .success(message): Log.atNotice?.log(message)
    }
    
    
    // Remove unknown services from the domains
    
    domains.forEach() { $0.removeUnknownServices() }
    
    
    // log the domain settings
    
    Log.atNotice?.log("Domain settings:\n\n\(domains)\n")
}


// =====================================
// Create the server admin pseudo domain
// =====================================

let serverAdminDomain: Domain

do {
    guard let serverAdminDomainDir = StorageUrls.serverAdminDir else {
        emergencyExit("The Server Admin (Pseudo) Domain directory could not be created")
    }
    
    guard let domain = Domain(name: "serveradmin", root: serverAdminDomainDir) else {
        emergencyExit("The Server Admin (Pseudo) Domain could not be created")
    }
    
    serverAdminDomain = domain

    serverAdminDomain.enabled = true
    serverAdminDomain.accessLogEnabled = true
    serverAdminDomain.four04LogEnabled = true
    serverAdminDomain.sessionLogEnabled = true
    serverAdminDomain.serviceNames = serverAdminServices // Defined in: Services.Registration.swift
    serverAdminDomain.rebuildServices()
    serverAdminDomain.sessionTimeout = 600 // Seconds

    Log.atNotice?.log("Created server admin (pseudo) domain")
}


// ==============================
// Setup the http connection pool
// ==============================

let connectionPool = ConnectionPool()

do {
    connectionPool.sorter = { // Sorting makes monitoring easier
        (_ lhs: Connection, _ rhs: Connection) -> Bool in
        let lhs = lhs as! SFConnection
        let rhs = rhs as! SFConnection
        return lhs.objectId < rhs.objectId
    }
}


// ==============================
// Initialize the serverTelemetry
// ==============================

let telemetry = ServerTelemetry()


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

telemetry.httpServerStatus.setValue("Stopped")
telemetry.httpsServerStatus.setValue("Stopped")


// =========================================================
// Make sure certificates are present for the M&C connection
// =========================================================
/*
if (!StorageUrls.exists(url: StorageUrls.sslConsoleServerCertificateFile) || !StorageUrls.exists(url: StorageUrls.sslConsoleServerPrivateKeyFile)) {
    switch generateKeyAndCertificate(privateKeyLocation: StorageUrls.sslConsoleServerPrivateKeyFile, certificateLocation: StorageUrls.sslConsoleServerCertificateFile) {
    case .error(let message): emergencyExit(message)
    case .success: Log.atNotice?.log("Certificate and private key for console connection generated")
    }
} else {
    Log.atNotice?.log("Certificate and private key files for console connection present")
}


// Create the CTX that will be used

guard let macCtx = ServerCtx() else { emergencyExit("Cannot create server context for console connection") }


// Set the certificate & private key

if case let .error(message) = macCtx.usePrivateKey(file: EncodedFile(path: StorageUrls.sslConsoleServerPrivateKeyFile!.path, encoding: .pem)) {
    emergencyExit(message)
}

if case let .error(message) = macCtx.useCertificate(file: EncodedFile(path: StorageUrls.sslConsoleServerCertificateFile!.path, encoding: .pem)) {
    emergencyExit(message)
}


// Verify the validity duration of the certificate

guard let macCert: X509 = X509(ctx: macCtx) else { emergencyExit("Could not extract certificate store from console context") }

fileprivate let today = Date().javaDate

if today < macCert.validNotBefore { emergencyExit("Console certificate in \(StorageUrls.sslConsoleServerCertificateFile!.path) is not yet valid") }
if today > macCert.validNotAfter  { emergencyExit("Console certificate in \(StorageUrls.sslConsoleServerCertificateFile!.path) is no longer valid") }

fileprivate let validForDays = (macCert.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)

Log.atInfo?.log("Server certificate for console interface is valid for \(validForDays) more days")


// Check that there is a trusted console certificate

var consoleServerCertificateFound = false
if let urls = try? FileManager.default.contentsOfDirectory(at: StorageUrls.sslConsoleTrustedClientsDir!, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) {
    for url in urls {
        // If a certificate file format is found, then load it and check its validity period
        if url.pathExtension.compare("pem", options: String.CompareOptions.caseInsensitive, range: nil, locale: nil) == ComparisonResult.orderedSame {
            // Load the file into a certificate store
            guard let ctx = ServerCtx() else { emergencyExit("Failed to create context for trusted console certificates check") }
            if case let .error(message) = ctx.useCertificate(file: EncodedFile(path: url.path, encoding: .pem)) {
                Log.atWarning?.log("Failed to load trusted console certificate at \(url.path)")
            } else {
                if let cert = X509(ctx: ctx) {
                    if today < cert.validNotBefore {
                        Log.atWarning?.log("Trusted console certificate in \(url.path) is not yet valid")
                    } else if today > cert.validNotAfter {
                        Log.atWarning?.log("Trusted console certificate in \(url.path) is no longer valid")
                    } else {
                        let validForDays = (macCert.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
                        Log.atInfo?.log("Trusted console certificate in \(url.path) is valid for \(validForDays) more days")
                        consoleServerCertificateFound = true
                    }
                }
            }
        }
    }
}

if consoleServerCertificateFound {
    Log.atNotice?.log("Trusted Console Certificate(s) present")
} else {
    Log.atError?.log("No Trusted Console Certificate found")
}
*/

// ====================================
// Call out to the custom setup routine
// ====================================

Log.atNotice?.log("Calling out to custom setup")

customSetup()

Log.atNotice?.log("Finished custom setup")


// ==================================
// Start servers
// ==================================

restartHttpAndHttpsServers()

// Wait for the 'quit' command

while !quitSwiftfire { _ = Darwin.sleep(2) }


// Cleanup

_ = serverAdminDomain.serverShutdown()
//statistics.save(toFile: StorageUrls.statisticsFile!)
//Log.atNotice?.log("Saved server statistics")

headerLogger.close()
Log.atNotice?.log("Closed header logging file")

if let url = StorageUrls.serverBlacklistFile {
    serverBlacklist.save(to: url)
    Log.atNotice?.log("Saved server blacklist")
}

switch domains.serverShutdown() {
case .error(let message): Log.atError?.log("Error while shutting down the domains:\n\(message)")
case .success: break;
}

switch domains.save(toFile: StorageUrls.domainDefaultsFile!) {
case .error(let message): Log.atError?.log("Error while saving the domains:\n\(message)")
case .success: Log.atNotice?.log("Saved domains")
}

Log.atNotice?.log("Swiftfire terminated normally")


// Give other tasks time to complete

_ = Darwin.sleep(10)

exit(EXIT_SUCCESS)


// === End ===
