// =====================================================================================================================
//
//  File:       Function.PostingLink.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
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
// Creates a (text) link that will post the key/value combination when clicked. Note the appearance of the link depends
// on the presence of the CSS in the given example.
//
//
// Signature:
// ----------
//
// .postingLink(target, text, key, value)
//
// Note: More key/value pairs may be added at the end. i.e. .postingLink(target, text, key1, value1, ke2, value2, etc...)
//
// Parameters:
// -----------
//
// target: The target page for the link.
// text: The text that is shown to click on.
// key: The key of the key/value pair that will be POST-ed.
// value: The value of the key/value pair that will be POST-ed
//
//
// Other Input:
// ------------
//
// CSS:
//    - class for form: posting-link-form
//    - class for input: posting-link-button
//
//
// SCSS example:
//
// .posting-link-form {
//    display: inline;
// }
// .posting-link-button {
//    background: none;
//    border: none;
//    color: blue;
//    text-decoration: underline;
//    cursor: pointer;
// }
// .posting-link-button:focus {
//    outline: none;
// }
// .posting-link-button:active {
//    color: black;
// }
//
//
// Returns:
// --------
//
// On success: The HTML code (a form) that constitutes the link.
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


/// Creates a string with the HTML code necessary to create a link that contains a POST-ed key/value pair.
///
/// - Parameters:
///   - target: The destination for the link.
///   - text: The text that can be clicked.
///   - key: The key of the key/value pair that will be POST-ed.
///   - value: The value of the key/value pair that will be POST-ed.

public func postingLink(target: String, text: String, keyValuePairs: Dictionary<String, String>) -> String {
    if keyValuePairs.isEmpty { return "***Error***" }
    var dict = keyValuePairs
    let pair = dict.remove(at: dict.startIndex)
    return "<form method=\"post\" action=\"\(target)\" class=\"posting-link-form\">\(dict.reduce("", { (p, q) in return p.appending("<input type=\"hidden\" name=\"\(q.key)\" value=\"\(q.value)\">") }))<button type=\"submit\" name=\"\(pair.key)\" value=\"\(pair.value)\" class=\"posting-link-button\">\(text)</button></form>"
}


extension Int {
    var isEven: Bool { return self % 2 == 0 }
    var isUneven: Bool { return self % 2 == 1 }
    func isMultiple(of i: Int) -> Bool { return self % i == 0 }
}


/// Creates a (text) link that will post the key/value combination when clicked.

public func function_postingLink(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
    // Check for minimum the 4 arguments and an even number of arguments
    
    guard case .array(let arr) = args, arr.count > 4, arr.count.isEven else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Create dictionary
    
    var dict: Dictionary<String, String> = [:]
    var argIndex = 2
    while argIndex < (arr.count - 1) {
        dict[arr[argIndex]] = arr[argIndex + 1]
        argIndex += 1
    }
    
    
    // Create html code
    
    return postingLink(target: arr[0], text: arr[1], keyValuePairs: dict).data(using: String.Encoding.utf8)
}
