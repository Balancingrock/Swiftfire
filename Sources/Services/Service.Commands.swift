// =====================================================================================================================
//
//  File:       Service.Commands.swift
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

import Http
import SwifterLog
import Core


// Commands, templates, pages and keys
//
// Note that commands and templates are lowercase
// Template paths are case sensitive and must lead with a "/"


/// This key can be used to display a message when something failed and the user has to try again.

let PREVIOUS_ATTEMPT_MESSAGE_KEY = "previous-attempt-message"


/// This key is used to acces the original page URL that lead to a need to login first.

public let ORIGINAL_PAGE_URL_KEY = "original-page-url"


// When somebody tried to do something which is not allowed, yet is also not an error

///The path to the page that displayes an error when the user attempted something that he has no rights to (yet).

let ATTEMPT_NOT_ALLOWED_TEMPLATE = "/pages/account/not-allowed.sf.html"


// General purpose keys used in the POST requests

/// POST-key for the button id

let BUTTON_KEY = "button"


/// POST-Key for the next url to be visited

let NEXT_URL_KEY = "next-url"


/// POST-Key for the account id (name)

let ACCOUNT_ID_KEY = "account-id"


/// POST-Key for the identify of a comment author id (name)

let COMMENT_ACCOUNT_KEY = "comment-account-id"


/// POST-Key for the UUID of a comment

let COMMENT_UUID_KEY = "comment-uuid"


/// POST-Key for the comment section identifier

let COMMENT_SECTION_IDENTIFIER_KEY = "comment-section-identifier"


/// POST-Key for the text of a comment

let COMMENT_TEXT_KEY = "comment-text"


/// POST-Key for the original timestamp of a comment

let COMMENT_ORIGINAL_TIMESTAMP_KEY = "comment-original-timestamp"


/// Executes commands given in the URL. Only active if the URL started with the command keyword followed by a command identifier.
///
/// _Input_:
///    - request.cookies: Will be checked for an existing session cookie.
///    - domain.sessions: Will be checked for an existing session, or a new session.
///    - domain.sessionTimeout: If the timeout < 1, then no session will be created.
///
/// _Output_:
///    - response
///
/// _Sequence_:
///   - Should be called after WaitUntilBodyComplete.

func service_commands(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: Services.Info, _ response: Response) -> Services.Result {
    
    
    // Exit if there is a code already
    
    if response.code != nil { return .next }
    
    
    // Exit if the first path part is not a 'command'
    
    guard
        request.resourcePathParts.count > 1,
        request.resourcePathParts[0].lowercased() == "command"
    else {
        Log.atInfo?.log("The request does not contain a command")
        return .next
    }

    
    // The command that must be executed
    //
    // Note that the parameters for the command must be present in the GET info or POST info of the request.
    
    let command = request.resourcePathParts[1].lowercased()

    
    // The redirected path
    
    var relativePath: String?
    
    
    // Get the command and execute it
    
    switch command {
        
    case COMMAND_LOGIN: relativePath = executeLogin(request, domain, info)
    case COMMAND_LOGOUT: relativePath = executeLogout(request, info)
    case COMMAND_EMAIL_VERIFICATION: relativePath = executeEmailVerification(request, domain, response, info)
    case COMMAND_REGISTER: relativePath = executeRegister(request, connection, domain, response, info)
    case COMMAND_FORGOT_PASSWORD: relativePath = executeForgotPassword(request, connection, domain, response, info)
    case COMMAND_REQUEST_NEW_PASSWORD: relativePath = executeRequestNewPassword(request, domain)
    case COMMAND_SET_NEW_PASSWORD: relativePath = executeSetNewPassword(request, domain)
    case COMMAND_POST_COMMENT: relativePath = executePostComment(request, domain, info)
    case COMMAND_COMMENT_REVIEW: relativePath = executeCommentReview(request, domain, info)
    case COMMAND_REMOVE_COMMENT: relativePath = executeRemoveComment(request, domain, info)
    case COMMAND_EDIT_COMMENT: relativePath = executeEditComment(request, domain, info)
    case COMMAND_UPDATE_COMMENT: relativePath = executeUpdateComment(request, domain, info)
    case COMMAND_CANCEL_UPDATE_COMMENT: relativePath = executeCancelUpdateComment(request, domain, info)

    default:
        
        Log.atError?.log("Unknown command with name: \(command) (original URL name: \(request.resourcePathParts[1]))")
        response.code = ._501_NotImplemented
        return .next
    }

    
    // Redirect the request
    
    if relativePath == nil {
        if let nextUrl = request.info[NEXT_URL_KEY] {
            relativePath = nextUrl
        }
    }
    
    guard relativePath != nil else {
        if response.code == nil {
            assert(false, "The relative path is still empty!")
            relativePath = "index.sf.html"
        }
        return .next
    }
    
    
    // Note: For request URLs there should be a test for resource availability, however this is unnecessary for internal generated resource paths.
    
    info[.relativeResourcePathKey] = relativePath!
    info[.absoluteResourcePathKey] = domain.webroot.appending(relativePath!)
    
    return .next
}

