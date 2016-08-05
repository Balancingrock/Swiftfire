// =====================================================================================================================
//
//  File:       Domain.HttpWorker.swift
//  Project:    Swiftfire
//
//  Version:    0.9.13
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.11 - Added statistics, partial rewrite of some code parts.
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
    
    func httpWorker(header: HttpHeader, body: Data, connection: HttpConnection, mutation: Mutation) -> Data {
        
        
        // =============================================================================================================
        // Access logging
        // =============================================================================================================
        
        if accessLogEnabled {
            let url = header.url ?? "unknown"
            let version = header.httpVersion?.rawValue ?? "unknown"
            let operation = header.operation?.rawValue ?? "unknown"
            accessLog?.record(time: Date(), ipAddress: connection.clientIp, url: url, operation: operation, version: version)
        }
        
        
        // =============================================================================================================
        // Telemetry update
        // =============================================================================================================

        telemetry.nofRequests.increment()
        
        
        // =============================================================================================================
        // Call the preprocessor if necessary
        // =============================================================================================================
        
        if enableHttpPreprocessor {
            // If the preprocessor creates a response, then return it as the response for this domain
            if let response = httpWorkerPreprocessor(header: header, body: body, connection: connection, mutation: mutation) {
                return response
            }
        }
        
        
        // =============================================================================================================
        // The header must be HTTP version 1.1
        // =============================================================================================================
        
        guard let httpVersion = header.httpVersion else {
            
            // Telemetry update
            telemetry.nof505.increment()
            
            // Log update
            let message = "HTTP Version not present"
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: message)
            
            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code505_HttpVersionNotSupported.rawValue
            mutation.responseDetails = message
            
            // Response
            return connection.httpErrorResponse(withCode: .code505_HttpVersionNotSupported)
        }
            
        guard httpVersion == HttpVersion.http1_1 else {
            
            // Telemetry update
            telemetry.nof505.increment()

            // Log update
            let message = "HTTP Version '\(httpVersion)' not supported"
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: message)
            
            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code505_HttpVersionNotSupported.rawValue
            mutation.responseDetails = message

            // Response
            return connection.httpErrorResponse(withCode: .code505_HttpVersionNotSupported)
        }
        
        
        // =============================================================================================================
        // It must be either a GET or POST operation
        // =============================================================================================================
        
        guard let operation = header.operation else {
            
            // Telemetry update
            telemetry.nof400.increment()

            // Log update
            let message = "Could not extract operation"
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: message)
            
            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
            mutation.responseDetails = message
            
            // Response
            return connection.httpErrorResponse(withCode: .code400_BadRequest)
        }
        
        guard (operation == HttpOperation.get || operation == HttpOperation.post) else {

            // Telemetry update
            telemetry.nof501.increment()
            
            // Log update
            let message = "Operation '\(operation.rawValue)' not supported)"
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: message)

            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code501_NotImplemented.rawValue
            mutation.responseDetails = message
            
            // Response
            return connection.httpErrorResponse(withCode: .code501_NotImplemented)
        }
        
        
        // =============================================================================================================
        // Determine the resource path
        // =============================================================================================================
        
        guard let partialPath = header.url else {

            // Telemetry update
            telemetry.nof400.increment()

            // Log update
            let message = "No URL found in header"
            log.atLevelDebug(id: connection.logId, source: #file.source(#function, #line), message: message)
            
            // Mutation update
            mutation.httpResponseCode = HttpResponseCode.code400_BadRequest.rawValue
            mutation.responseDetails = message
            
            // Response
            return connection.httpErrorResponse(withCode: .code400_BadRequest)
        }
        
        // Mutation update
        mutation.url = partialPath
        
        
        // =============================================================================================================
        // Check if the resource is available
        // =============================================================================================================
        
        let (newPartialPath, errorReason) = resourceIsAvailable(forRequestUrl: partialPath, connection: connection)
        
        if newPartialPath == nil {
        
            assert(errorReason != nil, "")
            
            if errorReason == .NotAvailable {
                
                // Telemetry update
                telemetry.nof404.increment()
                
                // Conditional recording of all 404 path errors
                if four04LogEnabled { four04Log?.record(message: partialPath) }
                
                // Mutation update
                mutation.httpResponseCode = HttpResponseCode.code404_NotFound.rawValue
                mutation.responseDetails = "Resource for url '\(partialPath)' not found"
                
                // Response
                return connection.httpErrorResponse(withCode: .code404_NotFound)
                
            } else if errorReason == .AccessNotAllowed {
                
                // Telemetry update
                telemetry.nof403.increment()
                
                // Mutation update
                let message = "Access not allowed"
                mutation.httpResponseCode = HttpResponseCode.code403_Forbidden.rawValue
                mutation.responseDetails = message
                
                // Response
                return connection.httpErrorResponse(withCode: HttpResponseCode.code403_Forbidden, andMessage: "<p>\(message)</p>")
            
            } else {
                assert(false, "error reason should not be .Available")
            }
        }
        
        
        // =============================================================================================================
        // Fetch the requested resource and return it
        // =============================================================================================================
        
        let responsePayload = createResponse(rootRelativePath: newPartialPath!, connection: connection, mutation: mutation)
        
        if responsePayload == nil {
            
            // Telemetry update
            telemetry.nof500.increment()
            
            // Log update
            let message = "Failure while creating HTTP Response"
            log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: message)
            
            // Mutation update
            mutation.httpResponseCode ??= HttpResponseCode.code500_InternalServerError.rawValue
            mutation.responseDetails ??= message
            
            // Response
            return connection.httpErrorResponse(withCode: .code500_InternalServerError, andMessage: "<p>A Server side error occured, the error has been logged.</p>")
        }
        
        
        // =============================================================================================================
        // Create the http response
        // =============================================================================================================
        
        let responseMimeType = mimeType(forPath: newPartialPath!) ?? mimeTypeDefault
        let response = connection.httpResponse(withCode: .code200_OK, mimeType: responseMimeType, andBody: responsePayload!)
        
        telemetry.nof200.increment()
        
        // Mutation update
        mutation.httpResponseCode = HttpResponseCode.code200_OK.rawValue

        
        // =============================================================================================================
        // Check if the postprocessor must be run
        // =============================================================================================================

        if enableHttpPostprocessor {
            
            // If the postprocessor returns a response, use that instead of the already prepared response
            if let postProResponse = httpWorkerPostprocessor(header: header, body: body, response: response, connection: connection, mutation: mutation) {
                
                mutation.responseDetails ??= "Response provided by postprocessor"
                
                return postProResponse
            }
        }
        
        
        return response
    }
    
    
    /**
     This method is destined to be overriden by a child implementation of Domain.
     
     Returns the status of the resource at the given path. This should be one of the following: Available, NotAvailable or AccessNotAllowed. The standard implementation will test if a readable file is available at the given path (after appending the path to the root). If the path indicates a directory, it will check for a readable index.html or index.htm file in that directory.
     
     - Note: The return value of this operation determines if the client receives a 404 (Not Available), 403 (Not Allowed) or 200 (OK).
     
     - Returns: The path at which the resource was found, note that this may be changed because of the automatic mapping of index.html and index.htm. If the path is nil then rge error reason will detail which errorcode must be returned to the client.
     */

    private func resourceIsAvailable(forRequestUrl path: String, connection: HttpConnection) -> (atPath: String?, errorReason: ResourceAvailability?) {
        

        // Build the full path
        
        let fullPath = (root as NSString).appendingPathComponent(path)

        
        // Check for existence
        
        var isDirectory: ObjCBool = false

        if connection.filemanager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
            

            // There is something, if it is a directory, check for index.html or index.htm
            
            if isDirectory {
                
                
                // Check for an 'index.html' file
                
                let tpath = (fullPath as NSString).appendingPathComponent("index.html")
                
                if connection.filemanager.isReadableFile(atPath: tpath) { return ((path as NSString).appending("index.html"), nil) }
                
                
                // Check for an 'index.htm' file
                
                let t2path = (fullPath as NSString).appendingPathComponent("index.htm")
                
                if connection.filemanager.isReadableFile(atPath: t2path) { return ((path as NSString).appending("index.htm"), nil) }
                
                
                // Neither file exists, and directory access is not allowed
                
                return (nil, .AccessNotAllowed)
                
                
            } else {
                
                // It is a file
                
                if connection.filemanager.isReadableFile(atPath: fullPath) { return (path, nil) }
                
                return (nil, .AccessNotAllowed)
            }
        
        } else {
        
            // There is nothing at the resource path
            
            return (nil, .NotAvailable)
        }
    }
    
    
    /**
     This method is destined to be overriden by a child implementation of Domain.

     This standard implementation returns the file pointed at by the resource.
     
     - Note: It is advised to update the statistics record if the data cannot be provided. If that is not done, a default message will be put in.
     
     - Returns: The contents of the file given by the root directory appended by the given path.
     */
    
    private func createResponse(rootRelativePath path: String, connection: HttpConnection, mutation: Mutation) -> Data? {
        
        
        // Build the full path
        
        let fullPath = (root as NSString).appendingPathComponent(path)
        
        
        // Test the full path
        
        if connection.filemanager.isReadableFile(atPath: fullPath) {
            if let result = connection.filemanager.contents(atPath: fullPath) { return result }
            let message = "Reading contents of file failed (but file is reported readable) resource: \(fullPath)"
            mutation.responseDetails = message
            log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: message)
            return nil
        }
        
        
        // Either the file is not readable or it is a directory
        
        var isDirectory: ObjCBool = false
        
        if connection.filemanager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
            
            
            // There is something, if it is a directory, check for index.html or index.htm
            
            if isDirectory {
                
                
                // Neither file exists, and directory access is not allowed
                
                let message = "A dictionary is not a resource: \(fullPath)"
                mutation.responseDetails = message
                log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: message)
                return nil
                
            } else {
                
                // It is not a directory, but the file exists, thus the file is not accessable
                
                let message = "The file: \(fullPath) is not readable"
                mutation.responseDetails = message
                log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: message)
                return nil
            }
            
        } else {
            
            // There is nothing at the resource path
            
            let message = "No file exists at \(fullPath)"
            mutation.responseDetails = message
            log.atLevelError(id: connection.logId, source: #file.source(#function, #line), message: message)
            return nil
        }
    }
}
