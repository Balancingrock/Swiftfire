// =====================================================================================================================
//
//  File:       Domain.HttpWorker.swift
//  Project:    Swiftfire
//
//  Version:    0.9.10
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
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
// v0.9.10 - Added domain statistics
// v0.9.7  - Added Access logging
// v0.9.6  - Header update
// v0.9.5  - Added MIME support
// v0.9.3  - Moved renamed telemetry items
// v0.9.2  - Added httpWorker and associated functions
//         - Removed resourcePathFor
//         - Renamed from Domain.HttpSupport to Domain.HttpWorker
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation


extension Domain {
    

    /**
     Handles client requests for this domain.
     
     - Parameter header: The HTTP Header from the client.
     - Parameter body: The HTTP body as received from the client (may have length zero).
     - Parameter connection: The active connection for this request.
     
     - Returns: The buffer with the response, ready for transmission back to the client.
     */
    
    func httpWorker(header: HttpHeader, body: UInt8Buffer, connection: HttpConnection) -> UInt8Buffer {
        
        
        // =============================================================================================================
        // Access logging
        // =============================================================================================================
        
        if accessLogEnabled {
            let url = header.url ?? "unknown"
            let version = header.httpVersion?.rawValue ?? "unknown"
            let operation = header.operation?.rawValue ?? "unknown"
            accessLog?.record(NSDate(), ipAddress: connection.clientIp, url: url, operation: operation, version: version)
        }
        
        
        // =============================================================================================================
        // Update the domain statistics
        // =============================================================================================================
        
        self.statistics?.record(header, connection: connection)
        
        
        // =============================================================================================================
        // Telemetry update
        // =============================================================================================================

        
        telemetry.nofRequests.increment()
        
        
        // =============================================================================================================
        // Call the preprocessor if necessary
        // =============================================================================================================
        
        if enableHttpPreprocessor {
            // If the preprocessor creates a response, then return it as the response for this domain
            if let response = httpWorkerPreprocessor(header: header, body: body, connection: connection) {
                return response
            }
        }
        
        
        // =============================================================================================================
        // The header must be HTTP version 1.1
        // =============================================================================================================
        
        guard let httpVersion = header.httpVersion where httpVersion == HttpVersion.HTTP_1_1 else {
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: "HTTP Version not present or not 1.1")
            telemetry.nof505.increment()
            return connection.httpErrorResponseWithCode(.CODE_505_HTTP_Version_Not_Supported)
        }
        
        
        // =============================================================================================================
        // It must be either a GET or POST operation
        // =============================================================================================================
        
        guard let operation = header.operation else {
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: "Could not extract operation")
            telemetry.nof400.increment()
            return connection.httpErrorResponseWithCode(.CODE_400_Bad_Request)
        }
        
        guard (operation == HttpOperation.GET || operation == HttpOperation.POST) else {
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: "Operation not a GET or POST")
            telemetry.nof501.increment()
            return connection.httpErrorResponseWithCode(.CODE_501_Not_Implemented)
        }
        
        
        // =============================================================================================================
        // Determine the resource path
        // =============================================================================================================
        
        guard let partialPath = header.url else {
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: "No URL found")
            telemetry.nof400.increment()
            return connection.httpErrorResponseWithCode(.CODE_400_Bad_Request)
        }
        let path = (root as NSString).stringByAppendingPathComponent(partialPath)
        
        
        // =============================================================================================================
        // Check if the resource exists in the file system
        // =============================================================================================================
        
        if !connection.filemanager.fileExistsAtPath(path) {
            telemetry.nof404.increment()
            if four04LogEnabled { four04Log?.record(path) }
            return connection.httpErrorResponseWithCode(.CODE_404_Not_Found)
        }
        
        
        // =============================================================================================================
        // Directory access is not allowed, but the index.html or index.htm will be returned if a directory is accessed
        // and it contains such a file
        // =============================================================================================================
        
        guard let resourcePath = filterForDirectoryAccess(path, connection: connection) else {
            telemetry.nof403.increment()
            return connection.httpErrorResponseWithCode(HttpResponseCode.CODE_403_Forbidden, andMessage: "<p>Directory access not allowed</p>")
        }
        
        
        // =============================================================================================================
        // Fetch the requested resource and return it
        // =============================================================================================================
        
        let responsePayload = createResponsePayloadForResourceAtPath(resourcePath, connection: connection)
        
        if responsePayload == nil {
            log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: "Failure while creating HTTP Response")
            return connection.httpErrorResponseWithCode(.CODE_500_Internal_Server_Error, andMessage: "<p>A Server side error occured, the error has been logged.</p>")
        }
        
        
        // =============================================================================================================
        // Create the http response
        // =============================================================================================================
        
        let mimeType = mimeTypeForPath(resourcePath) ?? MIME_TYPE_DEFAULT
        let response = connection.httpResponseWithCode(.CODE_200_OK, mimeType: mimeType, andBody: responsePayload!)
        telemetry.nof200.increment()
        
        
        // =============================================================================================================
        // Check if the postprocessor must be run
        // =============================================================================================================

        if enableHttpPostprocessor {
            // If the postprocessor returns a response, use that instead of the already prepared response
            if let postProResponse = httpWorkerPostprocessor(header: header, body: body, response: response, connection: connection) {
                return postProResponse
            }
        }
        
        
        return response
    }
    
    
    /// - Returns: The resource path ammended by index.html or index.htm
    
    private func filterForDirectoryAccess(path: String, connection: HttpConnection) -> String? {
        
        
        // GP
        
        var isDirectory: ObjCBool = false
        
        
        // Test the unmodified path
        
        if connection.filemanager.fileExistsAtPath(path, isDirectory: &isDirectory) {
            if !isDirectory {
                return path
            }
        } else {
            return nil
        }
        
        
        // The path exists, but it is a directory.
        
        
        // Check for an 'index.html' file
        
        let tpath = (path as NSString).stringByAppendingPathComponent("index.html")
        
        if connection.filemanager.fileExistsAtPath(tpath, isDirectory: &isDirectory) {
            if !isDirectory {
                return tpath
            }
        } else {
            return nil
        }
        
        
        // Check for an 'index.htm' file
        
        let t2path = (path as NSString).stringByAppendingPathComponent("index.html")
        
        if connection.filemanager.fileExistsAtPath(t2path, isDirectory: &isDirectory) {
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
    
    private func createResponsePayloadForResourceAtPath(path: String, connection: HttpConnection) -> NSData? {
        
        if connection.filemanager.isReadableFileAtPath(path) {
            if let data = connection.filemanager.contentsAtPath(path) {
                log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: "Returning file: " + path)
                return data
            } else {
                log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: "Failed to read file: \(path)")
                return nil
            }
        } else {
            log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: "No read access rights for file at: \(path)")
            return nil
        }
    }

}
