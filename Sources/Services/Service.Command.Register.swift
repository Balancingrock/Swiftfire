// =====================================================================================================================
//
//  File:       Service.Command.Register.swift
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


/// The  name to be used in HTML to invoke the register process that will create a new account and send a verification email..

let COMMAND_REGISTER = "register"

fileprivate let REGISTER_TEMPLATE = "/pages/register.sf.html"
fileprivate let REGISTER_CONTINUE_TEMPLATE = "/pages/register-continue.sf.html"
fileprivate let REGISTER_VERIFICATION_EMAIL_TEXT_TEMPLATE = "/templates/email-verification-text.sf.html"

fileprivate let REGISTER_NAME_KEY = "register-name" // Necessary, unique, non-empty
fileprivate let REGISTER_PASSWORD1_KEY = "register-password-1" // Necessary, non-empty
fileprivate let REGISTER_PASSWORD2_KEY = "register-password-2" // Necessary, non-empty
fileprivate let REGISTER_EMAIL_KEY = "register-email" // Necessary, email-pattern, verified by a regex that covers 99%
fileprivate let REGISTER_FROM_KEY_OPTIONAL = "from-address" // Optional, unchecked
fileprivate let REGISTER_SUBJECT_KEY_OPTIONAL = "subject" // Optional, unchecked


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

func executeRegister(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ response: Response, _ info: Services.Info) -> String? {

    
    // A session should be present
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atError?.log("Missing session")
        return LOGIN_TEMPLATE
    }

    // This guards against attempts to store too many account (which could lead to out-of-memory or out-of-disk errors)
    // Note that the address is logged, the admin can decide to block this address
    
    guard session.nofRegistrationAttempts < 10 else {
        Log.atAlert?.log("Too many registration attempts from IP address: \(connection.remoteAddress)")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Too many registration attempts, try again later"
        return REGISTER_TEMPLATE
    }
    
    session.nofRegistrationAttempts += 1
    
    
    // The request info should contain a Register Name key

    guard let accountName = request.info[REGISTER_NAME_KEY] else {
        Log.atError?.log("No '\(REGISTER_NAME_KEY)' found")
        return REGISTER_TEMPLATE
    }

    guard !accountName.isEmpty else {
        Log.atDebug?.log("Account name is empty")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Missing account name"
        return REGISTER_TEMPLATE
    }
    
    
    // The next test prevents the creation of a special account name that could be used to remove/edit comments from other anon users.
    
    guard !accountName.lowercased().starts(with: "anon") else {
        Log.atDebug?.log("The account name cannot start with 'anon'")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Account names cannot start with 'anon'"
        return REGISTER_TEMPLATE
    }

    guard domain.accounts.available(name: accountName) else {
        Log.atDebug?.log("An account with this name already exists")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Account name not available"
        return REGISTER_TEMPLATE
    }

    
    // The request info should contain a Register Password1 key

    guard let password1 = request.info[REGISTER_PASSWORD1_KEY] else {
        Log.atError?.log("No '\(REGISTER_PASSWORD1_KEY)' found")
        return REGISTER_TEMPLATE
    }
    
    guard password1.count > 4 else {
        Log.atDebug?.log("Password should contain more than 4 characters")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Password should contain more than 4 characters"
        return REGISTER_TEMPLATE
    }

    
    // The request info should contain a Register Password2 key

    guard let password2 = request.info[REGISTER_PASSWORD2_KEY] else {
        Log.atError?.log("No '\(REGISTER_PASSWORD2_KEY)' found")
        return REGISTER_TEMPLATE
    }
    
    guard !password2.isEmpty else {
        Log.atDebug?.log("Password is empty")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Second password cannot be empty"
        return REGISTER_TEMPLATE
    }

    guard password1 == password2 else {
        Log.atDebug?.log("Password1 and password2 are not the same")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "First and second password must be equal"
        return REGISTER_TEMPLATE
    }
    
    
    // The request info should contain a Register Email key

    guard let emailAddress = request.info[REGISTER_EMAIL_KEY] else {
        Log.atError?.log("No '\(REGISTER_EMAIL_KEY)' found")
        return REGISTER_TEMPLATE
    }
    
    let regex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: .init())
    
    guard let count = regex?.numberOfMatches(in: emailAddress, options: .init(), range: NSRange(location: 0, length: emailAddress.count)), count > 0 else {
        Log.atDebug?.log("Given email address seems to be incorrect: \(emailAddress)")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "The email address looks incorrect and cannot be used"
        return REGISTER_TEMPLATE
    }
    
    
    // Create new account with a verification code
    
    guard let account = domain.accounts.newAccount(name: accountName, password: password1) else {
        Log.atError?.log("Could not create a new account with name '\(accountName)' and password '\(password1)'")
        return REGISTER_TEMPLATE
    }
    
    account.emailAddress = emailAddress
    account.emailVerificationCode = UUID().uuidString
    
    
    // Add the new account to the accounts waiting for verification
    
    domain.accountUuidsWaitingForVerification.append(account.uuid.uuidString)
    
    
    // Send email verification mail
    
    let verificationLink = "http://\(domain.name):\(serverParameters.httpServicePortNumber.stringValue)/command/\(COMMAND_EMAIL_VERIFICATION)?\(EMAIL_VERIFICATION_CODE_KEY)=\(account.emailVerificationCode)"

    
    var message: String = ""
    
    switch SFDocument.factory(path: (domain.webroot + "/" + REGISTER_VERIFICATION_EMAIL_TEXT_TEMPLATE)) {
    case .success(let messageTemplate):

        let env = Functions.Environment(request: request, connection: connection, domain: domain, response: response, serviceInfo: info)
        request.info["link"] = verificationLink
        message = String(data: messageTemplate.getContent(with: env), encoding: .utf8) ?? "Click the following link (or copy it into the url field of a browser) to confirm your account at \(domain.name).\r\n Link = \(verificationLink)\r\n\r\n"

    case .error(let err):
    
        Log.atError?.log("Failed to read template with error: \(err)")
        message = "Click the following link (or copy it into the url field of a browser) to confirm your account at \(domain.name).\r\n\r\nLink = \(verificationLink)"
    }
    
    let fromAddress = request.info["FromAddress"] ?? "accountVerification@\(domain.name)"

    let email: String =
    """
    To: \(emailAddress)
    From: \(fromAddress)
    Content-Type: text/html;
    Subject: Confirm Account Creation at \(domain.name)\n
    \(message)
    """
    
    sendEmail(email, domainName: domain.name)
    
    return REGISTER_CONTINUE_TEMPLATE
}
