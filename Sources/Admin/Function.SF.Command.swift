// =====================================================================================================================
//
//  File:       Function.SF.Command.swift
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
// Builds a form with a button for the given command or a form with a input field and associated submit button.
//
//
// Signature:
// ----------
//
// Option 1: (Button only)
//
// .command("form-action")
//
//
// Option 2: (Button only)
//
// .command("form-action", "button-title")
//
//
// Option 3: (Input field + button)
//
// .command("form-action", "text-input-name", "button-title")
//
//
// Parameters:
// -----------
//
// 1 parameter:
//   - form-action: the name that is used as the form name and the button name.
//
// 2 parameters:
//   - form-action: is the value for the from action.
//   - button-title: is the value (i.e. title) of the button.
//
// 3 parameters: (not used)
//   - form-action: the name that is used as the form name.
//   - text-input-name, the name to be used as the input name.
//     If the name is a parameter name, then the current value of the parameter will be displayed in the input field.
//   - button-title, the title used for the button.
//
//
// Other Input:
// ------------
//
// session = environment.serviceInfo[.sessionKey] // Must be a non-expired session.
// session[.accountKey] must contain an admin account
//
//
// Returns:
// --------
//
// HTML code with form & button
//
//
// Other Output:
// -------------
//
// None.
//
//
// =====================================================================================================================

import Foundation

import Html
import Core


/// Builds a form with a button for the given command.
///
/// - Returns: The value of the requested parameter or "No access rights".

func function_sf_command(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
    guard case Function.Arguments.array(let array) = args else {
        return "Unknown command".data(using: String.Encoding.utf8)
    }
    
    var form: String
    
    switch array.count {
        
    case 1: // 1 argument = button only
        
        form = Form(method: .post, action: "/serveradmin/sfcommand/\(array[0])", Input.submit(title: array[0])).html
        
    case 2:
        
        form = Form(method: .post, action: "/serveradmin/sfcommand/\(array[0])", Input.submit(title: array[1])).html
    
/*    case 3:
        
        // 2 arguments = input field + button
        
        let name = array[1]
        var value = ""
        for p in parameters.all {
            if p.name == name {
                value = p.stringValue
            }
        }
        
        form = "<form style=\"display:inline;\" action=\"/serveradmin/sfcommand/\(array[0])\" method=\"post\"><input type=\"text\" name=\"\(array[1])\" value=\"\(value)\"><input type=\"submit\" value=\"\(array[2])\"></form>"
*/
        
    default:
        
        form = "***error***"
    }

    return form.data(using: String.Encoding.utf8)
}
