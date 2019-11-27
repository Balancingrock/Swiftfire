// =====================================================================================================================
//
//  File:       RestartHttpAndHttpsServers.swift
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

import Foundation
import SwifterSockets
import SecureSockets
import SwifterLog


fileprivate func httpServerErrorHandler(message: String) {
    Log.atError?.log(message, id: -1)
}

fileprivate func httpsServerErrorHandler(message: String) {
    Log.atError?.log(message, id: -1)
}


public func restartHttpAndHttpsServers() {

    
    // Stop the HTTP server (if running)
    
    if httpServer?.isRunning ?? false {
        
        Log.atNotice?.log("Stopping HTTP server")
        
        httpServer?.stop()
        
        serverTelemetry.httpServerStatus.value = "Stopping"
        
        
        // Wait until it is stopped
        
        var waitLimiter = 0
        while httpServer?.isRunning ?? true {
            _ = Darwin.sleep(1)
            if waitLimiter == 60 { break }
            waitLimiter += 1
        }
        
        if !(httpServer?.isRunning ?? false) {
            serverTelemetry.httpServerStatus.value = "Not Running"
        }
    }
    
    
    // Stop the HTTPS server (if running)
    
    if httpsServer?.isRunning ?? false {
        
        Log.atNotice?.log("Stopping HTTPS server")
        
        httpsServer?.stop()
        
        serverTelemetry.httpsServerStatus.value = "Stopping"
    
        
        // Wait until it is stopped
        
        var waitLimiter = 0
        while httpsServer?.isRunning ?? true {
            _ = Darwin.sleep(1)
            if waitLimiter == 60 { break }
            waitLimiter += 1
        }

        if !(httpsServer?.isRunning ?? false) {
            serverTelemetry.httpsServerStatus.value = "Not Running"
        }
    }
    
    
    // If neither server is running then reinit the available connections and domain services
    
    if !(httpsServer?.isRunning ?? false || httpServer?.isRunning ?? false) {
        
        
        // Reset available connections
        
        connectionPool.create(num: serverParameters.maxNofAcceptedConnections.value, generator: { return SFConnection() })
        
        Log.atNotice?.log("Initialized the connection pool with \(serverParameters.maxNofAcceptedConnections) http connections")
        
        
        // Rebuild the available services for the domains
        
        domains.forEach { $0.rebuildServices() }
    }
    
    
    // Restart the HTTP server
    
    httpServer = SwifterSockets.TipServer(
        .port(serverParameters.httpServicePortNumber.value),
        .maxPendingConnectionRequests(Int(serverParameters.maxNofPendingConnections.value)),
        .acceptQueue(httpServerAcceptQueue),
        .connectionObjectFactory(httpConnectionFactory),
        .acceptLoopDuration(2),
        .errorHandler(httpServerErrorHandler))
    
    switch httpServer?.start() {
        
    case nil:
        
        Log.atCritical?.log("No HTTP server created")
        serverTelemetry.httpServerStatus.value = "Cannot"
        
        
    case let .error(message)?:
        
        Log.atError?.log(message)
        serverTelemetry.httpServerStatus.value = "Error, see log"
        
        
    case .success?:
        
        Log.atNotice?.log("HTTP Server started on port \(serverParameters.httpServicePortNumber)")
        
        // Log the conditions the server is running under
        
        logServerSetup()
        
        serverTelemetry.httpServerStatus.value = "Running"
    }

    
    // Start the HTTPS server
    
    // Get a server certificate and private key reference
    
    var serverCtx = buildServerCtx()
    
    
    // Create new domain CTXs
    
    var domainCtxs = checkDomainCtxs()
    
    
    if serverCtx == nil && domainCtxs.count == 0 {
        
        Log.atWarning?.log("No certificate or private key (or combo) found, cannot start the HTTPS server")
        
        serverTelemetry.httpsServerStatus.value = "No Cert|Key"
        
    } else {
        
        
        // If there is a domain CTX but no server CTX, use the domain CTX instead
        
        if serverCtx == nil {
            serverCtx = domainCtxs[0]
            domainCtxs.remove(at: 0)
        }
        
        
        // Restart the HTTPS server
        
        httpsServer = SecureSockets.SslServer(
            .port(serverParameters.httpsServicePortNumber.value),
            .maxPendingConnectionRequests(Int(serverParameters.maxNofPendingConnections.value)),
            .acceptQueue(httpsServerAcceptQueue),
            .connectionObjectFactory(httpConnectionFactory),
            .acceptLoopDuration(2),
            .errorHandler(httpsServerErrorHandler),
            .serverCtx(serverCtx),
            .domainCtxs(domainCtxs.count > 0 ? domainCtxs : nil)
        )
        
        switch httpsServer?.start() {
            
        case nil:
            
            Log.atCritical?.log("No HTTPS server created")
            serverTelemetry.httpsServerStatus.value = "Cannot"
            
            
        case let .error(message)?:
            
            Log.atError?.log(message)
            serverTelemetry.httpsServerStatus.value = "Error"
            
            
        case .success?:
            
            Log.atNotice?.log("HTTPS Server started on port \(serverParameters.httpsServicePortNumber)")
            
            // Log the conditions the server is running under
            
            logServerSetup()
            
            serverTelemetry.httpsServerStatus.value = "Running"
        }
    }
}

fileprivate func buildServerCtx() -> ServerCtx? {
    
    guard let sslServerDir = Urls.sslServerDir else {
        Log.atError?.log("No sll server directory found")
        return nil
    }
    
    
    // Get all files in the ssl directory
    
    guard let files = try? FileManager.default.contentsOfDirectory(at: sslServerDir, includingPropertiesForKeys: [.isReadableKey], options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles]) else {
        
        Log.atWarning?.log("Directory \(sslServerDir.path) is empty (no cert or key file found)")
        return nil
    }
    
    
    // Filter for PEM files
    
    let pemFiles = files.compactMap({ $0.pathExtension.compare("pem", options: [.caseInsensitive], range: nil, locale: nil) == ComparisonResult.orderedSame ? $0 : nil })
    
    if pemFiles.count == 0 {
        Log.atInfo?.log("No pem files found in \(sslServerDir.path)")
        return nil
    }
    
    
    // Filter for files containing 'cert'
    
    let certFiles = pemFiles.compactMap({ $0.lastPathComponent.contains("cert") ? $0 : nil })
    
    if certFiles.count != 1 {
        if certFiles.count == 0 {
            Log.atInfo?.log("No certificate file found in \(sslServerDir.path) (filename should contain the lowercase characters 'cert'")
        } else {
            Log.atInfo?.log("Too many certificate files found in \(sslServerDir.path) (filenames  containing the lowercase characters 'cert'")
        }
        return nil
    }
    
    
    // Filter for files containing 'key'
    
    let keyFiles = pemFiles.compactMap({ $0.lastPathComponent.contains("key") ? $0 : nil })
    
    if keyFiles.count != 1 {
        if keyFiles.count == 0 {
            Log.atInfo?.log("No (private) key file found in \(sslServerDir.path) (filename should contain the lowercase characters 'key'")
        } else {
            Log.atInfo?.log("Too many (private) key files found in \(sslServerDir.path) (filenames containing the lowercase characters 'key'")
        }
        return nil
    }
    
    
    // Create the server CTX
    
    guard let ctx = ServerCtx() else {
        Log.atError?.log("Server context creation failed")
        return nil
    }
    
    
    // Add the certificate and (private) key
    
    if case let .error(message) = ctx.useCertificate(file: EncodedFile(path: certFiles[0].path, encoding: .pem)) {
        Log.atWarning?.log(message)
        return nil
    }
    
    if case let .error(message) = ctx.usePrivateKey(file: EncodedFile(path: keyFiles[0].path, encoding: .pem)) {
        Log.atWarning?.log(message)
        return nil
    }
    
    if case let .error(message) = ctx.checkPrivateKey() {
        Log.atWarning?.log(message)
        return nil
    }
    
    
    // Check validity period
    
    guard let cert = X509(ctx: ctx) else {
        Log.atWarning?.log("Failure retrieving certificate store from context")
        return nil
    }
    
    let today = Date().javaDate
    
    if today < cert.validNotBefore {
        Log.atWarning?.log("Certificate at \(certFiles[0].path) is not yet valid")
        return nil
    }
    
    if today > cert.validNotAfter {
        Log.atWarning?.log("Certificate at \(certFiles[0].path) is no longer valid")
        return nil
    }
    
    let validForDays = (cert.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
    
    Log.atInfo?.log("Server certificate is valid for \(validForDays) more days")
    
    return ctx
}

fileprivate func checkDomainCtxs() -> [ServerCtx] {
    
    let today = Date().javaDate
    
    var domainCtxs = domains.ctxs
    
    for domain in domains {
        
        switch domain.ctx {
            
        case let .error(message):
            
            Log.atWarning?.log(message)
            
        case let .success(ctx):
            
            let cert = X509(ctx: ctx)
            
            if cert != nil {
                
                if today < cert!.validNotBefore {
                    
                    Log.atWarning?.log("Certificate for domain \(domain.name) is not yet valid")
                    
                } else if today > cert!.validNotAfter {
                    
                    Log.atWarning?.log("Certificate for domain \(domain.name) is no longer valid")
                    
                } else {
                    
                    let validForDays = (cert!.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
                    
                    Log.atInfo?.log("Server certificate is valid for \(validForDays) more days")
                    
                    domainCtxs.append(ctx)
                }
                
            } else {
                
                Log.atInfo?.log("Cannot extract certificate of domain \(domain.name)")
            }
        }
    }
    
    return domainCtxs
}
