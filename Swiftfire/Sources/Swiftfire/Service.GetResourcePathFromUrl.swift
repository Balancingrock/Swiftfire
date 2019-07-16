// =====================================================================================================================
//
//  File:       Service.GetResourcePathFromUrl.swift
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
// Builds the resource path from the requested URL, the domain root directory and the presence of file candidates.
//
// If the root/url points at a directory, that directory will be tested for the presence of an index.htm or index.html
// file. If found, the resource path will be set to that file.
//
// If a response.code is set, this operation exists immediately with '.next'.
//
//
// Input:
// ------
//
// response.code: If set, this service will exit immediately with '.next'.
// header.url: The string representing the URL of the resource to be found.
// domain.root: The string for the root directory of the domain.
// connection.filemanager: used.
//
//
// On success:
// -----------
//
// info[.absoluteResourcePathKey] = A String value with the full path to the requested resource
// info[.relativeResourcePathKey] = A String value
//
// return: .next
//
//
// On error:
// ---------
//
// response.code:
//
// - code 400 (Bad Request) if the HTTP request header did not contain a url.
//   & domain.telemetry.nof400: incremented
//   & statistics: Updated with a ClientRecord.
//
// - code 404 (Not Found) if no resource (file) was present at the resource path.
//   & domain.telemetry.nof404: incremented
//   & statistics: Updated with a ClientRecord.
//
// - code 403 (Forbidden) if the file at the resource path is not readable.
//   & domain.telemetry.nof403: incremented
//   & statistics: Updated with a ClientRecord.
//
// return: .next
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets
import Http


/// Takes the URL from the request header and transforms it into a path that points at an existing resource
///
/// - Note: For a full description of all effects of this operation see the file: Service.GetResourcePathFromUrl.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: Always .next.

func service_getResourcePathFromUrl(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {
    
    
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
        
        domain.recordIn404Log(path)
        

        // Response
        
        response.code = Response.Code._404_NotFound
    }

    
    func handle403_ForbiddenError(path: String) {
        
        
        // Telemetry update
        
        domain.telemetry.nof403.increment()
        
        
        // Response
        
        response.code = Response.Code._403_Forbidden
    }

    
    // Extracts the name value pairs if they are present and removes all characters starting from the first question mark encountered.
    
    func extractAndRemoveNameValuePairs(path: String) -> String {
        
        
        // Only for get operations
        
        if request.method != .get { return path }
        
        
        // There must be a questionmark in the path
        
        if !path.contains("?") { return path }
        
        
        // Split the path into two parts, before and after the questionmark
        
        let parts = path.components(separatedBy: "?")
        
        if parts.count != 2 { return path } // Some kind of error or a special case by the website designer?
        
        
        // The second part contains the name/value pairs
        
        let getDict = ReferencedDictionary()
        
        var nameValuePairs = parts[1].components(separatedBy: "&")
        
        while nameValuePairs.count > 0 {
            var nameValue = nameValuePairs.removeFirst().components(separatedBy: "=")
            switch nameValue.count {
            case 0: break // error, don't do anything
            case 1: getDict[nameValue[0]] = ""
            case 2: getDict[nameValue[0]] = nameValue[1]
            default:
                let name = nameValue.removeFirst()
                getDict[name] = nameValue.joined(separator: "=")
            }
        }
        
        
        // Add the get dictionary to the service info
        
        if getDict.count > 0 { info[.getInfoKey] = getDict }
        
        
        // Return the "before questionmark' part of the original path
        
        return parts[0]
    }
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }

    
    // If there is a path already, skip (This allows o.a. serveradmin domain access)
    
    if info[.absoluteResourcePathKey] != nil { return .next }
    if info[.relativeResourcePathKey] != nil { return .next }
        
        
    // =============================================================================================================
    // Determine the resource path
    // =============================================================================================================
    
    guard let originalPartialPath = request.url else {
        handle400_BadRequestError(message: "No URL in request")
        return .next
    }
    
    
    // =============================================================================================================
    // Extract possible name/value pairs from the partial path
    // =============================================================================================================
    
    let partialPath = extractAndRemoveNameValuePairs(path: originalPartialPath)
    
    
    // =============================================================================================================
    // Add the partial path to the root
    // =============================================================================================================
    
    let fullPath = (domain.root as NSString).appendingPathComponent(partialPath)

    
    // =============================================================================================================
    // Check if there is something at the full path, append index.htm or index.html when necessary
    // =============================================================================================================
    
    var isDirectory: ObjCBool = false
    
    if connection.filemanager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
        
        
        // There is something, if it is a directory, check for index.html or index.htm
        
        if isDirectory.boolValue {
            
            
            // Find a root-index file
            
            let acceptedIndexNames = ["index.html", "index.sf.html", "index.htm", "index.sf.htm"]
            
            for name in acceptedIndexNames {
                
                
                // Check for an 'index.html' file
                
                let tpath = (fullPath as NSString).appendingPathComponent(name)
                
                if connection.filemanager.isReadableFile(atPath: tpath) {
                    
                    info[.absoluteResourcePathKey] = tpath as String
                    info[.relativeResourcePathKey] = (partialPath as NSString).appendingPathComponent(name)
                    
                    return .next
                }
            }
            
            
            // Neither file exists, and directory access is not allowed
            
            handle404_NotFoundError(path: partialPath)
            
            return .next
            
            
        } else {
            
            // It is a file
            
            if connection.filemanager.isReadableFile(atPath: fullPath) {
                
                info[.absoluteResourcePathKey] = fullPath
                info[.relativeResourcePathKey] = partialPath
                
                return .next
            
            } else {
            
                handle403_ForbiddenError(path: partialPath)

                return .next
            }
        }
        
    } else {
        
        // If an "<name>.<ext>" file is requested, then check also for a "<name>.sf.<ext>" file

        func addSf(toPath: String) -> String? {
            let pathWithoutExtension = (toPath as NSString).deletingPathExtension
            let extensionPart = (toPath as NSString).pathExtension
            return ((pathWithoutExtension as NSString).appendingPathExtension("sf") as NSString?)?.appendingPathExtension(extensionPart)
        }
        
        if let sfFullPath = addSf(toPath: fullPath) {
        
            if connection.filemanager.fileExists(atPath: sfFullPath, isDirectory: &isDirectory) {
                
                if !isDirectory.boolValue {
                    
                    // It is a file
                    
                    if connection.filemanager.isReadableFile(atPath: sfFullPath) {
                        
                        info[.absoluteResourcePathKey] = sfFullPath
                        
                        let sfPartialPath = addSf(toPath: partialPath) ?? partialPath // Default should never be used

                        info[.relativeResourcePathKey] = sfPartialPath
                        
                        return .next
                        
                        
                    } else {
                        
                        handle403_ForbiddenError(path: partialPath)
                        
                        return .next
                    }
                }
            }
        }
        

        // There is nothing at the resource path
        
        handle404_NotFoundError(path: partialPath)
        
        return .next
    }
}

