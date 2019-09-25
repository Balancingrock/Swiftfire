// =====================================================================================================================
//
//  File:       Function.PostingButtonedInput.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Comments updated
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import Core


/// Creates a string with the HTML code necessary to display an input field with a button to the right of it.
///
/// - Parameters:
///   - target: The target page for the link.
///   - inputName: The name of the input field, this name will be returned in the posted key/value pairs.
///   - inputValue: The initial value displayed in the input field.
///   - buttonTitle: The title for the button.
///   - keyValuePairs: (optional) Additional key/value pair that will be POST-ed.

public func postingButtonedInput(target: String, inputName: String, inputValue: String, buttonTitle: String, keyValuePairs: Dictionary<String, String> = [:]) -> String {
    var dict = keyValuePairs
    var buttonName: String?
    var buttonValue: String?
    if !dict.isEmpty {
        let pair = dict.remove(at: dict.startIndex)
        buttonName = pair.key
        buttonValue = pair.value
    }
    return """
        <form method="post" action="\(target)" class="posting-buttoned-input-form">
            \(dict.reduce("", {
                (p, q) in return p.appending("""
                    <input type="hidden" name="\(q.key)" value="\(q.value)">
                """)
            }))
            <input class="posting-buttoned-input-input" type="text" name="\(inputName)" value="\(inputValue)"</input>
            <button type="submit" name="\(buttonName ?? "")" value="\(buttonValue ?? "")" class="posting-buttoned-input-button">\(buttonTitle)</button>
        </form>
        """
}


/// Returns the HTML code for an input field with associated button on the right hand side embedded in a form including a number of key/value pairs among which the inputName/inputValue pair. If the button is clicked a POST HTML request will be made of the type x-www-form-urlencoded that includes the key/value pairs.
///
/// __Webpage Use__:
///
/// _Signature_: .postingButtonedInput(target, inputName, inputValue, buttonTitle, key-N, value-N, ...)
///
/// _Number of arguments_: 4 + (2 x N) where N is an integer >= 0
///
/// _Type of argument_:
///    - __target__: link to be invoked when the input (button) is clicked
///    - __inputName__: The name for the inputName/inputValue pair
///    - __inputValue__: The initial value for the input field
///    - __buttonTitle__: Title of the input (button)
///    - __key-N__: The key N to include in a POST request of type x-www-form-urlencoded
///    - __value-N__: The value for key N to include in a POST request of type x-www-form-urlencoded
///
/// _Other input used_:
///    - the css class of the form is `posting-buttoned-input-form`
///    - the css class of the input is `posting-buttoned-input-input`
///    - the css class of the button is `posting-buttoned-input-button`
///
/// _Return_: The HTML code for the requested button. `***Error***` if less than 4 or an uneven number of arguments is present.

func function_postingButtonedInput(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: inout Functions.Environment) -> Data? {
    
    // Check for minimum the 4 arguments and an even number of arguments
    
    guard case .arrayOfString(let arr) = args, arr.count >= 4, arr.count.isEven else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
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
