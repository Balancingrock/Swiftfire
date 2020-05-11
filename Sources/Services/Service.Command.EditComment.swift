// =====================================================================================================================
//
//  File:       Service.Command.EditComment.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019-2020 Marinus van der Lugt, All rights reserved.
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
import Http


/// The  name to be used in HTML to invoke the editing of a comment.

let COMMAND_EDIT_COMMENT = "edit-comment"


/// Execute the Edit Comment command.
///
/// - parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain for which to review the comments.
///     - info: The service info dictionary.
///
/// - Returns: If a specific page should be returned, the path to that page is returned. Otherwise nil.

func executeEditComment(_ request: Request, _ domain: Domain, _ info: Services.Info) -> String? {
    
    guard let text = request.info[COMMENT_TEXT_KEY] else {
        Log.atError?.log("Missing \(COMMENT_TEXT_KEY) in request.info")
        return nil
    }
    
    guard text.count > 1 else {
        Log.atDebug?.log("Character count too low, is: \(text.count), should be >1")
        return nil
    }

    
    // Add formatting
    
    let markedUp = Comment.htmlify(text)

    
    // Write the preview string to request info
    
    request.info["preview"] = markedUp
    
    
    return "/pages/comment-edit.sf.html"
}
