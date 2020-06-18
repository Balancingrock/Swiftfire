// =====================================================================================================================
//
//  File:       Service.Command.ForgotPassword.swift
//  Project:    Swiftfire
//
//  Version:    1.3.2
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
// 1.3.2 #14 fixed template links and usage of parameters
// 1.3.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Core
import Http


// Creates an email with a link to set a new password

/// The  name to be used in HTML to initiate the forgot password sequence.

let COMMAND_FORGOT_PASSWORD = "forgot-password"


fileprivate let FORGOT_PASSWORD_TEMPLATE = "/pages/account/forgot-password.sf.html"
fileprivate let FORGOT_PASSWORD_CONTINUE_TEMPLATE = "/pages/account/forgot-password-continue.sf.html"
fileprivate let FORGOT_PASSWORD_EMAIL_TEXT_TEMPLATE = "/assets/templates/request-new-password-text.sf.html"

fileprivate let FORGOT_PASSWORD_ACCOUNT_ID_KEY = "forgot-password-account-id"


/// Execute the Login command.
///
/// - parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - connection: The connection object the request uses.
///     - domain: The domain for which to review the comments.
///     - response: The response that will be returned.
///     - info: The service info dictionary.
///
/// - Returns: If a specific page should be returned, the path to that page is returned. Otherwise nil.

func executeForgotPassword(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ response: Response, _ info: Services.Info) -> String {

    // Note: We always return the 'success' template as we do not want to give out any clues to a possible hack attempt
    
    // The request info should contain a name key

    guard let accountId = request.info[FORGOT_PASSWORD_ACCOUNT_ID_KEY] else {
        Log.atError?.log("No '\(FORGOT_PASSWORD_ACCOUNT_ID_KEY)' found")
        return FORGOT_PASSWORD_CONTINUE_TEMPLATE
    }

    guard !accountId.isEmpty else {
        Log.atDebug?.log("Account id is empty")
        return FORGOT_PASSWORD_CONTINUE_TEMPLATE
    }

    guard accountId != "Anon" else {
        Log.atDebug?.log("Cannot change Anon account")
        return FORGOT_PASSWORD_CONTINUE_TEMPLATE
    }
    
    guard let account = domain.accounts.getAccountWithoutPassword(for: accountId) else {
        Log.atDebug?.log("No account for id: \(accountId)")
        return FORGOT_PASSWORD_CONTINUE_TEMPLATE
    }

    
    account.newPasswordVerificationCode = UUID().uuidString
    account.newPasswordRequestTimestamp = Date().unixTime
    
    
    // Add the new account to the accounts waiting for verification
    
    domain.accountsWaitingForNewPassword.append(account)
    
    
    // Send email verification mail
    
    let verificationLink = "http://\(domain.name):\(serverParameters.httpServicePortNumber.stringValue)/command/\(COMMAND_REQUEST_NEW_PASSWORD)?\(REQUEST_NEW_PASSWORD_CODE_KEY)=\(account.newPasswordVerificationCode)"

    
    var message: String = ""
    
    switch SFDocument.factory(path: (domain.webroot + "/" + FORGOT_PASSWORD_EMAIL_TEXT_TEMPLATE)) {
    case .success(let messageTemplate):

        let env = Functions.Environment(request: request, connection: connection, domain: domain, response: response, serviceInfo: info)
        request.info["link"] = verificationLink
        message = String(data: messageTemplate.getContent(with: env), encoding: .utf8) ?? "Click the following link (or copy it into the url field of a browser) to create a new password.\r\n Link = \(verificationLink)\r\n\r\n"

    case .failure(let err):
    
        Log.atError?.log("Failed to read template with error: \(err.localizedDescription)")
        message = "Click the following link (or copy it into the url field of a browser) to create a new password.\r\n Link = \(verificationLink)\r\n\r\n"
    }
    
    let fromAddress = request.info["FromAddress"] ?? "accountVerification@\(domain.name)"

    let email: String =
    """
    To: \(account.emailAddress)
    From: \(fromAddress)
    Content-Type: text/html;
    Subject: Set new password at \(domain.name)\n
    \(message)
    """
    
    sendEmail(email, domainName: domain.name)
    
    return FORGOT_PASSWORD_CONTINUE_TEMPLATE
}
