// =====================================================================================================================
//
//  File:       Function.Timestamp.swift
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

import Core


/// Returns the current time in the format "yyyy-MM-dd'T'HH.mm.ss.SSSZ".
///
/// __Webpage Use__:
///
/// _Signature_: .timestamp()
///
/// _Number of arguments_: 0
///
/// _Returns_: The current time.

public func function_timestamp(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    let now = dateFormatter.string(from: Date())
    
    return now.data(using: String.Encoding.utf8)
}
