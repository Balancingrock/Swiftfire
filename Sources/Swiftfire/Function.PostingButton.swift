// =====================================================================================================================
//
//  File:       Function.PostingButton.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.7 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
/// Creates a (text) link that will post the key/value combination when clicked.
//
//
// Signature:
// ----------
//
// .postingButton(target, title, key, value)
//
// Note: More key/value pairs may be added at the end. i.e. .postingButton(target, title, key1, value1, ke2, value2, etc...)
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


/// Creates a string with the HTML code necessary to create a button that contains a POST-ed key/value pair.
///
/// - Parameters:
///   - target: The target url for the form containing the button.
///   - title: The button title.
///   - key: The key of the key/value pair that will be POST-ed.
///   - value: The value of the key/value pair that will be POST-ed.

func postingButton(target: String, title: String, keyValuePairs: Dictionary<String, String>) -> String {
    if keyValuePairs.isEmpty { return "***Error***" }
    var dict = keyValuePairs
    let pair = dict.remove(at: dict.startIndex)
    return "<form method=\"post\" action=\"\(target)\" class=\"posting-button-form\">\(dict.reduce("", { (p, q) in return p.appending("<input type=\"hidden\" name=\"\(q.key)\" value=\"\(q.value)\">") }))<button type=\"submit\" name=\"\(pair.key)\" value=\"\(pair.value)\" class=\"posting-button-button\">\(title)</button></form>"
}


/// Creates a button that will post the key/value combination when clicked.

func function_postingButton(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
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
    
    return postingButton(target: arr[0], title: arr[1], keyValuePairs: dict).data(using: String.Encoding.utf8)
}
