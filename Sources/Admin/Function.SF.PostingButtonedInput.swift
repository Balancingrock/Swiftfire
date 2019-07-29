// =====================================================================================================================
//
//  File:       Function.SF.PostingButtonedInput.swift
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
// Creates an input field with associated button that will post a URL plus key/value combination(s) when clicked.
// The default value for the field can be extracted from the server parameters or domain parameters.
//
//
// Signature:
// ----------
//
// .sf-postingButtonedInput(target, inputName, inputValue, buttonTitle)
//
// Note: More key/value pairs may be added at the end. i.e.:
// .postingButtonedInput(target, inputName, inputValue, buttonTitle, key1, value1, key2, value2, etc...)
//
//
// Parameters:
// -----------
//
// target: The target page for the link.
// inputName: The name of the input field, this name will be returned in the posted key/value pairs. If this is the name of a server parameter, the value of that server parameter will be used as the default value. Overriding the given default value. If the inputName is not a server parameter name, but a domain parameter name AND a postInfo["DomainName"] is present with the name of a valid domain, then the value of that domain parameter will be used as the default value. Overriding the given default value. Note that when a postInfo["DomainName"] was used, this will also be set as part of the posted info for the form.
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

import Core
import Functions


/// Creates a (text) link that will post the key/value combination when clicked.

func function_sf_postingButtonedInput(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    
    // Check access rights
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        return "Session error".data(using: String.Encoding.utf8)
    }
    
    guard let account = session.info[.accountKey] as? Account else {
        return "Account error".data(using: String.Encoding.utf8)
    }
    
    guard serverAdminDomain.accounts.contains(account.uuid) else {
        return "Illegal access".data(using: String.Encoding.utf8)
    }

    
    // Check for minimum the 4 arguments and an even number of arguments
    
    guard case .array(let arr) = args, arr.count >= 4, (arr.count % 2 == 0) else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Create dictionary
    
    var dict: Dictionary<String, String> = [:]
    for i in 4 ..< arr.count {
        dict[arr[i]] = arr[i+1]
    }
    
    
    // If the inputName is the name of a parameter, use the value from the parameter as the default.
    
    var value: String?
    
    for t in parameters.all {
        
        if t.name.caseInsensitiveCompare(arr[1]) == ComparisonResult.orderedSame {
            value = t.stringValue
            break
        }
    }

    
    // If the value is not set, then check for the presence of a domain name in the post info. If found, then check for a parameter from that domain to be used as the default value.
    
    if value == nil {
        if let postInfo = environment.serviceInfo[.postInfoKey] as? PostInfo {
            if let name = postInfo["DomainName"] {
                if let domain = domains.domain(forName: name) {
                    switch arr[1] {
                    case "name": value = domain.name
                    case "wwwincluded": value = domain.wwwIncluded.description
                    case "root": value = domain.root
                    case "forewardurl": value = domain.forwardUrl
                    case "enabled": value = domain.enabled.description
                    case "accesslogenabled": value = domain.accessLogEnabled.description
                    case "404logenabled": value = domain.four04LogEnabled.description
                    case "phppath": value = (domain.phpPath?.path ?? "").description
                    case "phpoptions": value = domain.phpPath == nil ? "" : (domain.phpOptions ?? "").description
                    case "phpmapindex": value = domain.phpPath == nil ? "" : domain.phpMapIndex.description
                    case "phpmapall": value = domain.phpPath == nil ? "" : domain.phpMapAll.description
                    case "phptimeout": value = domain.phpTimeout.description
                    case "sessionlogenabled": value = domain.sessionLogEnabled.description
                    case "sfresources": value = domain.sfresources
                    case "sessiontimeout": value = domain.sessionTimeout.description
                    default: break
                    }
                    if value != nil {
                        dict["DomainName"] = name
                    }
                }
            }
        }
    }
    
    // Create html code
    
    return postingButtonedInput(target: arr[0], inputName: arr[1], inputValue: (value ?? arr[2]), buttonTitle: arr[3], keyValuePairs: dict).data(using: String.Encoding.utf8)
}