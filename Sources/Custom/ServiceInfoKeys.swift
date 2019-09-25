// =====================================================================================================================
//
//  File:       ServiceInfoKeys.swift
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
// 1.3.0 - Removed getInfo and postInfo keys
// 1.0.1 - Documentation update
//       - Changed the sessionKey identifier to `Session` from `SessionId`
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation


/// Keys for the Service Info dictionary. The service info directory is passed to each service and can be used to communicate from the earlier to the later services.
///
/// Every key defined here should be documented as to the type of information and the purpose of that information.

public enum ServiceInfoKey: String {
    
    // The first definitions are needed by the core Swiftfire framework.
    
    /// This is the path to the resource requested by the URL that was received. The path is absolute, i.e. starts at the root of the file system.
    ///
    /// __Type__: String
    ///
    /// __Set by__: Service.GetResourcePathFromUrl
    ///
    /// __Used by__: Service.GetFileFromResourcePath
    
    case absoluteResourcePathKey = "AbsoluteResourcePath"
    
    
    /// This is the path to the requested resource. The path is relative to the root of the domain. Note that this may be different from the URL that was requested
    ///
    /// __Type__: String
    ///
    /// __Set by__: Service.GetResourcePathFromUrl
    ///
    /// __Used by__: For logging purposes

    case relativeResourcePathKey = "RelativeResourcePath"
    
    
    /// The time stamp at the start of the HTTP request processing.
    ///
    /// __Type__: Int64, interpreted as javaDate, milliseconds from 1 Jan 1970.
    ///
    /// __Set by__: SFConnection.Worker before first domain service call.
    ///
    /// __Used by__: Statistics purposes.
    
    case responseStartedKey = "ResponseStarted"
    
    
    /// The session that belongs to the request that is beiing processed. A session is a series of requestst all from the same user within the session-timeout threshold.
    ///
    /// __Type__: Session
    ///
    /// __Set by__: Service.GetSession
    ///
    /// __Used by__: Multiple, general purpose.
    
    case sessionKey = "Session"
    
    
    // =================================================================
    // Don't make any changes above this line, add new definitions below
    // =================================================================

}

