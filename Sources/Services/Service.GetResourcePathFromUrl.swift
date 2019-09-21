// =====================================================================================================================
//
//  File:       Service.GetResourcePathFromUrl.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Partly rewritten, retrieval of URL and name/value pairs has moved to library Http
// 1.0.1 - Documentation update
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import SwifterLog
import SwifterSockets
import Http
import Core


/// Determines which resource (file) is requested by a HTTP request. Note that the path itself can be different from the URL itself because of several factors (not listed here).
///
/// _Input_:
///   - request.url: The string representing the URL of the resource to be found.
///   - domain.root: The string for the root directory of the domain.
///   - connection.filemanager: used.
///
/// _Output_:
///   - info[.absoluteResourcePathKey]: A file Path with the full path to the requested resource.
///   - info[.relativeResourcePathKey]: A file Path relative to the root of the domain.
///   - domain.telemetry: Updated in accordance with the processing results
///   - response.code: Only if an error occured.
///
/// _Sequence_:
///   - Can be one of the first services, does not need any predecessors.

func service_getResourcePathFromUrl(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: Services.Info, _ response: Response) -> Services.Result {
    
    
    func handle400_BadRequestError(message: String) {
        
        
        // Telemetry update
        
        domain.telemetry.nof400.increment()
        
        
        // Aliases
        
        let logId = Int(connection.interface?.logId ?? -2)
        
        
        // Log update
        
        Log.atCritical?.log(message, id: logId)
        
        
        // Response
        
        response.code = Response.Code._400_BadRequest
    }
    
    
    func handle404_NotFoundError(path: String) {
        
        
        // Telemetry update
        
        domain.telemetry.nof404.increment()
        
        
        // Conditional recording of all 404 path errors
        
        domain.four04Log.record(message: path)
        

        // Response
        
        response.code = Response.Code._404_NotFound
    }

    
    func handle403_ForbiddenError(path: String) {
        
        
        // Telemetry update
        
        domain.telemetry.nof403.increment()
        
        
        // Response
        
        response.code = Response.Code._403_Forbidden
    }

    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }

    
    // Abort if the partial path and relative path are already set
    
    if info[.relativeResourcePathKey] == nil { return .next }
    if info[.absoluteResourcePathKey] == nil { return .next }
    
    
    // =============================================================================================================
    // Determine the resource path
    // =============================================================================================================
    
    guard let partialPath = request.resourcePath else {
        handle400_BadRequestError(message: "No URL in request")
        return .next
    }
    
    
    // =============================================================================================================
    // Add the partial path to the root
    // =============================================================================================================
    
    let fullPath = (domain.webroot as NSString).appendingPathComponent(partialPath)

    
    // =============================================================================================================
    // Check if there is something at the full path
    // =============================================================================================================
        
    switch FileManager.default.readableResourceFileExists(at: fullPath, for: domain) {
        
    case .cannotBeRead: handle403_ForbiddenError(path: partialPath)

    case .doesNotExist: handle404_NotFoundError(path: partialPath)
        
    case .isDirectoryWithoutIndex: handle403_ForbiddenError(path: partialPath)
        
    case let .exists(path: foundPath):
        
        info[.absoluteResourcePathKey] = foundPath
        info[.relativeResourcePathKey] = foundPath.replacingOccurrences(of: domain.webroot, with: "", range: Range(NSRange(location: 0, length: domain.webroot.count), in: foundPath))
    }
    
    return .next
}

