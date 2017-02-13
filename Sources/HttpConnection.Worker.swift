// =====================================================================================================================
//
//  File:       HttpConnection.HttpWorker.swift
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
// v0.9.15 - General update and switch to frameworks
// v0.9.14 - Added support for HTTP 1.0
//         - Upgraded to Xcode 8 beta 6
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.11 - Added support for usage statistics
// v0.9.6  - Header update
// v0.9.3  - Added incrementing of serverTelemetry.nofHttp400Replies if the host cannot be mapped to a domain
//         - Split "domain not found" error into "domain not found" and "domain not enabled"
//         - Removed port information from "domain not found/enabled" error
// v0.9.2  - Made forwarding case cleaner
//         - Moved the code that provides a response to the Domain class
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import SwifterSockets
import SwiftfireCore


extension HttpConnection {
    
    
    /// Examines the http message header for a servicable request and creates the corresponding response.
    /// Implementation justification:  
    
    func worker(header: HttpHeader, body: Data) {
        
        
        // =============================================================================================================
        // Create a new statistics record for this message
        // =============================================================================================================

        let mutation = Mutation.createAddClientRecord()
        mutation.ipAddress = remoteAddress
        mutation.connectionAllocationCount = allocationCount
        mutation.connectionObjectId = objectId
        mutation.socket = logId
        mutation.requestReceived = Date().javaDate
        
        
        // =============================================================================================================
        // Check which protocol version is used
        // =============================================================================================================
        
        // =============================================================================================================
        // Special case for HTTP version 1.0
        // =============================================================================================================
        
        // HTTP/1.0 does not contain a "Host" field. It is therefore handled seperately.

        guard let httpVersion = header.httpVersion else {
            
            // Telemetry update
            telemetry.nofHttp400Replies.increment()
            
            // Log update
            let message = "HTTP Version not present"
            log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: message)
            
            // Reply to client
            let response = HttpResponse.withCode(.code400_BadRequest, version: .http1_1, message: "<p>\(message)</p>")
            transfer(response)

            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
            mutation.responseDetails = message
            mutation.requestCompleted = Date().javaDate
            statistics.submit(mutation: mutation)
            
            return
        }
        

        // =============================================================================================================
        // Find the domain this request is for
        // =============================================================================================================

        var host: Host
        
        if let _host = header.host {
            
            host = _host
        
        } else {
            
            // No host found, if this is a HTTP1.0 request, then use the spefied domain as the 'host'.
            
            if httpVersion == HttpVersion.http1_0 {
                
                if domains.domain(forName: parameters.http1_0DomainName) != nil {
                    
                    host = Host(address: parameters.http1_0DomainName, port: nil)
                    
                } else {
                
                    // Telemetry update
                    telemetry.nofHttp500Replies.increment()
                    
                    // Logging update
                    let message = "Domain name for HTTP 1.0 requests not defined or domain not present"
                    log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: message)
                    
                    // Reply to client
                    let response = HttpResponse.withCode(.code500_InternalServerError, version: httpVersion, message: "<p>\(message)</p>")
                    transfer(response)
                    
                    // Mutation update
                    mutation.httpResponseCode = HttpResponseCode.code500_InternalServerError.rawValue
                    mutation.responseDetails = message
                    mutation.requestCompleted = Date().javaDate
                    statistics.submit(mutation: mutation)
                    
                    return
                }

            } else {
                
                // Telemetry update
                telemetry.nofHttp400Replies.increment()
                
                // Logging update
                let message = "Could not extract host from Http Request Header"
                log.atLevelDebug(id: logId, source: #file.source(#function, #line), message: message)
                
                // Reply to client
                let response = HttpResponse.withCode(.code400_BadRequest, version: httpVersion, message: "<p>\(message)</p>")
                transfer(response)
                
                // Mutation update
                mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
                mutation.responseDetails = message
                mutation.requestCompleted = Date().javaDate
                statistics.submit(mutation: mutation)
                
                return
            }
        }
        
        guard let domain = domains.domain(forName: host.address), domain.enabled else {
            
            // Telemetry update
            telemetry.nofHttp400Replies.increment()
            
            // Logging update
            let message: String
            if domains.domain(forName: host.address) == nil {
                message = "Domain not found for host: \(host.address)"
            } else {
                message = "Domain not enabled for host: \(host.address)"
            }
            log.atLevelNotice(id: logId, source: #file.source(#function, #line), message: message)
            
            // Reply to client
            let response = HttpResponse.withCode(.code400_BadRequest, version: httpVersion, message: "<p>\(message)</p>")
            transfer(response)
            
            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
            mutation.responseDetails = message
            mutation.requestCompleted = Date().javaDate
            statistics.submit(mutation: mutation)

            return
        }
            
        // Update mutation
        
        mutation.domain = domain.name
        
        
        // =============================================================================================================
        // Evaluate forwarding
        // =============================================================================================================
        //
        // In case of forwarding do not check other header fields, simply transfer everything to the new destination.
        
        if domain.forwardHost != nil {
            
            if forwarder == nil {
                let result = SwifterSockets.connectToTipServer(atAddress: domain.forwardHost!.address, atPort: (domain.forwardHost!.port ?? "80"), connectionObjectFactory: forwardingConnectionFactory)
                
                if case let .error(message) = result {
                    log.atLevelError(id: logId, source: #file.source(#function, #line), message: message)
                }
                if case let .success(conn) = result {
                    forwarder = conn as? Forwarder
                    forwarder!.client = self
                }
            
                if forwarder != nil {
                    var data: Data = header.asData()!
                    data.append(body)
                    _ = forwarder?.transfer(data, callback: nil)
                }
            }
            
            // The forwarding connection will be closed when the forwarding target closes its connection. Until then all data received from the forwarding target will be routed to the client.

            // Mutation update
            mutation.httpResponseCode = "Unavailable"
            mutation.responseDetails = "Forwarding of domain '\(host.address)'"
            mutation.requestCompleted = Date().javaDate
            statistics.submit(mutation: mutation)

            return
        }
        
        
        // =============================================================================================================
        // The domain takes over from here
        // =============================================================================================================

        if let response = domain.httpWorker(header: header, body: body, connection: self, mutation: mutation) {
            
            transfer(response)
        
            // Mutation update
            mutation.httpResponseCode ??= HttpResponseCode.code200_OK.rawValue
            mutation.responseDetails ??= ""
            mutation.requestCompleted = Date().javaDate
            statistics.submit(mutation: mutation)
        
        } else {
        
            // If no data is returned the domain does not want to serve the client, in that case the statistics are not updated and the connection should close asap.
            mustClose = true
        }
    }
}
