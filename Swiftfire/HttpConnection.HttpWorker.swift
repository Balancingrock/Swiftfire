// =====================================================================================================================
//
//  File:       HttpConnection.HttpWorker.swift
//  Project:    Swiftfire
//
//  Version:    0.9.0
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
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = ((#file as NSString).lastPathComponent as NSString).stringByDeletingPathExtension


extension HttpConnection {
    
    
    /// Examines the http message header for a servicable request and creates the corresponding response.
    /// Implementation justification:  
    
    func httpWorker(header header: HttpHeader, body: UInt8Buffer) {
        
        
        // =================================================================================================================
        // Find the domain this request is for
        // =================================================================================================================
        
        guard let host = header.host else {
            log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "Could not extract host from HttpHeader")
            handleHttpCode400()
            return
        }
        
        guard let domain = domains.enabledDomainForName(host.address) else {
            log.atLevelDebug(id: logId, source: SOURCE + ".\(#function).\(#line)", message: "Domain not found for host: \(host.address), port: \(host.port)")
            handleHttpCode400()
            return
        }
        
        
        // =================================================================================================================
        // Evaluate forwarding
        // =================================================================================================================
        //
        // In case of forwarding do not check other header fields, simply transfer everything to the new destination.
        
        if domain.forwardHost != nil {
            forwardingOpenConnection(domain.forwardHost!)
            forwardingTransmit(UInt8Buffer(buffers: header.asUInt8Buffer(), body))
            // The forwarding connection will be closed when the forwarding target closes its connection. Until then all data received from the forwarding target will be routed to the client.
            return
        }
        
        
        // =================================================================================================================
        // The header must be HTML version 1.1
        // =================================================================================================================
        
        guard let httpVersion = header.httpVersion where httpVersion == HttpVersion.HTTP_1_1 else {
            log.atLevelDebug(id: logId, source: SOURCE + "\(#function).\(#line)", message: "HTTP Version not present or not 1.1")
            handleHttpCode505()
            return
        }
        
        
        // =================================================================================================================
        // It must be either a GET or POST operation
        // =================================================================================================================
        
        guard let operation = header.operation else {
            log.atLevelDebug(id: logId, source: SOURCE + "\(#function).\(#line)", message: "Could not extract operation")
            handleHttpCode400()
            return
        }
        
        guard (operation == HttpOperation.GET || operation == HttpOperation.POST) else {
            log.atLevelDebug(id: logId, source: SOURCE + "\(#function).\(#line)", message: "Operation not a GET or POST")
            handleHttpCode501()
            return
        }
        
        
        // =================================================================================================================
        // Determine the resource path
        // =================================================================================================================
        
        guard let partialPath = header.url else {
            log.atLevelDebug(id: logId, source: SOURCE + "\(#function).\(#line)", message: "No URL found")
            handleHttpCode400()
            return
        }
        let path = (domain.root as NSString).stringByAppendingPathComponent(partialPath)
        
        
        // =================================================================================================================
        // Check if the resource exists in the file system
        // =================================================================================================================
        
        if !filemanager.fileExistsAtPath(path) { handleHttpCode404() }
        
        
        // =================================================================================================================
        // Directory access is not allowed, but the index.html or index.htm will be returned if a directory is accessed and
        // it contains such a file
        // =================================================================================================================
        
        guard let resourcePath = filterForDirectoryAccess(path) else {
            handleDirAccessNotAllowed()
            return
        }

        
        // =================================================================================================================
        // Fetch the requested resource and return it
        // =================================================================================================================
        
        let responsePayload = createResponsePayloadForResourceAtPath(resourcePath)
        
        if responsePayload == nil { handleHttpCode500WithText("A Server side error occured, the error has been logged.") }
        
        
        // =================================================================================================================
        // Create the http header for the response
        // =================================================================================================================
        
        let responseHeaderString = "HTTP/1.1 " + HttpResponseCode.CODE_200_OK.rawValue + CRLF +
            "Date: \(NSDate())" + CRLF +
            "Server: Swiftfire/\(Parameters.version)" + CRLF +
            "Content-Type: text/html; charset=UTF-8" + CRLF +
            "Content-Length: \(responsePayload!.length)" + CRLFCRLF
        
        let responseHeader = responseHeaderString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        
        
        // =================================================================================================================
        // Add header and payload together
        // =================================================================================================================
        
        let response = UInt8Buffer(sizeInBytes: responseHeader.length + responsePayload!.length)
        
        response.add(responseHeader)
        response.add(responsePayload!)
        
        
        // =================================================================================================================
        // Increase the total number of replies
        // =================================================================================================================
        
        telemetry.nofSuccessfulHttpReplies.increment()
        
        
        // =================================================================================================================
        // Transfer the reply
        // =================================================================================================================
        
        transferToClient(response)
    }
    
    
    private func handleHttpCode400() {
        telemetry.nofHttp400Replies.increment()
        handleHttpErrorCode(.CODE_400_Bad_Request)
    }
    
    
    private func handleHttpCode404() {
        telemetry.nofHttp404Replies.increment()
        handleHttpErrorCode(.CODE_404_Not_Found)
    }
    
    
    private func handleHttpCode500WithText(text: String) {
        
        telemetry.nofHttp500Replies.increment()
        
        log.atLevelError(id: logId, source: #file.source(#function, #line), message: "Failure while creating HTTP Response")
        
        sendMessageWithCode(
            HttpResponseCode.CODE_500_Internal_Server_Error,
            title: nil,
            body: "<p>\(text)</p>")
    }
    
    
    private func handleHttpCode501() {
        telemetry.nofHttp501Replies.increment()
        handleHttpErrorCode(.CODE_501_Not_Implemented)
    }
    
    
    private func handleHttpCode505() {
        telemetry.nofHttp505Replies.increment()
        handleHttpErrorCode(.CODE_505_HTTP_Version_Not_Supported)
    }
    
    
    private func handleHttpErrorCode(code: HttpResponseCode) {
        
        let message = "HTTP Request rejected with: \(code.rawValue)"
        log.atLevelNotice(id: logId, source: #file.source(#function, #line), message: message)
        
        sendMessageWithCode(code, title: nil, body: nil)
    }
    
    
    private func handleDirAccessNotAllowed() {
        let message = "<p>Directory access not allowed</p>"
        sendMessageWithCode(HttpResponseCode.CODE_403_Forbidden, body: message)
    }
    
    
    /// - Returns: The resource path ammended by index.html or index.htm
    
    private func filterForDirectoryAccess(path: String) -> String? {
        
        
        // GP
        
        var isDirectory: ObjCBool = false
        
        
        // Test the unmodified path
        
        if filemanager.fileExistsAtPath(path, isDirectory: &isDirectory) {
            if !isDirectory {
                return path
            }
        } else {
            return nil
        }
        
        
        // The path exists, but it is a directory.
        
        
        // Check for an 'index.html' file
        
        let tpath = (path as NSString).stringByAppendingPathComponent("index.html")
        
        if filemanager.fileExistsAtPath(tpath, isDirectory: &isDirectory) {
            if !isDirectory {
                return tpath
            }
        } else {
            return nil
        }
        
        
        // Check for an 'index.htm' file
        
        let t2path = (path as NSString).stringByAppendingPathComponent("index.html")
        
        if filemanager.fileExistsAtPath(t2path, isDirectory: &isDirectory) {
            if !isDirectory {
                return t2path
            }
        } else {
            return nil
        }
        
        
        // Failed, the directory exists, but no default file is present.
        // Access is denied
        
        return nil
    }
    
    
    // A simple implementation that can serve plain file html pages.
    // - Returns: The contents of the file at the path given by the ap_WebsiteDirectory and the requested URL
    
    private func createResponsePayloadForResourceAtPath(path: String) -> NSData? {
        
        if filemanager.isReadableFileAtPath(path) {
            if let data = filemanager.contentsAtPath(path) {
                log.atLevelDebug(id: logId, source: SOURCE + ".createHttpResponse", message: "Returning file: " + path)
                return data
            } else {
                log.atLevelError(id: logId, source: #file.source(#function, #line), message: "Failed to read file: \(path)")
                return nil
            }
        } else {
            log.atLevelError(id: logId, source: #file.source(#function, #line), message: "No read access rights for file at: \(path)")
            return nil
        }
    }
}