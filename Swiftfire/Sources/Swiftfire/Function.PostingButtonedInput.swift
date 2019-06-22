// =====================================================================================================================
//
//  File:       Function.PostingButtonedInput.swift
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
/// Creates an input field with associated button that will post a URL plus key/value combination(s) when clicked.
//
//
// Signature:
// ----------
//
// .postingButtonedInput(target, inputName, inputValue, buttonTitle)
//
// Note: More key/value pairs may be added at the end. i.e.:
// .postingButtonedInput(target, inputName, inputValue, buttonTitle, key1, value1, key2, value2, etc...)
//
//
// Parameters:
// -----------
//
// target: The target page for the link.
// inputName: The name of the input field, this name will be returned in the posted key/value pairs.
// inputValue: The initial value displayed in the input field.
// buttonTitle: The title for the button.
// key: (optional) The key of the key/value pair that will be POST-ed.
// value: (optional) The value of the key/value pair that will be POST-ed
//
//
// Other Input:
// ------------
//
// CSS:
//    - class for form: posting-buttoned-input-form
//    - class for input: posting-buttoned-input-input
//    - class for button: posting-buttoned-input-button
//
//
// Returns:
// --------
//
// On success: The HTML code (a form).
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


/// Creates a string with the HTML code necessary to display an input field with a button to the right of it.
///
/// - Parameters:
///   - target: The target page for the link.
///   - inputName: The name of the input field, this name will be returned in the posted key/value pairs.
///   - inputValue: The initial value displayed in the input field.
///   - buttonTitle: The title for the button.
///   - keyValuePairs: (optional) Additional key/value pair that will be POST-ed.

func postingButtonedInput(target: String, inputName: String, inputValue: String, buttonTitle: String, keyValuePairs: Dictionary<String, String> = [:]) -> String {
    var dict = keyValuePairs
    var buttonName: String?
    var buttonValue: String?
    if !dict.isEmpty {
        let pair = dict.remove(at: dict.startIndex)
        buttonName = pair.key
        buttonValue = pair.value
    }
    return "<form method=\"post\" action=\"\(target)\" class=\"posting-buttoned-input-form\">\(dict.reduce("", { (p, q) in return p.appending("<input type=\"hidden\" name=\"\(q.key)\" value=\"\(q.value)\">") }))<input class=\"posting-buttoned-input-input\"  type=\"text\" name=\"\(inputName)\" value=\"\(inputValue)\"</input><button type=\"submit\" name=\"\(buttonName ?? "")\" value=\"\(buttonValue ?? "")\" class=\"posting-buttoned-input-button\">\(buttonTitle)</button></form>"
}


/// Creates a (text) link that will post the key/value combination when clicked.

func function_postingButtonedInput(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    // Check for minimum the 4 arguments and an even number of arguments
    
    guard case .array(let arr) = args, arr.count >= 4, arr.count.isEven else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Create dictionary
    
    var dict: Dictionary<String, String> = [:]
    var argIndex = 2
    while argIndex < (arr.count - 1) {
        dict[arr[argIndex]] = arr[argIndex + 1]
        argIndex += 1
    }
    
    
    // Create html code
    
    return postingButtonedInput(target: arr[0], inputName: arr[1], inputValue: arr[2], buttonTitle: arr[3], keyValuePairs: dict).data(using: String.Encoding.utf8)
}
