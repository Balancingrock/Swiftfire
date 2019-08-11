// =====================================================================================================================
//
//  File:       Function.SF.DomainButton.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Creates a button that will post the key/value combinations when clicked. One of the keys is "DomainName" and it will
// be set to the value of the domain name of the domain currently viewed.
//
//
// Signature:
// ----------
//
// .domainButton(target, title)
//
// Note: key/value pairs may be added at the end. i.e. .domainButton(target, title, key1, value1, key2, value2, etc...)
//
// Parameters:
// -----------
//
// target: The target url for the form containing the button.
// title: The button title.
// key: The key of the key/value pair that will be POST-ed.
// value: The value of the key/value pair that will be POST-ed
//
//
// Other Input:
// ------------
//
// CSS:
//    - class of form: posting-button-form
//    - class of input: posting-button-button
//
//
// Returns:
// --------
//
// On success: The HTML code (a form) that constitutes the button.
// On error: ***Error***
//
//
// Other Output:
// -------------
//
// None.
//
// =====================================================================================================================

import Foundation

import Core
import Functions


/// Creates a button that will post the key/value combination when clicked.

public func function_sf_domainButton(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
    // Check for minimum the 2 arguments and an even number of arguments
    
    guard case .array(let arr) = args, arr.count >= 2, arr.count.isEven else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Check that a valid domain name was specified
    
    guard let postInfo = environment.serviceInfo[.postInfoKey] as? PostInfo,
        let name = postInfo["DomainName"] else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Create dictionary
    
    var dict: Dictionary<String, String> = ["DomainName": name]
    var argIndex = 2
    while argIndex < (arr.count - 1) {
        dict[arr[argIndex]] = arr[argIndex + 1]
        argIndex += 1
    }
    
    
    // Create html code
    
    return postingButton(target: arr[0], title: arr[1], keyValuePairs: dict).data(using: String.Encoding.utf8)
}
