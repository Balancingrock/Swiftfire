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
// 0.9.15  - General update and switch to frameworks
//         - Updated domainServices
// 0.9.14  - Added support for HTTP 1.0
//         - Upgraded to Xcode 8 beta 6
// 0.9.13  - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11  - Added support for usage statistics
// 0.9.6   - Header update
// 0.9.3   - Added incrementing of serverTelemetry.nofHttp400Replies if the host cannot be mapped to a domain
//         - Split "domain not found" error into "domain not found" and "domain not enabled"
//         - Removed port information from "domain not found/enabled" error
// 0.9.2   - Made forwarding case cleaner
//         - Moved the code that provides a response to the Domain class
// 0.9.0   - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Handles the work associated with a HTTP connection object. Once a complete HTTP request is received, this operation
// starts processing that request. After a some validation it starts the services for the domain the request is for.
// Upon completion of the services, it will send a response to the client.
//
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import SwifterSockets
import SwiftfireCore


extension HttpConnection {
    
    
    /// Create an error for a missing http version
    
    private func send400BadRequestResponse(_ message: String, processingStartedAt: Int64) {
        
        
        // Telemetry update
        
        telemetry.nofHttp400Replies.increment()
        
        
        // Log update
        
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: message)
        
        
        // Reply to client
        
        let response = createHttpResponse(for: .code400_BadRequest, version: .http1_1, message: "<p>\(message)</p>")
        transfer(response)
        
        
        // Statistics update
        
        let mutation = Mutation.createAddClientRecord(from: self)
        mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
        mutation.responseDetails = message
        mutation.requestReceived = processingStartedAt
        statistics.submit(mutation: mutation, onError: {
            [unowned self] (message: String) in
            log.atLevelError(id: self.logId, source: #file.source(#function, #line), message: message)
        })

    }
    
    
    /// Create an error if http1.0 is not supported.
    
    private func send500InternalServerError(_ message: String, processingStartedAt: Int64) {
        
        
        // Telemetry update
        
        telemetry.nofHttp500Replies.increment()
        
        
        // Logging update
        
        Log.atDebug?.log(id: logId, source: #file.source(#function, #line), message: message)
        
        
        // Reply to client
        
        let response = createHttpResponse(for: .code500_InternalServerError, version: .http1_0, message: "<p>\(message)</p>")
        transfer(response)
        
        
        // Statistics update
        
        let mutation = Mutation.createAddClientRecord(from: self)
        mutation.httpResponseCode = HttpResponseCode.code500_InternalServerError.rawValue
        mutation.responseDetails = message
        mutation.requestReceived = processingStartedAt
        statistics.submit(mutation: mutation, onError: {
            [unowned self] (message: String) in
            log.atLevelError(id: self.logId, source: #file.source(#function, #line), message: message)
        })

    }
    
    
    /// Examines the http message header for a servicable request and creates the corresponding response.
    /// Implementation justification:
    
    func worker(header: HttpHeader, body: Data) {
        
        
        // To determine how long it takes to create a response message
        
        let timestampResponseStart = Date().javaDate
        
        

        // =============================================================================================================
        // Find the domain (host) this request is for.
        // =============================================================================================================

        guard let httpVersion = header.httpVersion else {
            send400BadRequestResponse("HTTP Version not present", processingStartedAt: timestampResponseStart)
            return
        }
        
        var host: HttpHost
        
        
        // Find the host. For HTTP 1.1 this must be provided in the request, for HTTP 1.0 it should be defined in the parameter 'http1_0DomainName'
        
        if let _host = header.host {
            
            host = _host
        
        } else {
            
            
            // No host found, and this is a HTTP1.0 request, then use the predefined http1_0DomainName as the 'host'.
            
            if httpVersion == HttpVersion.http1_0 {
                
                
                // Find the domain, if none is found, then http 1.0 is not supported
                
                if domains.domain(forName: parameters.http1_0DomainName) != nil {
                    
                    host = HttpHost(address: parameters.http1_0DomainName, port: nil)
                    
                } else {
                
                    send500InternalServerError("HTTP 1.0 requests not supported", processingStartedAt: timestampResponseStart)
                    
                    return
                }

            } else {
                
                send400BadRequestResponse("Could not extract host from Http Request Header", processingStartedAt: timestampResponseStart)
                
                return
            }
        }
        
        
        // Get the domain
        
        guard let domain = domains.domain(forName: host.address), domain.enabled else {
            
            let message: String
            if domains.domain(forName: host.address) == nil {
                message = "Domain not found for host: \(host.address)"
            } else {
                message = "Domain not enabled for host: \(host.address)"
            }
            
            send400BadRequestResponse(message, processingStartedAt: timestampResponseStart)

            return
        }

        
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

            // Statistics update
            let mutation = Mutation.createAddClientRecord(from: self)
            mutation.domain = domain.name
            mutation.httpResponseCode = "Unavailable"
            mutation.responseDetails = "Forwarding of domain '\(host.address)'"
            mutation.requestReceived = timestampResponseStart
            statistics.submit(mutation: mutation) {
                [unowned self] (message: String) in
                log.atLevelError(id: self.logId, source: #file.source(#function, #line), message: message)
            }

            return
        }
        
        
        // =============================================================================================================
        // Increment the access counter for the domain
        // =============================================================================================================

        domain.telemetry.nofRequests.increment()

        
        // =============================================================================================================
        // Access logging
        // =============================================================================================================
        
        domain.recordInAccessLog(
            time: timeOfAccept,
            ipAddress: remoteAddress,
            url: header.url ?? "",
            operation: header.operation?.rawValue ?? "",
            version: header.httpVersion?.rawValue ?? "")

        
        // =============================================================================================================
        // Start the service chain
        // =============================================================================================================

        var response = DomainServices.Response(httpVersion, mimeTypeDefault)
        
        // Note: Since the response.code is not set, it is possible to only consume a request and not transmit any response.
        
        var chainInfo = DomainServices.ChainInfo()
        chainInfo[ResponseStartedKey] = timestampResponseStart

        for item in domain.services {
            if item.service(header, body, self, domain, &chainInfo, &response) == .abortChain { break }
        }
        
        
        // =============================================================================================================
        // Send reply
        // =============================================================================================================
        
        // If there is no code, nothing will be returned
        
        guard let code = response.code else { return }
        
            
        // If there is data return that data
            
        if let payload = response.payload {
            
            
            // Wrap the data in a HTTP resonse
            
            let message = createHttpResponse(for: code, version: response.httpVersion, mimeType: response.mimeType, body: payload)
            
            
            // Transmit the response
            
            bufferedTransfer(message)

            
            // Update the statistics
            
            let mutation = Mutation.createAddClientRecord(from: self)
            mutation.domain = domain.name
            mutation.url = chainInfo[RelativeResourcePathKey] as? String ?? "Unknown resource path"
            mutation.httpResponseCode = code.rawValue
            mutation.responseDetails = ""
            mutation.requestReceived = timestampResponseStart
            statistics.submit(mutation: mutation, onError: {
                [unowned self] (message: String) in
                log.atLevelError(id: self.logId, source: #file.source(#function, #line), message: message)
            })

            log.atLevelInfo(id: logId, source: #file.source(#function, #line), message: "Response took \(Date().javaDate - timestampResponseStart) milli seconds")
            
        } else {
        
            // There is no data, try to create a domain specific default response
            
            if let payload = domain.customErrorResponse(for: code) {
                
                let message = createHttpResponse(for: code, version: response.httpVersion, mimeType: mimeTypeHtml, body: payload)
                bufferedTransfer(message)

                
            } else {
                
                
                // There is no domain default response, use the server default response
                
                let message = createHttpResponse(for: code, version: response.httpVersion)
                bufferedTransfer(message)
            }
        }
    }
}
