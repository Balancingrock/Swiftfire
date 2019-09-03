// =====================================================================================================================
//
//  File:       Function.Assign.swift
//  Project:    Swiftfire
//
//  Version:    1.2.0
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
// 1.2.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Core


/// Returns the value of the parameter
///
/// __Webpage Use__:
///
/// _Signature_: .assign(key, value)
///
/// _Number of arguments_: 2
///
/// _Type of argument_:
///   - value: String, the parameter value to assign to the functionInfo dictionary
///   - key: String, the key for the value in the functionInfo dictionary
///
/// _Returns_: The value in postInfo for the key. If the key does not exist, it returns ***error***.

public func function_assign(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    guard case .arrayOfString(let arr) = args, arr.count == 2 else { return "***error***".data(using: .utf8) }
    
    let value = evaluateKeyArgument(arr[0], using: info, in: environment)
    
    let key = arr[1]
    
    info[key] = value
    
    return Data()
}
