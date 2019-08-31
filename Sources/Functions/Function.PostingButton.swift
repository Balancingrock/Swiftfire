// =====================================================================================================================
//
//  File:       Function.PostingButton.swift
//  Project:    Swiftfire
//
//  Version:    1.2.0
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
// 1.2.0 - Allow usage of keyed arguments for value arguments.
// 1.0.0 - Raised to v1.0.0, Removed old change log
//
// =====================================================================================================================

import Foundation

import Core


/// Creates a string with the HTML code necessary to create an input (button) that contains a POST-ed key/value pair.
///
/// - Parameters:
///   - target: The target url for the form containing the button.
///   - title: The button title.
///   - key: The key of the key/value pair that will be POST-ed.
///   - value: The value of the key/value pair that will be POST-ed.


public func postingButton(target: String, title: String, keyValuePairs: Dictionary<String, String>) -> String {
    if keyValuePairs.isEmpty { return "***Error***" }
    var dict = keyValuePairs
    let pair = dict.remove(at: dict.startIndex)
    return "<form method=\"post\" action=\"\(target)\" class=\"posting-button-form\">\(dict.reduce("", { (p, q) in return p.appending("<input type=\"hidden\" name=\"\(q.key)\" value=\"\(q.value)\">") }))<button type=\"submit\" name=\"\(pair.key)\" value=\"\(pair.value)\" class=\"posting-button-button\">\(title)</button></form>"
}


/// Returns the HTML code for an input (button) field embedded in a form including a number of key/value pairs. If the button is clicked a POST HTML request will be made of the type x-www-form-urlencoded that includes the given key/value pairs. Once the POST request is processed by Service.DecodePostFormUrlEncoded the postInfo dictionary will contain the key/value pairs.
///
/// __Webpage Use__:
///
/// _Signature_: .postingButton(target, title, key-N, value-N, ...)
///
/// _Number of arguments_: 4 + (2 x N) where N is an integer >= 0
///
/// _Type of argument_:
///    - __target__: link to be invoked when the input (button) is clicked
///    - __title__: Title of the input (button)
///    - __key-N__: The key N to include in a POST request of type x-www-form-urlencoded.
///    - __value-N__: The value for key N to include in a POST request of type x-www-form-urlencoded. This may be a keyed argument, see Functions.md and/or the operation evaluateKeyArgument.
///
/// _Other input used_:
///    - the css class of the form is `posting-button-form`
///    - the css class of the input is `posting-button-button`
///
/// _Return_: The HTML code for the requested button. `***Error***` if less than 4 or an uneven number of arguments is present.

public func function_postingButton(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    
    // Check for minimum the 4 arguments and an even number of arguments
    
    guard case .arrayOfString(let arr) = args, arr.count >= 4, arr.count.isEven else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Create dictionary
    
    var dict: Dictionary<String, String> = [:]
    var argIndex = 2
    while argIndex < (arr.count - 1) {
        dict[arr[argIndex]] = arr[argIndex + 1]
        argIndex += 1
    }
    
    
    // Parse for key argument values
    
    for (key, value) in dict {
        dict[key] = evaluateKeyArgument(value, using: info, in: environment)
    }
    
    
    // Create html code
    
    return postingButton(target: arr[0], title: arr[1], keyValuePairs: dict).data(using: String.Encoding.utf8)
}
