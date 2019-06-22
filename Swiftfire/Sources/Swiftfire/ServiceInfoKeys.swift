// =====================================================================================================================
//
//  File:       ServiceInfoKeys.swift
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

import Foundation


/// Service Info key's

public enum ServiceInfoKey: String {
    
    
    /// [String] set by the service that determines the URL of the resource to be fetched. (DomainService.GetResourcePathFromUrl)
    ///
    /// This path is relative to the root of the file system. It is used to fetch the requested resource.
    
    case absoluteResourcePathKey = "AbsoluteResourcePath"
    
    
    /// [String] set by the service that determines the URL of the resource to be fetched. (DomainService.GetResourcePathFromUrl)
    ///
    /// This path is relative to the root of the domain. It is used for statistics purposes.
    
    case relativeResourcePathKey = "RelativeResourcePath"
    
    
    /// [Int64] set by HttpConnection.Worker before first domain service call.
    ///
    /// It is the time stamp at the start of the HTTP request processing. It is used for statistics purposes.
    
    case responseStartedKey = "ResponseStarted"
    
    
    /// [Session] set by the service that determines the session for this request.
    
    case sessionKey = "SessionId"
    
    
    /// [Dictionary<String, String>] The name/value pairs for a GET request that returns form data.
    ///
    /// Set by the service: GetResourcePathFromUrl
    
    case getInfoKey = "GetInfo"
    
    
    /// [Dictionary<String, String>] The name/value pairs for a POST request that returns form data x-www-form-urlencoded.
    ///
    /// Set by the service: DecodePostFormUrlEncoded
    
    case postInfoKey = "PostInfo"
}

