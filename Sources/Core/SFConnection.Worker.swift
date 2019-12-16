// =====================================================================================================================
//
//  File:       HttpConnection.HttpWorker.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Removed inout from the service signature
//       - Changed account handling
// 1.2.0 - Added domain admin to access setup page even when the domain is disabled
// 1.0.0 - Raised to v1.0.0, Removed old change log,
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
        
        serverTelemetry.nofHttp400Replies.increment()
        
        
        // Log update
        
        Log.atDebug?.log(message, id: logId)
        
        
        // Reply to client
        
        let response = Response()
        response.code = ._400_BadRequest
        response.version = .http1_1
        response.createErrorMessageInBody(message: "<p>\(message)</p>")
        if let data = response.data {
            transfer(data)
        } else {
            Log.atError?.log("Failed to create HTTP reply with message = '\(message)'", id: logId)
        }
    }
    
    
    /// Create an error if http1.0 is not supported.
    
    private func send500InternalServerError(_ message: String, processingStartedAt: Int64) {
        
        
        // Telemetry update
        
        serverTelemetry.nofHttp500Replies.increment()
        
        
        // Logging update
        
        Log.atDebug?.log(message, id: logId)
        
        
        // Reply to client
        
        let response = Response()
        response.code = ._500_InternalServerError
        response.version = .http1_1
        response.createErrorMessageInBody(message: "<p>\(message)</p>")
        if let data = response.data {
            transfer(data)
        } else {
            Log.atError?.log("Failed to create HTTP reply with message = '\(message)'", id: logId)
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
                
                if domainManager.domain(for: serverParameters.http1_0DomainName.value) != nil {
                    
                    host = Host(address: serverParameters.http1_0DomainName.value, port: nil)
                    
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
        
        if domainManager.count == 0 {
            domain = serverAdminDomain
        }
        
        
        // If the domain is not set, retrieve the domain from the request
        
        var errorMessage: String?
        if domain == nil {
        
            
            // Get the domain from the host
            
            if let hostDomain = domainManager.domain(for: host.address) {
                
                
                // Make sure the domain is enabled
                
                if hostDomain.enabled {
                    
                    domain = hostDomain
                
                } else {
                
                    
                    // The domain is disabled, but allow domain admin accesses
                    
                    if let setupKeyword = hostDomain.setupKeyword, let urlStr = request.url, urlStr.hasPrefix("/\(setupKeyword)") {
                         
                        domain = hostDomain
                        
                    } else {
                        errorMessage = "Domain not enabled for host: \(host.address)"
                    }
                }
            
            } else {
                errorMessage = "Domain not found for host: \(host.address)"
            }
        }

        if let errorMessage = errorMessage {
            send400BadRequestResponse(errorMessage, processingStartedAt: timestampResponseStart)
            return
        }
        
        Log.atDebug?.log("Request for domain: \(domain.name)", id: logId)
        
        
        // =============================================================================================================
        // Evaluate forwarding
        // =============================================================================================================
        //
        // In case of forwarding do not check other header fields, simply transfer everything to the new destination.
        
        if domain.forwardHost != nil {
            
            if forwarder == nil {
                let result = SwifterSockets.connectToTipServer(atAddress: domain.forwardHost!.address, atPort: (domain.forwardHost!.port ?? "80"), connectionObjectFactory: forwardingConnectionFactory)
                
                if case let .error(message) = result {
                    Log.atError?.log(message, id: logId)
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

            return
        }
        
        
        // =============================================================================================================
        // Increment the access counter for the domain
        // =============================================================================================================

        domain.telemetry.nofRequests.increment()

        
        // =============================================================================================================
        // Access logging
        // =============================================================================================================
        
        domain.accessLog.record(
            time: timeOfAccept,
            ipAddress: remoteAddress,
            url: request.url ?? "",
            operation: request.method?.rawValue ?? "",
            version: request.version?.rawValue ?? ""
        )

        
        // =============================================================================================================
        // Execute the service chain
        // =============================================================================================================

        Log.atDebug?.log("Starting domain services", id: logId)

        let response = Response()
        response.version = httpVersion
        response.contentType = mimeTypeDefault
        
        
        let serviceInfo = Services.Info()
        serviceInfo[.responseStartedKey] = timestampResponseStart

        for item in domain.services {
            
            if serverParameters.debugMode.value {

                Log.atDebug?.log("Service: \(item.name)", id: logId)
            }

            
            // ******************** SERVICE CALL
            if item.service(request, self, domain, serviceInfo, response) == .abort { break }
            // ********************
            
            if serverParameters.debugMode.value {

                if serviceInfo.dict.count == 0 {
                    Log.atDebug?.log( "\n\nService info is empty", id: logId)
                } else {
                    var str = ""
                    str += serviceInfo.dict.map({ key, value in "Key: \(key), Value: \(value)" }).joined(separator: "\n")
                    Log.atDebug?.log("\n\nService info:\n\(str)\n", id: logId)
                }
                
                Log.atDebug?.log("\n\n\(response)\n", id: logId)
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
            account: session?[.accountUuidKey] as? String,
            responseCode: response.code ?? Response.Code._500_InternalServerError,
            request: request.asData(),
            responseData: response.data
        )
        
        domain.recordStatistics(visit)
 
        
        Log.atInfo?.log("Response took \(completed - timestampResponseStart) milli seconds", id: logId)
    }
}





