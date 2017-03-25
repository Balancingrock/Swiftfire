// =====================================================================================================================
//
//  File:       MacCommand.HttpsServerRun.swift
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
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
// 0.9.18 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterJSON
import SwiftfireCore
import SecureSockets
import SwifterSockets


fileprivate func serverErrorHandler(message: String) { Log.atError?.log(id: -1, source: "HTTPS Server", message: message) }


extension HttpsServerRunCommand: MacCommand {
    
    public static func factory(json: VJson?) -> MacCommand? {
        return HttpsServerRunCommand(json: json)
    }
    
    public func execute() {
        
        
        // If the server is running, don't do anything
        
        if httpsServer?.isRunning ?? false { telemetry.httpsServerStatus = "Running"; return }
        
        
        // If the http server is not running either, then reinit the available connections and domain services
        
        if !(httpServer?.isRunning ?? false) {
            
            
            // Reset available connections
            
            connectionPool.create(num: parameters.maxNofAcceptedConnections, generator: { return HttpConnection() })
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Initialized the connection pool with \(parameters.maxNofAcceptedConnections) http connections")
            
            
            // Rebuild the available services for the domains
        
            domains.forEach(){ $0.rebuildServices() }
        }
        
        
        // Get a server certificate and private key reference
        
        var serverCtx = buildServerCtx()

        
        // Create new domain CTXs
        
        var domainCtxs = checkDomainCtxs()
        

        if serverCtx == nil && domainCtxs.count == 0 {
            
            Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "No certificate or private key (or combo) found, cannot start the HTTPS server")
            
            telemetry.httpsServerStatus = "No Cert|Key"
        
        } else {
        
            
            // If there is a domain CTX but no server CTX, use the domain CTX instead
            
            if serverCtx == nil {
                serverCtx = domainCtxs[0]
                domainCtxs.remove(at: 0)
            }
            
            
            // Restart the HTTPS server
            
            httpsServer = SecureSockets.SslServer(
                .port(parameters.httpsServicePortNumber),
                .maxPendingConnectionRequests(Int(parameters.maxNofPendingConnections)),
                .acceptQueue(httpsServerAcceptQueue),
                .connectionObjectFactory(httpConnectionFactory),
                .acceptLoopDuration(2),
                .errorHandler(serverErrorHandler),
                .serverCtx(serverCtx),
                .domainCtxs(domainCtxs.count > 0 ? domainCtxs : nil)
            )
            
            switch httpsServer?.start() {
            
            case nil:
                
                log.atLevelCritical(id: -1, source: #file.source(#function, #line), message: "No HTTPS server created")
                telemetry.httpsServerStatus = "Cannot"
            
                
            case let .error(message)?:
                
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: message)
                telemetry.httpsServerStatus = "Error"
                
            
            case .success?:
                
                log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "HTTPS Server started on port \(parameters.httpsServicePortNumber)")
                telemetry.httpsServerStatus = "Running"
            }
        }
        
        log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Completed")
    }
}

fileprivate func buildServerCtx() -> ServerCtx? {
    
    guard let sslServerDir = FileURLs.sslServerDir else {
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
    
    let validForDays = (cert.validNotAfter - today)/(24 * 60 * 60 * 1000)
    
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
        
                    let validForDays = (cert!.validNotAfter - today)/(24 * 60 * 60 * 1000)
        
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
