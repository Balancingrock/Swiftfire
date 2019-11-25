// =====================================================================================================================
//
//  File:       Service.Commands.ApproveComment.swift
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

internal let COMMAND_COMMENT_REVIEW = "comment-review"


// The URL from where this command is posted

fileprivate let ORIGINATING_PAGE_URL = "/pages/comment-review.sf.html"


// Defined in the HTML of the originating page and used here

fileprivate let ACCEPT_BUTTON = "Accept"
fileprivate let REJECT_BUTTON = "Reject"
fileprivate let PREVIEW_BUTTON = "Preview"
fileprivate let UPDATE_AND_ACCEPT_BUTTON = "Update and Accept"


// Execute the Approve Comment command by removing the command from the approval list and updating the article comment table.

func executeCommentReview(_ request: Request, _ domain: Domain, _ info: Services.Info) -> String? {
    
    guard let uuid = request.info[COMMENT_UUID_KEY] else {
        Log.atError?.log("Missing \(COMMENT_UUID_KEY) in request.info")
        return ORIGINATING_PAGE_URL
    }
    
    guard let identifier = request.info[COMMENT_SECTION_IDENTIFIER_KEY] else {
        Log.atError?.log("Missing \(COMMENT_SECTION_IDENTIFIER_KEY) in request.info")
        return ORIGINATING_PAGE_URL
    }
    
    guard let accountIdStr = request.info[ACCOUNT_ID_KEY] else {
        Log.atError?.log("Missing \(ACCOUNT_ID_KEY) in request.info")
        return ORIGINATING_PAGE_URL
    }
    
    guard let accountId = UUID(uuidString: accountIdStr) else {
        Log.atError?.log("Connot create UUID from: \(accountIdStr)")
        return ORIGINATING_PAGE_URL
    }
    
    guard let account = domain.accounts.getAccount(for: accountId) else {
        Log.atError?.log("No account with UUID: \(accountId.uuidString)")
        return ORIGINATING_PAGE_URL
    }

    guard let ot = request.info[COMMENT_ORIGINAL_TIMESTAMP_KEY] else {
        Log.atError?.log("Missing \(COMMENT_ORIGINAL_TIMESTAMP_KEY) in request.info")
        return ORIGINATING_PAGE_URL
    }

    guard let button = request.info[BUTTON_KEY] else {
        Log.atError?.log("Missing \(ACCOUNT_ID_KEY) in request.info")
        return ORIGINATING_PAGE_URL
    }
    
    
    switch button {
    
    case ACCEPT_BUTTON:
        
        // Add the comment to the comment table for the page
        
        domain.comments.approveComment(uuid: uuid)
        
        
    case REJECT_BUTTON:
        
        // Remove a comment from the approval list and the account
        
        domain.comments.rejectComment(uuid: uuid)
        
        
    case PREVIEW_BUTTON:
        
        // Update the text of the comment (but don't accept it now)
        
        guard let text = request.info[COMMENT_TEXT_KEY] else {
            Log.atError?.log("Missing \(COMMENT_TEXT_KEY) in request.info")
            return ORIGINATING_PAGE_URL
        }
        
        domain.comments.updateComment(text: text, identifier: identifier, account: account, originalTimestamp: ot)
        
        
    case UPDATE_AND_ACCEPT_BUTTON:
        
        // First update the comment, then accept it
    
        guard let text = request.info[COMMENT_TEXT_KEY] else {
            Log.atError?.log("Missing \(COMMENT_TEXT_KEY) in request.info")
            return ORIGINATING_PAGE_URL
        }
        
        domain.comments.updateComment(text: text, identifier: identifier, account: account, originalTimestamp: ot)
        domain.comments.approveComment(uuid: uuid)

        
    default:
        Log.atError?.log("Unknown button selector: \(button)")
    }
    
    return nil
}
