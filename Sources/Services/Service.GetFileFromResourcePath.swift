// =====================================================================================================================
//
//  File:       Service.GetFileAtResourcePath.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Retrieves the file at the path from info[ResourcePathKey] and places it in the response.payload.
//
//
// Input:
// ------
//
// info[.absoluteResourcePathKey]: A string with the full path for the file to be read.
//
//
// On success:
// -----------
//
// response.payload: Set with contents of file at chainInfo[.absoluteResourcePathKey]
// response.contentType: Set to the mime type for the file extension
// response.code: Set to code 200 (OK)
//
// domain.telemetry.nof200: Incremented
//
// return: .next
//
//
// On error:
// ---------
//
// response.code: Set to code 500 (Internal Server Error)
//
// domain.telemetry.nof500: Incremented
//
// statistics: Updated with new ClientRecord
//
// return: .next
//
// Possible error causes:
// - No resource path found in chainInfo
// - Resource path in serviceInfo points to a resource that cannot be retrieved
//
// =====================================================================================================================

import Foundation

import SwifterLog
import SwifterSockets
import Http
import Core


/// Retrieve the file content from the resource path and put it in the response payload.
///
/// - Note: For a full description of all effects of this operation see the file: DomainService.GetFileAtResourcePath.swift
///
/// - Parameters:
///   - header: The header of the HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next.

func service_getFileAtResourcePath(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Services.Info, _ response: inout Response) -> Services.Result {
    
    

    func handle500_ServerError(connection: SFConnection, resourcePath: String?, message: String, line: Int) {
        
        
        // Telemetry update
        
        domain.telemetry.nof500.increment()
        
        
        // Log update
        
        Log.atCritical?.log(message, id: connection.logId)

        
        // Response
        
        response.code = Response.Code._500_InternalServerError
    }
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }

    
    // =================================================================================================================
    // Make sure a resource path string is present in the chainInfo
    // =================================================================================================================
    
    guard let resourcePath = info[.absoluteResourcePathKey] as? String else {
        handle500_ServerError(connection: connection, resourcePath: nil, message: "No resource path present", line: #line)
        return .next
    }

    Log.atDebug?.log("Resource path = \(resourcePath)", id: connection.logId)
    
    
    // =================================================================================================================
    // Fetch the requested resource
    // =================================================================================================================
    
    let body: Data
    
    
    // If the resource is a php file and php is enabled then process the PHP part first
    
    var phpData: Data?
    if (domain.phpPath != nil) && ((resourcePath as NSString).pathExtension.lowercased() == "php") {
        phpData = loadPhpFile(file: URL(fileURLWithPath: resourcePath), domain: domain)
    }
    
    
    // If the file can contain function calls, then process it. Otherwise return the file as read.
    
    if (resourcePath as NSString).lastPathComponent.contains(".sf.") {
    
        switch SFDocument.factory(path: resourcePath, data: phpData, filemanager: connection.filemanager) {
            
        case .error(let message):
            
            handle500_ServerError(connection: connection, resourcePath: resourcePath, message: message, line: #line)
            return .next
            
            
        case .success(let doc):

            var environment = Functions.Environment(request: request, connection: connection, domain: domain, response: &response, serviceInfo: &info)
            
            body = doc.getContent(with: &environment)
        }
        
        
    } else {
        
        if let phpData = phpData {
            
            body = phpData
            
        } else {
            
            guard let data = connection.filemanager.contents(atPath: resourcePath) else {
                handle500_ServerError(connection: connection, resourcePath: resourcePath, message: "Reading contents of file failed (but file is reported readable), resource: \(resourcePath)", line: #line)
                return .next
            }

            body = data
        }
    }
    
    
    // =============================================================================================================
    // Create the http response
    // =============================================================================================================
        
        
    // Telemetry update
        
    domain.telemetry.nof200.increment()

        
    // Response
        
    response.code = Response.Code._200_OK
    response.contentType = mimeType(forPath: resourcePath) ?? mimeTypeDefault
    response.body = body
        
    return .next
}

