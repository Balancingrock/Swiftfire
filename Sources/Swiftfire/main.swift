// =====================================================================================================================
//
//  File:       main.swift
//  Project:    Swiftfire
//
//  Version:    1.3.3
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2020 Marinus van der Lugt, All rights reserved.
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
// 1.3.3 - Linux compatibility
// 1.3.2 - Added logging (in global var) of startup time
//       #10 Moved initialization of server admin services to the main operation.
// 1.3.0 - Removed DecodePostFormUrlEncoded
//       #8: Auto oading of domain & aliases list
// 1.1.0 #1: Fixed loading & storing of domain service names
//       #2: Moved server blacklist to serverAdminDomain
//       #4: Rebuild domain services after loading the domains
// 1.0.0 - Raised to v1.0.0, Removed old change log,
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
import Core
import Functions
import Services
import Admin
import Custom


/// Stops the startup process.

fileprivate func emergencyExit(_ message: String) -> Never {
    Log.atEmergency?.log(message)
    _ = sleep(2) // Give the logger some time to do its work
    fatalError(message)
}


// Set default logging levels to gain some output if anything goes wrong before the log levels are set from the server parameter values

Log.singleton.osLogFacilityRecordAtAndAboveLevel = SwifterLog.Level.none
Log.singleton.fileRecordAtAndAboveLevel = SwifterLog.Level.none
Log.singleton.stdoutPrintAtAndAboveLevel = SwifterLog.Level.debug
Log.singleton.callbackAtAndAboveLevel = SwifterLog.Level.none
Log.singleton.networkTransmitAtAndAboveLevel = SwifterLog.Level.none


// First message

Log.atNotice?.log("Starting Swiftfire webserver \(serverTelemetry.serverVersion)")


// ===============================
// Evaluate command line arguments
// ===============================

do {
    // Note that this function will not return if an error occured on the command line.
    commandLineArguments.read()
    
    Log.atNotice?.log("Using server root directory: \(Urls.rootDir.path)")
}


// =======================================
// Initialize the configuration parameters
// =======================================

do {
    // Load the server parameter default values
    guard serverParameters.load() else {
        emergencyExit("Could not load server parameters")
    }
    
    // Override with command line arguments
    commandLineArguments.updateServerParameters()
    
    // Add update (validation) actions
    setupParametersDidSetActions()
    
    Log.atDebug?.log("Configuration parameters:\n\n\(serverParameters)\n")
}


// =================
// Configure logging
// =================

do {
    guard let applicationLogDir = Urls.applicationLogDir?.path else {
        emergencyExit("Could not construct application log directory")
    }
    Log.logfiles.directoryPath = applicationLogDir
    
    guard let fileLoglevel = SwifterLog.Level.factory(serverParameters.fileRecordAtAndAboveLevel.value) else {
        emergencyExit("Could not construct file loglevel")
    }
    Log.singleton.fileRecordAtAndAboveLevel = fileLoglevel
    
    Log.logfiles.maxNumberOfFiles = serverParameters.logfileMaxNofFiles.value
    Log.logfiles.maxSizeInBytes = UInt64(serverParameters.logfileMaxSize.value) * 1024
    
    guard let osLogLoglevel = SwifterLog.Level.factory(serverParameters.osLogRecordAtAndAboveLevel.value) else {
        emergencyExit("Could not construct asl loglevel")
    }
    Log.singleton.osLogFacilityRecordAtAndAboveLevel = osLogLoglevel
    
    guard let stdoutLoglevel = SwifterLog.Level.factory(serverParameters.stdoutPrintAtAndAboveLevel.value) else {
        emergencyExit("Could not construct stdout loglevel")
    }
    Log.singleton.stdoutPrintAtAndAboveLevel = stdoutLoglevel
    
    guard let callbackLoglevel = SwifterLog.Level.factory(serverParameters.callbackAtAndAboveLevel.value) else {
        emergencyExit("Could not construct callout loglevel")
    }
    Log.singleton.callbackAtAndAboveLevel = callbackLoglevel
    
    guard let networkLoglevel = SwifterLog.Level.factory(serverParameters.networkTransmitAtAndAboveLevel.value) else {
        emergencyExit("Could not construct network loglevel")
    }
    Log.singleton.networkTransmitAtAndAboveLevel = networkLoglevel
    
    let address = serverParameters.networkLogtargetIpAddress.value
    let port = serverParameters.networkLogtargetPortNumber.value
    if !address.isEmpty && !port.isEmpty {
        let target = SwifterLog.Network.NetworkTarget(address: address, port: port)
        Log.network.connectToNetworkTarget(target)
    }
    
    Log.atNotice?.log("Logging configured")
}


// =================
// Load the services
// =================

do {
    registerServices()
    sfRegisterServices()
    Log.atDebug?.log("Registered services:\n\n\(services)\n")
    
    
    /// Default services for newly created domains.
    ///
    /// This service stack implements a default webserver.
    
    defaultServices = [
        serviceName_Blacklist,
        serviceName_OnlyHttp10OrHttp11,
        serviceName_OnlyGetOrPost,
        serviceName_GetSession,
        serviceName_WaitUntilBodyComplete,
        serviceName_Setup,
        serviceName_Commands,
        serviceName_GetResourcePathFromUrl,
        serviceName_StorePreLoginUrl,
        serviceName_GetFileAtResourcePath,
        serviceName_RestartSessionTimeout,
        serviceName_TransferResponse
    ]
}


// ==================
// Load the functions
// ==================

do {
    registerFunctions()
    sfRegisterFunctions()
    Log.atDebug?.log("Registered functions:\n\n\(functions)\n")
}


// ============================
// Setup the Http Header Logger
// ============================

do {
    headerLogger = HttpHeaderLogger(logDir: Urls.headersLogDir)
    guard headerLogger != nil else {
        emergencyExit("Header Logger could not be instantiated")
    }
    
    Log.atDebug?.log("Created header logging directory in: \(Urls.headersLogDir!.path)")
}


// ===================
// Prepare the domainManager
// ===================

do {
    guard domainManager != nil else { emergencyExit("Could not create domainManager") }
    
    // Remove unknown services from the domains
    
    domainManager.forEach() { $0.removeUnknownServices() }
    
    
    // Rebuild the available services for the domains
    
    domainManager.forEach { $0.rebuildServices?($0) }

    
    // log the domain settings
    
    Log.atNotice?.log("Domain settings:\n\n\(String(describing: domainManager))\n")
}


// =====================================
// Create the server admin pseudo domain
// =====================================

do {
    guard let domain = Domain("serveradmin") else {
        emergencyExit("The Server Admin (Pseudo) Domain could not be created")
    }
    
    
    // The serveradmin domain should not have an Anon account
    
    assert(domain.accounts!.getAccountWithoutPassword(for: "Anon") == nil)
    
    serverAdminDomain = domain

    serverAdminDomain.webroot = serverParameters.adminSiteRoot.value
    serverAdminDomain.enabled = true
    serverAdminDomain.accessLogEnabled = true
    serverAdminDomain.four04LogEnabled = true
    serverAdminDomain.sessionLogEnabled = true
    serverAdminDomain.services = [
        Services.Entry(serviceName_GetSession, service_getSession),
        Services.Entry(serviceName_WaitUntilBodyComplete, service_waitUntilBodyComplete),
        Services.Entry("Server Admin", service_serverAdmin),
        Services.Entry(serviceName_RestartSessionTimeout, service_restartSessionTimeout),
        Services.Entry(serviceName_TransferResponse, service_transferResponse)
    ]
    serverAdminDomain.rebuildServices = nil // Don't modify the above defined services
    serverAdminDomain.sessionTimeout = 600 // Seconds

    serverAdminDomain.storeSetup()
    
    Log.atNotice?.log("Created server admin (pseudo) domain")
}


// =================================================
// Configure the sorter for the http connection pool
// =================================================

do {
    connectionPool.sorter = { // Sorting makes monitoring easier
        (_ lhs: Connection, _ rhs: Connection) -> Bool in
        let lhs = lhs as! SFConnection
        let rhs = rhs as! SFConnection
        return lhs.objectId < rhs.objectId
    }
}


// ==========================
// Setup the server telemetry
// ==========================

do {    
    Log.atNotice?.log("Server Telemetry object available")
}


// ===================================
// Prepare for the HTTP & HTTPS server
// ===================================

httpServerAcceptQueue = DispatchQueue(
    label: "HTTP Server Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

httpsServerAcceptQueue = DispatchQueue(
    label: "HTTPS Server Accept queue",
    qos: .userInteractive,
    attributes: [],
    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
    target: nil)

serverTelemetry.httpServerStatus.setValue("Stopped")
serverTelemetry.httpsServerStatus.setValue("Stopped")



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


// Log the startup time

startupTime = Date()


// ===========================
// Wait for the 'quit' command
// ===========================

while !quitSwiftfire { _ = sleep(2) }

httpServer?.stop()
httpsServer?.stop()
Log.atNotice?.log("Received quit command, requested the server(s) to stop")


// ============================================================================================
// The servers should stop processing requests, give active requests time to terminate normally
// ============================================================================================

_ = sleep(10)


// ================================================
// Save the state, telemetry and logs of the server
// ================================================

_ = serverAdminDomain.shutdown()


// =====================
// Close the server logs
// =====================

headerLogger.close()
Log.atNotice?.log("Closed header logging file")


// ================================
// Persist the state of the domains
// ================================

domainManager.shutdown()


// ===============
// Done
// ===============

Log.atNotice?.log("Swiftfire terminated normally")

exit(EXIT_SUCCESS)


// === End ===
