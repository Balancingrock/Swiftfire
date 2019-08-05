// =====================================================================================================================
//
//  File:       Function.NofPageHits.swift
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
/// Returns the number of hits for a resource.
//
//
// Signature:
// ----------
//
// .nofPageHits(path: String)
//
//
// Parameters:
// -----------
//
// path: An optional string representing the path for which to retrieve the page hits. This string should be a relative
// path from the root of the domain. If no path is present the path at '.relativeResourcePathKey' from the
// 'environment.serviceInfo' will be used.
//
//
// Other Input:
// ------------
//
// None.
//
//
// Returns:
// --------
//
// The number of page hits.
//
//
// Other Output:
// -------------
//
// None.
//
// =====================================================================================================================

import Foundation

import SwifterLog
import Core


/// Returns the number of hits for a relative resource path. The path should be relative to the root directory of the domain.
///
/// If the arguments contains a String, then the string will be used as the relative resource path and the count for that resource will be returned.
///
/// If the argument does not contain any arguments, it will return the count for the currently requested resource.

public func function_nofPageHits(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    var count: String = "*error*"
    
    var path: String?
    
    if case .array(let arr) = args {
        if arr.count > 0 {
            path = arr[0]
        }
    }
    
    if path == nil {
        path = environment.serviceInfo[.relativeResourcePathKey] as? String
    }
    
    if let path = path {
        count = environment.domain.hitCounters.increment(path) 
    }
    
    Log.atDebug?.log("HitCount for \(path ?? "Unknown") = \(count)", from: Source(id: Int(environment.connection.logId), file: #file, function: #function, line: #line))

    return count.data(using: .utf8)
}

