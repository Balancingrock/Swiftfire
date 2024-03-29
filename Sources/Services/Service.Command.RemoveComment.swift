// =====================================================================================================================
//
//  File:       Service.Command.RemoveComment.swift
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


/// The  name to be used in HTML to invoke the removal of a comment.

let COMMAND_REMOVE_COMMENT = "remove-comment"


/// Execute the Remove Comment command.
///
/// - parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain for which to review the comments.
///     - info: The service info dictionary.
///
/// - Returns: If a specific page should be returned, the path to that page is returned. Otherwise nil.

func executeRemoveComment(_ request: Request, _ domain: Domain, _ info: Services.Info) -> String? {
        
    guard let originalTimestamp = request.info[COMMENT_ORIGINAL_TIMESTAMP_KEY] else {
        Log.atError?.log("Missing \(COMMENT_ORIGINAL_TIMESTAMP_KEY) in request.info")
        return nil
    }
        
    guard let identifier = request.info[COMMENT_SECTION_IDENTIFIER_KEY] else {
        Log.atError?.log("Missing \(COMMENT_SECTION_IDENTIFIER_KEY) in request.info")
        return nil
    }
    
    guard let accountIdStr = request.info[COMMENT_ACCOUNT_KEY] else {
        Log.atError?.log("Missing \(COMMENT_ACCOUNT_KEY) in request.info")
        return nil
    }
    
    guard let accountId = UUID(uuidString: accountIdStr) else {
        Log.atError?.log("Cannot create UUID from: \(accountIdStr)")
        return nil
    }
    
    guard let account = domain.accounts.getAccount(for: accountId) else {
        Log.atError?.log("Missing account for \(accountId.uuidString)")
        return nil
    }
    
    guard let loginAccount = (info[.sessionKey] as? Session)?.getAccount(inDomain: domain) else {
        Log.atDebug?.log("No user logged in")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Login required"
        return LOGIN_TEMPLATE
    }
        
    guard loginAccount.isModerator || loginAccount.isDomainAdmin || (loginAccount === account) else {
        Log.atWarning?.log("User \(loginAccount.name) does not have the rights to remove this comment \(identifier), \(originalTimestamp)")
        return nil
    }
    
    
    /// The account, domain and timestamp are known, create the comment
    
    domain.comments.removeComment(identifier: identifier, account: account, originalTimestamp: originalTimestamp)
    
    
    return nil
}
