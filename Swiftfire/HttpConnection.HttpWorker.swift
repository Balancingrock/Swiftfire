// =====================================================================================================================
//
//  File:       HttpConnection.HttpWorker.swift
//  Project:    Swiftfire
//
//  Version:    0.9.2
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swiftfire.html
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// v0.9.2 - Made forwarding case cleaner
//        - Moved the code that provides a response to the Domain class
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = ((#file as NSString).lastPathComponent as NSString).stringByDeletingPathExtension


extension HttpConnection {
    
    
    /// Examines the http message header for a servicable request and creates the corresponding response.
    /// Implementation justification:  
    
    func httpWorker(header header: HttpHeader, body: UInt8Buffer) {
        
        
        // =============================================================================================================
        // Find the domain this request is for
        // =============================================================================================================
        
        guard let host = header.host else {
            log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "Could not extract host from Http Request Header")
            let response = httpErrorResponseWithCode(.CODE_400_Bad_Request, andMessage: "<p>Could not extract host from Http Request Header<p>")
            transferToClient(response)
            return
        }
        
        guard let domain = domains.enabledDomainForName(host.address) else {
            log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "Domain not found for host: \(host.address), port: \(host.port)")
            let response = httpErrorResponseWithCode(.CODE_400_Bad_Request, andMessage: "<p>Domain not found for host: \(host.address), port: \(host.port)</p>")
            transferToClient(response)
            return
        }
        
        
        // =============================================================================================================
        // Evaluate forwarding
        // =============================================================================================================
        //
        // In case of forwarding do not check other header fields, simply transfer everything to the new destination.
        
        if domain.forwardHost != nil {
            if forwardingSocket == nil { forwardingOpenConnection(domain.forwardHost!) }
            if forwardingSocket != nil { forwardingTransmit(UInt8Buffer(buffers: header.asUInt8Buffer(), body)) }
            // The forwarding connection will be closed when the forwarding target closes its connection. Until then all data received from the forwarding target will be routed to the client.
            return
        }
        
        
        // =============================================================================================================
        // The domain takes over from here
        // =============================================================================================================

        let response = domain.httpWorker(header, body: body, connection: self)

        
        // =================================================================================================================
        // Transfer the reply
        // =================================================================================================================
        
        transferToClient(response)
    }
}