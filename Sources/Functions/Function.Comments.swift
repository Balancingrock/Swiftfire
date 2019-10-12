// =====================================================================================================================
//
//  File:       Function.Comments.swift
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
import BRBON


/// Returns the HTML code for a comments section.
///
/// __Webpage Use__:
///
/// _Signature_: .commentSection(identifier, options...)
///
/// _Number of arguments_:  >= 1
///
/// _Type of argument_:
///    - __identifier__: A unique identifier for the comments section. Each comments section should have a unique identifier to keep the comments with the article. The '.' in this identifier has a special meaning - it is used as a folder seperation character. Characters that are illegal in a file path should not be used (but are not tested for!). Leading dots will be removed. Example: identifier = "2019.10.08.article-slug" will result in the creation of a directory "domain/comments/2019/10/08/article-slug" that will contain the comment table and cache. (Every account from which a comment is posted will also contain this directory path with the comments itself in it)
///    - __options__: Additional specifiers that are used to create the comments section.
///             - anon: When present, anonymous comments are accepted, otherwise only logged in users are allowed to comment.
///
/// _Other input used_:
///    - The current account
///
/// _Return_: The HTML code. In case of an error the ***error*** string is returned.

public func function_comments(_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
    
    
    // The function arguments should be an array of string
    
    guard case .arrayOfString(let arr) = args else {
        Log.atError?.log("Wrong type of arguments")
        return "***error***".data(using: .utf8)
    }
    
    
    // At least the identifier should be present
    
    guard arr.count >= 1 else {
        Log.atError?.log("Missing identifier in function argument")
        return "***error***".data(using: .utf8)
    }
    
    
    // There must be a session
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        Log.atError?.log("No session found")
        return "***error***".data(using: .utf8)
    }
    
    
    // First attempt at retrieving the account
    
    let account = session.info[.accountKey] as? Account
    
    
    var data: Data = "<div class=\"sfcomments\">".data(using: .utf8)!
    
    data.append(environment.domain.comments.commentBlocks(for: arr[0].lowercased(), environment: environment))
    
    data.append(environment.domain.comments.commentInputField(account, environment))
    
    data.append("</div>".data(using: .utf8)!)

    return data
}

