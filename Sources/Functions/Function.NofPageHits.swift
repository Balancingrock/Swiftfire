// =====================================================================================================================
//
//  File:       Function.NofPageHits.swift
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
// 1.3.0 - Removed inout from the function.environment signature
// 1.0.1 - Documentation update
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import SwifterLog
import Core


/// Returns the number of times this functions was called with the same argument.
///
/// __Webpage Use__:
///
/// _Signature_: .nofPageHits() _or_ .nofPageHits(String)
///
/// _Number of arguments_: 0 or 1
///
/// _Type of argument_: String
///
/// _Return_: The number of times this function was called with the same string. Returns `*error*` if there are too many arguments.
///
/// Note: If there is no argument, the function will use the serviceInfo dictionary value for `relativeResourcePathKey`.
///
/// After a server start (or reset) the value will start at 0.

public func function_nofPageHits(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    var count: String = "*error*"
    
    var path: String?
    
    if case .arrayOfString(let arr) = args {
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
    
    Log.atDebug?.log("HitCount for \(path ?? "Unknown") = \(count)", from: Source(id: Int(environment.connection.logId)))

    return count.data(using: .utf8)
}

