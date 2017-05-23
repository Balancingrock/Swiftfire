//
//  RestartHttpAndHttpsServers.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 16/05/17.
//
//

import Foundation
import SwifterSockets
import SecureSockets


fileprivate func httpServerErrorHandler(message: String) { Log.atError?.log(id: -1, source: "HTTP Server", message: message) }
fileprivate func httpsServerErrorHandler(message: String) { Log.atError?.log(id: -1, source: "HTTPS Server", message: message) }


func restartHttpAndHttpsServers() {

    
    // Stop the HTTP server (if running)
    
    if httpServer?.isRunning ?? false {
        
        Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "Stopping HTTP server")
        
        httpServer?.stop()
        
        telemetry.httpServerStatus.value = "Stopping"
        
        
        // Wait until it is stopped
        
        var waitLimiter = 0
        while httpServer?.isRunning ?? true {
            sleep(1)
            if waitLimiter == 60 { break }
            waitLimiter += 1
        }
        
        if !(httpServer?.isRunning ?? false) {
            telemetry.httpServerStatus.value = "Not Running"
        }
    }
    
    
    // Stop the HTTPS server (if running)
    
    if httpsServer?.isRunning ?? false {
        
        Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "Stopping HTTPS server")
        
        httpsServer?.stop()
        
        telemetry.httpsServerStatus.value = "Stopping"
    
        
        // Wait until it is stopped
        
        var waitLimiter = 0
        while httpsServer?.isRunning ?? true {
            sleep(1)
            if waitLimiter == 60 { break }
            waitLimiter += 1
        }

        if !(httpsServer?.isRunning ?? false) {
            telemetry.httpsServerStatus.value = "Not Running"
        }
    }
    
    
    // If neither server is running then reinit the available connections and domain services
    
    if !(httpsServer?.isRunning ?? false || httpServer?.isRunning ?? false) {
        
        
        // Reset available connections
        
        connectionPool.create(num: parameters.maxNofAcceptedConnections.value, generator: { return SFConnection() })
        
        Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "Initialized the connection pool with \(parameters.maxNofAcceptedConnections) http connections")
        
        
        // Rebuild the available services for the domains
        
        domains.forEach(){ $0.rebuildServices() }
    }
    
    
    // Restart the HTTP server
    
    httpServer = SwifterSockets.TipServer(
        .port(parameters.httpServicePortNumber.value),
        .maxPendingConnectionRequests(Int(parameters.maxNofPendingConnections.value)),
        .acceptQueue(httpServerAcceptQueue),
        .connectionObjectFactory(httpConnectionFactory),
        .acceptLoopDuration(2),
        .errorHandler(httpServerErrorHandler))
    
    switch httpServer?.start() {
        
    case nil:
        
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "No HTTP server created")
        telemetry.httpServerStatus.value = "Cannot"
        
        
    case let .error(message)?:
        
        Log.atError?.log(id: -1, source: #file.source(#function, #line), message: message)
        telemetry.httpServerStatus.value = "Error, see log"
        
        
    case .success?:
        
        Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "HTTP Server started on port \(parameters.httpServicePortNumber)")
        
        // Log the conditions the server is running under
        
        logServerSetup()
        
        telemetry.httpServerStatus.value = "Running"
    }

    
    // Start the HTTPS server
    
    // Get a server certificate and private key reference
    
    var serverCtx = buildServerCtx()
    
    
    // Create new domain CTXs
    
    var domainCtxs = checkDomainCtxs()
    
    
    if serverCtx == nil && domainCtxs.count == 0 {
        
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "No certificate or private key (or combo) found, cannot start the HTTPS server")
        
        telemetry.httpsServerStatus.value = "No Cert|Key"
        
    } else {
        
        
        // If there is a domain CTX but no server CTX, use the domain CTX instead
        
        if serverCtx == nil {
            serverCtx = domainCtxs[0]
            domainCtxs.remove(at: 0)
        }
        
        
        // Restart the HTTPS server
        
        httpsServer = SecureSockets.SslServer(
            .port(parameters.httpsServicePortNumber.value),
            .maxPendingConnectionRequests(Int(parameters.maxNofPendingConnections.value)),
            .acceptQueue(httpsServerAcceptQueue),
            .connectionObjectFactory(httpConnectionFactory),
            .acceptLoopDuration(2),
            .errorHandler(httpsServerErrorHandler),
            .serverCtx(serverCtx),
            .domainCtxs(domainCtxs.count > 0 ? domainCtxs : nil)
        )
        
        switch httpsServer?.start() {
            
        case nil:
            
            Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "No HTTPS server created")
            telemetry.httpsServerStatus.value = "Cannot"
            
            
        case let .error(message)?:
            
            Log.atError?.log(id: -1, source: #file.source(#function, #line), message: message)
            telemetry.httpsServerStatus.value = "Error"
            
            
        case .success?:
            
            Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "HTTPS Server started on port \(parameters.httpsServicePortNumber)")
            
            // Log the conditions the server is running under
            
            logServerSetup()
            
            telemetry.httpsServerStatus.value = "Running"
        }
    }
}

fileprivate func buildServerCtx() -> ServerCtx? {
    
    guard let sslServerDir = StorageUrls.sslServerDir else {
        Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "No sll server directory found")
        return nil
    }
    
    
    // Get all files in the ssl directory
    
    guard let files = try? FileManager.default.contentsOfDirectory(at: sslServerDir, includingPropertiesForKeys: [.isReadableKey], options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles]) else {
        
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: "Directory \(sslServerDir.path) is empty (no cert or key file found)")
        return nil
    }
    
    
    // Filter for PEM files
    
    let pemFiles = files.flatMap({ $0.pathExtension.compare("pem", options: [.caseInsensitive], range: nil, locale: nil) == ComparisonResult.orderedSame ? $0 : nil })
    
    if pemFiles.count == 0 {
        Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "No pem files found in \(sslServerDir.path)")
        return nil
    }
    
    
    // Filter for files containing 'cert'
    
    let certFiles = pemFiles.flatMap({ $0.lastPathComponent.contains("cert") ? $0 : nil })
    
    if certFiles.count != 1 {
        if certFiles.count == 0 {
            Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "No certificate file found in \(sslServerDir.path) (filename should contain the lowercase characters 'cert'")
        } else {
            Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "Too many certificate files found in \(sslServerDir.path) (filenames  containing the lowercase characters 'cert'")
        }
        return nil
    }
    
    
    // Filter for files containing 'key'
    
    let keyFiles = pemFiles.flatMap({ $0.lastPathComponent.contains("key") ? $0 : nil })
    
    if keyFiles.count != 1 {
        if keyFiles.count == 0 {
            Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "No (private) key file found in \(sslServerDir.path) (filename should contain the lowercase characters 'key'")
        } else {
            Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "Too many (private) key files found in \(sslServerDir.path) (filenames containing the lowercase characters 'key'")
        }
        return nil
    }
    
    
    // Create the server CTX
    
    guard let ctx = ServerCtx() else {
        Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Server context creation failed")
        return nil
    }
    
    
    // Add the certificate and (private) key
    
    if case let .error(message) = ctx.useCertificate(file: EncodedFile(path: certFiles[0].path, encoding: .pem)) {
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: message)
        return nil
    }
    
    if case let .error(message) = ctx.usePrivateKey(file: EncodedFile(path: keyFiles[0].path, encoding: .pem)) {
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: message)
        return nil
    }
    
    if case let .error(message) = ctx.checkPrivateKey() {
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: message)
        return nil
    }
    
    
    // Check validity period
    
    guard let cert = X509(ctx: ctx) else {
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: "Failure retrieving certificate store from context")
        return nil
    }
    
    let today = Date().javaDate
    
    if today < cert.validNotBefore {
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: "Certificate at \(certFiles[0].path) is not yet valid")
        return nil
    }
    
    if today > cert.validNotAfter {
        Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: "Certificate at \(certFiles[0].path) is no longer valid")
        return nil
    }
    
    let validForDays = (cert.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
    
    Log.atInfo?.log(id: -1, source: "Main", message: "Server certificate is valid for \(validForDays) more days")
    
    return ctx
}

fileprivate func checkDomainCtxs() -> [ServerCtx] {
    
    let today = Date().javaDate
    
    var domainCtxs = domains.ctxs
    
    for domain in domains {
        
        switch domain.ctx {
            
        case let .error(message): Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: message)
            
        case let .success(ctx):
            
            let cert = X509(ctx: ctx)
            
            if cert != nil {
                
                if today < cert!.validNotBefore {
                    
                    Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: "Certificate for domain \(domain.name) is not yet valid")
                    
                } else if today > cert!.validNotAfter {
                    
                    Log.atWarning?.log(id: -1, source: #file.source(#function, #line), message: "Certificate for domain \(domain.name) is no longer valid")
                    
                } else {
                    
                    let validForDays = (cert!.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
                    
                    Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "Server certificate is valid for \(validForDays) more days")
                    
                    domainCtxs.append(ctx)
                }
                
            } else {
                
                Log.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "Cannot extract certificate of domain \(domain.name)")
            }
        }
    }
    
    return domainCtxs
}
