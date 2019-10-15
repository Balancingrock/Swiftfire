// =====================================================================================================================
//
//  File:       Function.Show.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Updated comments
//       - Removed inout from the function.environment signature
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Core


/// Returns the value of the parameter.
///
/// See comments for Core.evaluateKeyArgument for possible sources for the 'show' function.
///
/// __Webpage Use__:
///
/// _Signature_: .show(key)
///
/// _Number of arguments_: 1
///
/// _Type of argument_: String
///
/// _Returns_: The value for the key. If the key does not exist, it returns ***error***.

public func function_show(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    guard case .arrayOfString(let arr) = args, arr.count == 1 else { return htmlErrorMessage }

    return (readKey(arr[0], using: info, in: environment))?.data(using: .utf8) ?? htmlErrorMessage
}
