// =====================================================================================================================
//
//  File:       Service.GetFileAtResourcePath.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2020 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 #7 Removed local filemanager
//       - Removed inout from the service signature
//       - Removed inout from the function.environment signature
// 1.0.1 - Documentation update
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import SwifterLog
import SwifterSockets
import Http
import Core


/// Retrieve the requested file content, process it (if necessary) and puts the result in the response payload. Processing depends on the file type and can invoke PHP or SF file processing.
///
/// _Input_:
///    - info[.absoluteResourcePathKey]: A string with the path of the source file to fetch.
///    - domain.php...: These variables determine if and how the PHP interpreter will be used.
///
/// _Output_:
///    - response.payload: Set with the (processed) content of the file.
///    - response.code: Set to OK on success, or a corresponding code if an error occured.
///    - response.contentType: Set to the mime-type corresponding to the source file extension.
///    - domain.telemetry: Corresponding to the result, some parameters will be updated.
///
/// _Sequence_:
///    - The Service.GetResourcePathFromUrl has to be called first.

func service_getFileAtResourcePath(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: Services.Info, _ response: Response) -> Services.Result {
    
    

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
    
        switch SFDocument.factory(path: resourcePath, data: phpData) {
            
        case .error(let message):
            
            handle500_ServerError(connection: connection, resourcePath: resourcePath, message: message, line: #line)
            return .next
            
            
        case .success(let doc):

            let environment = Functions.Environment(request: request, connection: connection, domain: domain, response: response, serviceInfo: info)
            
            body = doc.getContent(with: environment)
        }
        
        
    } else {
        
        if let phpData = phpData {
            
            body = phpData
            
        } else {
            
            guard let data = FileManager.default.contents(atPath: resourcePath) else {
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

