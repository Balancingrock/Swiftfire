// =====================================================================================================================
//
//  File:       RestartHttpAndHttpsServers.swift
//  Project:    Swiftfire
//
//  Version:    0.10.10
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// 0.10.12 - Upgraded to SwifterLog 1.1.0
// 0.10.10 - Added 'Darwin' to sleep statements.
// 0.10.7 - Initial release
// =====================================================================================================================

import Foundation
import SwifterSockets
import SecureSockets
import SwifterLog


fileprivate func httpServerErrorHandler(message: String) {
    Log.atError?.log(
        message: message,
        from: Source(id: -1, file: #file, function: #function, line: #line)
    )
}

fileprivate func httpsServerErrorHandler(message: String) {
    Log.atError?.log(
        message: message,
        from: Source(id: -1, file: #file, function: #function, line: #line)
    )
}


func restartHttpAndHttpsServers() {

    
    // Stop the HTTP server (if running)
    
    if httpServer?.isRunning ?? false {
        
        Log.atNotice?.log(
            message: "Stopping HTTP server",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        
        httpServer?.stop()
        
        telemetry.httpServerStatus.value = "Stopping"
        
        
        // Wait until it is stopped
        
        var waitLimiter = 0
        while httpServer?.isRunning ?? true {
            _ = Darwin.sleep(1)
            if waitLimiter == 60 { break }
            waitLimiter += 1
        }
        
        if !(httpServer?.isRunning ?? false) {
            telemetry.httpServerStatus.value = "Not Running"
        }
    }
    
    
    // Stop the HTTPS server (if running)
    
    if httpsServer?.isRunning ?? false {
        
        Log.atNotice?.log(
            message: "Stopping HTTPS server",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        
        httpsServer?.stop()
        
        telemetry.httpsServerStatus.value = "Stopping"
    
        
        // Wait until it is stopped
        
        var waitLimiter = 0
        while httpsServer?.isRunning ?? true {
            _ = Darwin.sleep(1)
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
        
        Log.atNotice?.log(
            message: "Initialized the connection pool with \(parameters.maxNofAcceptedConnections) http connections",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        
        
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
        
        Log.atCritical?.log(
            message: "No HTTP server created",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        telemetry.httpServerStatus.value = "Cannot"
        
        
    case let .error(message)?:
        
        Log.atError?.log(
            message: message,
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        telemetry.httpServerStatus.value = "Error, see log"
        
        
    case .success?:
        
        Log.atNotice?.log(
            message: "HTTP Server started on port \(parameters.httpServicePortNumber)",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        
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
        
        Log.atCritical?.log(
            message: "No certificate or private key (or combo) found, cannot start the HTTPS server",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        
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
            
            Log.atCritical?.log(
                message: "No HTTPS server created",
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
            telemetry.httpsServerStatus.value = "Cannot"
            
            
        case let .error(message)?:
            
            Log.atError?.log(
                message: message,
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
            telemetry.httpsServerStatus.value = "Error"
            
            
        case .success?:
            
            Log.atNotice?.log(
                message: "HTTPS Server started on port \(parameters.httpsServicePortNumber)",
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
            
            // Log the conditions the server is running under
            
            logServerSetup()
            
            telemetry.httpsServerStatus.value = "Running"
        }
    }
}

fileprivate func buildServerCtx() -> ServerCtx? {
    
    guard let sslServerDir = StorageUrls.sslServerDir else {
        Log.atError?.log(
            message: "No sll server directory found",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    
    // Get all files in the ssl directory
    
    guard let files = try? FileManager.default.contentsOfDirectory(at: sslServerDir, includingPropertiesForKeys: [.isReadableKey], options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles]) else {
        
        Log.atWarning?.log(
            message: "Directory \(sslServerDir.path) is empty (no cert or key file found)",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    
    // Filter for PEM files
    
    let pemFiles = files.flatMap({ $0.pathExtension.compare("pem", options: [.caseInsensitive], range: nil, locale: nil) == ComparisonResult.orderedSame ? $0 : nil })
    
    if pemFiles.count == 0 {
        Log.atInfo?.log(
            message: "No pem files found in \(sslServerDir.path)",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    
    // Filter for files containing 'cert'
    
    let certFiles = pemFiles.flatMap({ $0.lastPathComponent.contains("cert") ? $0 : nil })
    
    if certFiles.count != 1 {
        if certFiles.count == 0 {
            Log.atInfo?.log(
                message: "No certificate file found in \(sslServerDir.path) (filename should contain the lowercase characters 'cert'",
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
        } else {
            Log.atInfo?.log(
                message: "Too many certificate files found in \(sslServerDir.path) (filenames  containing the lowercase characters 'cert'",
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
        }
        return nil
    }
    
    
    // Filter for files containing 'key'
    
    let keyFiles = pemFiles.flatMap({ $0.lastPathComponent.contains("key") ? $0 : nil })
    
    if keyFiles.count != 1 {
        if keyFiles.count == 0 {
            Log.atInfo?.log(
                message: "No (private) key file found in \(sslServerDir.path) (filename should contain the lowercase characters 'key'",
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
        } else {
            Log.atInfo?.log(
                message: "Too many (private) key files found in \(sslServerDir.path) (filenames containing the lowercase characters 'key'",
                from: Source(id: -1, file: #file, function: #function, line: #line)
            )
        }
        return nil
    }
    
    
    // Create the server CTX
    
    guard let ctx = ServerCtx() else {
        Log.atError?.log(
            message: "Server context creation failed",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    
    // Add the certificate and (private) key
    
    if case let .error(message) = ctx.useCertificate(file: EncodedFile(path: certFiles[0].path, encoding: .pem)) {
        Log.atWarning?.log(
            message: message,
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    if case let .error(message) = ctx.usePrivateKey(file: EncodedFile(path: keyFiles[0].path, encoding: .pem)) {
        Log.atWarning?.log(
            message: message,
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    if case let .error(message) = ctx.checkPrivateKey() {
        Log.atWarning?.log(
            message: message,
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    
    // Check validity period
    
    guard let cert = X509(ctx: ctx) else {
        Log.atWarning?.log(
            message: "Failure retrieving certificate store from context",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    let today = Date().javaDate
    
    if today < cert.validNotBefore {
        Log.atWarning?.log(
            message: "Certificate at \(certFiles[0].path) is not yet valid",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    if today > cert.validNotAfter {
        Log.atWarning?.log(
            message: "Certificate at \(certFiles[0].path) is no longer valid",
            from: Source(id: -1, file: #file, function: #function, line: #line)
        )
        return nil
    }
    
    let validForDays = (cert.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
    
    Log.atInfo?.log(
        message: "Server certificate is valid for \(validForDays) more days",
        from: Source(id: -1, file: #file, function: #function, line: #line)
    )
    
    return ctx
}

fileprivate func checkDomainCtxs() -> [ServerCtx] {
    
    let today = Date().javaDate
    
    var domainCtxs = domains.ctxs
    
    for domain in domains {
        
        switch domain.ctx {
            
        case let .error(message): Log.atWarning?.log(
            message: message,
            from: Source(id: -1, file: #file, function: #function, line: #line)
            )
            
        case let .success(ctx):
            
            let cert = X509(ctx: ctx)
            
            if cert != nil {
                
                if today < cert!.validNotBefore {
                    
                    Log.atWarning?.log(
                        message: "Certificate for domain \(domain.name) is not yet valid",
                        from: Source(id: -1, file: #file, function: #function, line: #line)
                    )
                    
                } else if today > cert!.validNotAfter {
                    
                    Log.atWarning?.log(
                        message: "Certificate for domain \(domain.name) is no longer valid",
                        from: Source(id: -1, file: #file, function: #function, line: #line)
                    )
                    
                } else {
                    
                    let validForDays = (cert!.validNotAfter - today)/Int64(24 * 60 * 60 * 1000)
                    
                    Log.atInfo?.log(
                        message: "Server certificate is valid for \(validForDays) more days",
                        from: Source(id: -1, file: #file, function: #function, line: #line)
                    )
                    
                    domainCtxs.append(ctx)
                }
                
            } else {
                
                Log.atInfo?.log(
                    message: "Cannot extract certificate of domain \(domain.name)",
                    from: Source(id: -1, file: #file, function: #function, line: #line)
                )
            }
        }
    }
    
    return domainCtxs
}
