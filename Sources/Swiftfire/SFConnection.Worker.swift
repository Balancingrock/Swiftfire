// =====================================================================================================================
//
//  File:       HttpConnection.HttpWorker.swift
//  Project:    Swiftfire
//
//  Version:    0.10.12
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
//         - Separated the response transfer into its own service
//         - Separated the session restart into its own service
//         - Rewrote statistics package
// 0.10.11 - Renamed createErrorMessageInBody
//         - Replaced SwifterJSON with VJson
// 0.10.10 - Added 'Darwin' to sleep statements.
// 0.10.9 - Streamlined and folded http API into its own project
// 0.10.6 - Updated parameters to services & transmission of response
//        - Renamed chain... to service...
//        - Added freeing of session.
// 0.10.6 - Renamed HttpHeader to HttpRequest
// 0.10.5 - Added more debug output
// 0.10.0 - Renamed HttpConnection to SFConnection
// 0.9.18 - Header update
//        - Replaced log by Log?
// 0.9.15 - General update and switch to frameworks
//        - Updated domainServices
// 0.9.14 - Added support for HTTP 1.0
//        - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Added support for usage statistics
// 0.9.6  - Header update
// 0.9.3  - Added incrementing of serverTelemetry.nofHttp400Replies if the host cannot be mapped to a domain
//        - Split "domain not found" error into "domain not found" and "domain not enabled"
//        - Removed port information from "domain not found/enabled" error
// 0.9.2  - Made forwarding case cleaner
//        - Moved the code that provides a response to the Domain class
// 0.9.0  - Initial release
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
import VJson
import SwifterLog
import SwifterSockets
import Http


extension SFConnection {
    
    
    /// Create an error for a missing http version
    
    private func send400BadRequestResponse(_ message: String, processingStartedAt: Int64) {
        
        
        // Telemetry update
        
        telemetry.nofHttp400Replies.increment()
        
        
        // Log update
        
        Log.atDebug?.log(
            message,
            from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
        )
        
        
        // Reply to client
        
        let response = Response()
        response.code = ._400_BadRequest
        response.version = .http1_1
        response.createErrorMessageInBody(message: "<p>\(message)</p>")
        if let data = response.data {
            transfer(data)
        } else {
            Log.atError?.log(
                "Failed to create HTTP reply with message = '\(message)'",
                from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
            )
        }
    }
    
    
    /// Create an error if http1.0 is not supported.
    
    private func send500InternalServerError(_ message: String, processingStartedAt: Int64) {
        
        
        // Telemetry update
        
        telemetry.nofHttp500Replies.increment()
        
        
        // Logging update
        
        Log.atDebug?.log(
            message,
            from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
        )
        
        
        // Reply to client
        
        let response = Response()
        response.code = ._500_InternalServerError
        response.version = .http1_1
        response.createErrorMessageInBody(message: "<p>\(message)</p>")
        if let data = response.data {
            transfer(data)
        } else {
            Log.atError?.log(
                "Failed to create HTTP reply with message = '\(message)'",
                from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
            )
        }
    }
    
    
    /// Examines the http message header for a servicable request and creates the corresponding response.
    /// Implementation justification:
    
    func worker(_ request: Request) {
        
        
        // To determine how long it takes to create a response message
        
        let timestampResponseStart = Date().javaDate
        

        // The Http version is necessary to be able to prepare a response
        
        guard let httpVersion = request.version else {
            send400BadRequestResponse("HTTP Version not present", processingStartedAt: timestampResponseStart)
            return
        }

        
        // =============================================================================================================
        // Find the domain (host) this request is for.
        // =============================================================================================================

        var domain: Domain!
        var host: Http.Host
        
        
        // Find the host. For HTTP 1.1 this must be provided in the request, for HTTP 1.0 it should be defined in the parameter 'http1_0DomainName'
        
        if let _host = request.host {
            
            host = _host
        
        } else {
            
            
            // No host found, and this is a HTTP1.0 request, then use the predefined http1_0DomainName as the 'host'.
            
            if httpVersion == Version.http1_0 {
                
                
                // Find the domain, if none is found, then http 1.0 is not supported
                
                if domains.domain(forName: parameters.http1_0DomainName.value) != nil {
                    
                    host = Host(address: parameters.http1_0DomainName.value, port: nil)
                    
                } else {
                
                    send500InternalServerError("HTTP 1.0 requests not supported", processingStartedAt: timestampResponseStart)
                    
                    return
                }

            } else {
                
                send400BadRequestResponse("Could not extract host from Http Request Header", processingStartedAt: timestampResponseStart)
                
                return
            }
        }

        
        // A special case is made for the server admin pseudo domain
        
        if let urlStr = request.url, urlStr.hasPrefix("/serveradmin") {
            domain = serverAdminDomain
        }
        
        
        // If there is no serverAdminDomain account, request the creation of server admin account
        
        if serverAdminDomain.accounts.count == 0 {
            domain = serverAdminDomain
        }
        
        
        // If there are no domains defined, always switch to the serveradmin domain
        
        if domains.count == 0 {
            domain = serverAdminDomain
        }
        
        
        // If the domain is not set, retrieve the domain from the request
        
        if domain == nil {
        
            
            // Get the domain from the host
            
            if let hostDomain = domains.domain(forName: host.address), hostDomain.enabled {
                
                domain = hostDomain
            
            } else {
                
                let message: String
                if domains.domain(forName: host.address) == nil {
                    message = "Domain not found for host: \(host.address)"
                } else {
                    message = "Domain not enabled for host: \(host.address)"
                }
                
                send400BadRequestResponse(message, processingStartedAt: timestampResponseStart)
                
                return
            }
        }

        Log.atDebug?.log(
            "Request for domain: \(domain.name)",
            from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
        )
        
        
        // =============================================================================================================
        // Evaluate forwarding
        // =============================================================================================================
        //
        // In case of forwarding do not check other header fields, simply transfer everything to the new destination.
        
        if domain.forwardHost != nil {
            
            if forwarder == nil {
                let result = SwifterSockets.connectToTipServer(atAddress: domain.forwardHost!.address, atPort: (domain.forwardHost!.port ?? "80"), connectionObjectFactory: forwardingConnectionFactory)
                
                if case let .error(message) = result {
                    Log.atError?.log(
                        message,
                        from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
                    )
                }
                if case let .success(conn) = result {
                    forwarder = conn as? Forwarder
                    forwarder!.client = self
                }
            
                if forwarder != nil {
                    var data: Data = request.asData()!
                    if let body = request.body { data.append(body) }
                    _ = forwarder?.transfer(data, callback: nil)
                }
            }
            
            // The forwarding connection will be closed when the forwarding target closes its connection. Until then all data received from the forwarding target will be routed to the client.

            // Statistics update
            /*let mutation = Mutation.createAddClientRecord(from: self)
            mutation.domain = domain.name
            mutation.httpResponseCode = "Unavailable"
            mutation.responseDetails = "Forwarding of domain '\(host.address)'"
            mutation.requestReceived = timestampResponseStart
            statistics.submit(mutation: mutation) {
                [unowned self] (message: String) in
                Log.atError?.log(
                    message: message,
                    from: Source(id: self.logId, file: #file, type: "SFConnection", function: #function, line: #line)
                )
            }*/

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
            url: request.url ?? "",
            operation: request.method?.rawValue ?? "",
            version: request.version?.rawValue ?? "")

        
        // =============================================================================================================
        // Execute the service chain
        // =============================================================================================================

        Log.atDebug?.log(
            "Starting domain services",
            from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
        )

        var response = Response()
        response.version = httpVersion
        response.contentType = mimeTypeDefault
        
        
        var serviceInfo = Service.Info()
        serviceInfo[.responseStartedKey] = timestampResponseStart

        for item in domain.services {
            
            if parameters.debugMode.value {

                Log.atDebug?.log(
                    "Service: \(item.name)",
                    from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
                )
            }

            
            // ******************** SERVICE CALL
            if item.service(request, self, domain, &serviceInfo, &response) == .abort { break }
            // ********************
            
            if parameters.debugMode.value {

                if serviceInfo.dict.count == 0 {
                    Log.atDebug?.log(
                        "\n\nService info is empty",
                        from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
                    )
                } else {
                    var str = ""
                    str += serviceInfo.dict.map({ key, value in "Key: \(key), Value: \(value)" }).joined(separator: "\n")
                    Log.atDebug?.log(
                        "\n\nService info:\n\(str)\n",
                        from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
                    )
                }
                
                Log.atDebug?.log(
                    "\n\n\(response)\n",
                    from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
                )
            }
        }
        
        
        // Update the statistics
        
        let completed = Date().javaDate
        let session = serviceInfo[.sessionKey] as? Session
        
        let visit = Visit(
            received: timestampResponseStart,
            completed: completed,
            url: serviceInfo[.relativeResourcePathKey] as? String ?? "Unknown",
            address: self.remoteAddress,
            session: session?.id,
            account: (session?[.accountKey] as? Account)?.uuid,
            responseCode: response.code ?? Response.Code._500_InternalServerError,
            request: request.asData(),
            responseData: response.data
        )
        
        domain.recordStatistics(visit)
 
        
        Log.atInfo?.log(
            "Response took \(completed - timestampResponseStart) milli seconds",
            from: Source(id: logId, file: #file, type: "SFConnection", function: #function, line: #line)
        )
    }
}





