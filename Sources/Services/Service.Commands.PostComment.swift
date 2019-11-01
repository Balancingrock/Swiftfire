// =====================================================================================================================
//
//  File:       Service.Commands.PostComment.swift
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
import Http


// The command

internal let COMMAND_POST_COMMENT = "post-comment"


// Defined in the HTML of the originating page and used here

fileprivate let COMMENT_DISPLAY_NAME_KEY = "display-name"


// Executes the post comment command

func executePostComment(_ request: Request, _ domain: Domain, _ info: Services.Info) -> String? {
        
    guard let text = request.info[COMMENT_TEXT_KEY] else {
        Log.atError?.log("Missing \(COMMENT_TEXT_KEY) in request.info")
        return nil
    }
    
    guard text.count > 1 else {
        Log.atDebug?.log("Character count too low, is: \(text.count), should be >1")
        return nil
    }
    
    guard let identifier = request.info[COMMENT_SECTION_IDENTIFIER_KEY] else {
        Log.atError?.log("Missing \(COMMENT_SECTION_IDENTIFIER_KEY) in request.info")
        return nil
    }
    
    let displayName = request.info[COMMENT_DISPLAY_NAME_KEY] ?? "Anon"
    
    let account = (info[.sessionKey] as? Session)?.info[.accountKey] as? Account
    
    
    /// The account and domain are known, create the comment
    
    domain.comments.newComment(text: text, identifier: identifier, displayName: displayName, account: account)
    
    
    return nil
}
