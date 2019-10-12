// =====================================================================================================================
//
//  File:       Function.Enable-Disable.swift
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
// 1.3.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Core


/// Enables a named block.
///
/// __Webpage Use__:
///
/// _Signature_: .enable(name, condition, variables...)
///
/// _Number of arguments_:  >= 3
///
/// _Type of argument_:
///    - __name__: The name of the block to enable.
///    - __condition__: The condition which the next veraible(s) have to fulfill to enable the named block
///         - `nil`: There must be one additional variable which must be nil in order to enable the block.
///         - `non-nil`: There must be one additional variable which must be non-nil in order to enable the block.
///         - `empty`: There must be one additional variable which must be empty in order to enable the block.
///         - `non-empty`: There must be one additional variable which must not be empty in order to enable the block.
///     - __variables...__: The variables to be used to evaluate the condition
///
/// _Other input used_:
///    - none
///
/// _Returns_: nil

public func function_enabled(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {

    if evaluate(args, &info, environment) {
        
        guard case .arrayOfString(let arr) = args, arr.count > 0 else {
            Log.atError?.log()
            return nil
        }
        
        let id = arr[0]
        
        environment.sfdocument?.blocks.enable(blockId: id)
    }
    
    return nil
}


public func function_disabled(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {

    if evaluate(args, &info, environment) {
        
        guard case .arrayOfString(let arr) = args, arr.count > 0 else {
            Log.atError?.log()
            return nil
        }
        
        let id = arr[0]
        
        environment.sfdocument?.blocks.disable(blockId: id)
    }
    
    return nil
}


fileprivate func evaluate(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Bool {
    
    guard case .arrayOfString(let arr) = args, arr.count > 2 else {
        Log.atError?.log()
        return false
    }
    
    let condition = arr[1]
    
    switch condition {
    
    case "nil":
        
        guard arr.count == 3 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(arr.count)")
            return false
        }
        
        return evaluateKeyArgument(arr[2], using: info, in: environment) == nil
        
        
    case "non-nil":
        
        guard arr.count == 3 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(arr.count)")
            return false
        }
        
        return evaluateKeyArgument(arr[2], using: info, in: environment) != nil

        
    case "empty":
        
        guard arr.count == 3 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(arr.count)")
            return false
        }
        
        return evaluateKeyArgument(arr[2], using: info, in: environment)?.isEmpty ?? false

        
    case "non-empty":
        
        guard arr.count == 3 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(arr.count)")
            return false
        }
        
        return !(evaluateKeyArgument(arr[2], using: info, in: environment)?.isEmpty ?? false)

        
    default:
        Log.atError?.log("Unknown condition \(condition)")
        return false
    }
}
