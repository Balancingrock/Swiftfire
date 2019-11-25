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

import Http
import SwifterLog
import Core


// Commands, templates, pages and keys
//
// Note that commands and templates are lowercase
// Template paths are case sensitive and must lead with a "/"

fileprivate let PREVIOUS_ATTEMPT_MESSAGE_KEY = "previous-attempt-message"
public let ORIGINAL_PAGE_URL_KEY = "original-page-url"

// Login. This command is used to login to an existing account. It needs the LoginName and LoginPassword.

fileprivate let LOGIN_COMMAND = "login"

fileprivate let LOGIN_TEMPLATE = "/pages/login.sf.html"

fileprivate let LOGIN_NAME_KEY = "login-name"
fileprivate let LOGIN_PASSWORD_KEY = "login-password"



// Logout. Disassociate an account with the session.

fileprivate let LOGOUT_COMMAND = "logout"


// When somebody tried to do something which is not allowed, yet also not an error

fileprivate let ATTEMPT_NOT_ALLOWED_TEMPLATE = "/pages/not-allowed.sf.html"


// Email verification. This command is received when a new user clicks the link in the confirmation email.

fileprivate let EMAIL_VERIFICATION_COMMAND = "email-verification"

fileprivate let EMAIL_VERIFICATION_SUCCESS_TEMPLATE = "/pages/email-verification-success.sf.html"
fileprivate let EMAIL_VERIFICATION_FAILED_TEMPLATE = "/pages/email-verification-failed.sf.html"

fileprivate let EMAIL_VERIFICATION_CODE_KEY = "verification-code"


// This creates a new account and sends a verification email

fileprivate let REGISTER_COMMAND = "register"

fileprivate let REGISTER_TEMPLATE = "/pages/register.sf.html"
fileprivate let REGISTER_CONTINUE_TEMPLATE = "/pages/register-continue.sf.html"
fileprivate let REGISTER_VERIFICATION_EMAIL_TEXT_TEMPLATE = "/templates/email-verification-text.sf.html"

fileprivate let REGISTER_NAME_KEY = "register-name" // Necessary, unique, non-empty
fileprivate let REGISTER_PASSWORD1_KEY = "register-password-1" // Necessary, non-empty
fileprivate let REGISTER_PASSWORD2_KEY = "register-password-2" // Necessary, non-empty
fileprivate let REGISTER_EMAIL_KEY = "register-email" // Necessary, email-pattern, verified by a regex that covers 99%
fileprivate let REGISTER_FROM_KEY_OPTIONAL = "from-address" // Optional, unchecked
fileprivate let REGISTER_SUBJECT_KEY_OPTIONAL = "subject" // Optional, unchecked


// Creates an email with a link to set a new password

fileprivate let FORGOT_PASSWORD_COMMAND = "forgot-password"

fileprivate let FORGOT_PASSWORD_TEMPLATE = "/pages/forgot-password.sf.html"
fileprivate let FORGOT_PASSWORD_CONTINUE_TEMPLATE = "/pages/forgot-password-continue.sf.html"
fileprivate let FORGOT_PASSWORD_EMAIL_TEXT_TEMPLATE = "/templates/request-new-password-text.sf.html"

fileprivate let FORGOT_PASSWORD_ACCOUNT_ID_KEY = "forgot-password-account-id"


// The request new password command (2-stage, followed by set new password)
// This command is triggered by the forgot password mail that was send

fileprivate let REQUEST_NEW_PASSWORD_COMMAND = "request-new-password"

fileprivate let REQUEST_NEW_PASSWORD_FAILED_TEMPLATE = "/pages/request-new-password-failed.sf.html"

fileprivate let REQUEST_NEW_PASSWORD_CODE_KEY = "request-new-password-code"


// The set new password command (the follow-up of the request new password Command)

fileprivate let SET_NEW_PASSWORD_COMMAND = "set-new-password"

fileprivate let SET_NEW_PASSWORD_TEMPLATE = "/pages/set-new-password.sf.html"
fileprivate let SET_NEW_PASSWORD_SUCCESS_TEMPLATE = "/pages/set-new-password-success.sf.html"

fileprivate let SET_NEW_PASSWORD_ACCOUNT_ID_KEY = "uuid"
fileprivate let SET_NEW_PASSWORD_PASSWORD1_KEY = "set-new-password-1"
fileprivate let SET_NEW_PASSWORD_PASSWORD2_KEY = "set-new-password-2"


// General purpose keys used in the POST requests

internal let BUTTON_KEY = "button"
internal let NEXT_URL_KEY = "next-url"
internal let ACCOUNT_ID_KEY = "account-id"
internal let COMMENT_ACCOUNT_KEY = "comment-account-id"
internal let COMMENT_UUID_KEY = "comment-uuid"
internal let COMMENT_SECTION_IDENTIFIER_KEY = "comment-section-identifier"
internal let COMMENT_TEXT_KEY = "comment-text"
internal let COMMENT_ORIGINAL_TIMESTAMP_KEY = "comment-original-timestamp"


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
        
    case LOGIN_COMMAND: relativePath = executeLogin(request, domain, info)
    case LOGOUT_COMMAND: relativePath = executeLogout(request, info)
    case EMAIL_VERIFICATION_COMMAND: relativePath = executeEmailVerification(request, response, domain, info)
    case REGISTER_COMMAND: relativePath = executeRegister(request, connection, domain, response, info)
    case FORGOT_PASSWORD_COMMAND: relativePath = executeForgotPassword(request, connection, domain, response, info)
    case REQUEST_NEW_PASSWORD_COMMAND: relativePath = executeRequestNewPassword(request, domain)
    case SET_NEW_PASSWORD_COMMAND: relativePath = executeSetNewPassword(request, domain)
    case COMMAND_POST_COMMENT: relativePath = executePostComment(request, domain, info)
    case COMMAND_COMMENT_REVIEW: relativePath = executeCommentReview(request, domain, info)
    case COMMAND_REMOVE_COMMENT: relativePath = executeRemoveComment(request, domain, info)
    case COMMAND_EDIT_COMMENT: relativePath = executeEditComment(request, domain, info)
    case COMMAND_UPDATE_COMMENT: relativePath = executeUpdateComment(request, domain, info)

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


// MARK: Commands for execution


fileprivate func executeLogin(_ request: Request, _ domain: Domain, _ info: Services.Info) -> String? {
    
    
    // A session should be present
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atError?.log("Missing session")
        return LOGIN_TEMPLATE
    }

    
    // Prevent brute force breakin attempts by imposing a 2 second wait since the last login attempt
    
    if let previousAttempt = session[.lastFailedLoginAttemptKey] as? Int64 {
        let now = Date().javaDate
        if now - previousAttempt < 2000 {
            session[.lastFailedLoginAttemptKey] = now
            request.info["PreviousAttemptMessage"] = "Too quick, wait a few seconds before trying again"
            return LOGIN_TEMPLATE
        }
    }

    
    // The request info should contain a LoginName key for the login name
    
    guard let loginName = request.info[LOGIN_NAME_KEY] else {
        Log.atError?.log("Missing '\(LOGIN_NAME_KEY)' in request.info")
        return LOGIN_TEMPLATE
    }
    
    guard !loginName.isEmpty else {
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "The Name field cannot be empty"
        return LOGIN_TEMPLATE
    }
    
    
    // The request info should contain a LoginName key for the login name

    guard let loginPassword = request.info[LOGIN_PASSWORD_KEY] else {
        Log.atError?.log("Missing '\(LOGIN_PASSWORD_KEY)' in request.info")
        return LOGIN_TEMPLATE
    }
            
    
    // Get the account (if it exists, is active and the password is correct)
    
    guard let account = domain.accounts.getActiveAccount(withName: loginName, andPassword: loginPassword) else {
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Unknown name - password combination"
        return LOGIN_TEMPLATE
    }
    
    
    // Success
    
    Log.atDebug?.log("Account name \(account.name) logged in")
    
    session.info[.accountKey] = account
    
    return (session.info[.preLoginUrlKey] as? String) ?? "/index.sf.html"
}


fileprivate func executeLogout(_ request: Request, _ info: Services.Info) -> String? {
    
    
    // A session should be present
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atError?.log("Missing session")
        return LOGIN_TEMPLATE
    }

    session.info.remove(key: .accountKey)
    
    return request.info[ORIGINAL_PAGE_URL_KEY] ?? "/index.sf.html"
}


fileprivate func executeRegister(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ response: Response, _ info: Services.Info) -> String? {

    
    // A session should be present
    
    guard let session = info[.sessionKey] as? Session else {
        Log.atError?.log("Missing session")
        return LOGIN_TEMPLATE
    }

    // This guards against attempts to store too many account (which could lead to out-of-memory or out-of-disk errors)
    // Note that the address is logged, the admin can decide to block this address
    
    guard session.nofRegistrationAttempts < 10 else {
        Log.atCritical?.log("Too many registration attempts from IP address: \(connection.remoteAddress)")
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
        Log.atDebug?.log("The account name cannot start with 'anon-'")
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
    
    domain.accountIdsWaitingForVerification?.root?.appendElement(account.uuid)
    
    
    // Send email verification mail
    
    let verificationLink = "http://\(domain.name):\(serverParameters.httpServicePortNumber.stringValue)/command/\(EMAIL_VERIFICATION_COMMAND)?\(EMAIL_VERIFICATION_CODE_KEY)=\(account.emailVerificationCode)"

    
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


fileprivate func executeEmailVerification(_ request: Request, _ response: Response, _ domain: Domain, _ info: Services.Info) -> String? {
        
    guard let verificationCode = request.info[EMAIL_VERIFICATION_CODE_KEY] else {
        Log.atInfo?.log("Missing verifcation code in command")
        response.code = ._400_BadRequest
        return nil
    }
    
    guard let waitingAccounts = domain.accountIdsWaitingForVerification?.root?.arrayOfString else {
        Log.atNotice?.log("An attempt was made to verify an account while there are no accounts waiting for verification")
        return EMAIL_VERIFICATION_FAILED_TEMPLATE
    }
    
    var success = false
    for (index, accountId) in waitingAccounts.enumerated() {
        
        guard let uuid = UUID(uuidString: accountId) else {
            Log.atNotice?.log("Could not create UUID for: \(accountId)")
            return EMAIL_VERIFICATION_FAILED_TEMPLATE
        }
        
        guard let account = domain.accounts.getAccount(for: uuid) else {
            Log.atNotice?.log("Could not find account with UUID \(accountId)")
            return EMAIL_VERIFICATION_FAILED_TEMPLATE
        }
        
        if account.emailVerificationCode == verificationCode {
            
            // Mark the account as verified
            account.emailVerificationCode = ""
            
            // Keep track in the log
            Log.atNotice?.log("Account with name \(account.name) and uuid \(accountId) has been verified")
            
            // Remove the account from the waiting list
            domain.accountIdsWaitingForVerification!.root!.removeElement(atIndex: index)
            
            // Note: Do not automatically login. That could cause somebody else but the user to be logged in as that user.
                        
            // Successful account verification
            success = true
            
            break
        }
    }
    
    if success {
        return EMAIL_VERIFICATION_SUCCESS_TEMPLATE
    } else {
        Log.atNotice?.log("Account verification failed for code: \(verificationCode)")
        return EMAIL_VERIFICATION_FAILED_TEMPLATE
    }
}


fileprivate func executeForgotPassword(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ response: Response, _ info: Services.Info) -> String {

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
    
    guard let uuid = UUID(uuidString: accountId) else {
        Log.atDebug?.log("Cannot create UUID from \(accountId)")
        return FORGOT_PASSWORD_CONTINUE_TEMPLATE
    }

    guard let account = domain.accounts.getAccount(for: uuid) else {
        Log.atDebug?.log("No account for uuid: \(accountId)")
        return FORGOT_PASSWORD_CONTINUE_TEMPLATE
    }

    
    account.newPasswordVerificationCode = UUID().uuidString
    account.newPasswordRequestTimestamp = Date().unixTime
    
    
    // Add the new account to the accounts waiting for verification
    
    domain.accountsWaitingForNewPassword.append(account)
    
    
    // Send email verification mail
    
    let verificationLink = "http://\(domain.name):\(serverParameters.httpServicePortNumber.stringValue)/command/\(REQUEST_NEW_PASSWORD_COMMAND)?\(REQUEST_NEW_PASSWORD_CODE_KEY)=\(account.newPasswordVerificationCode)"

    
    var message: String = ""
    
    switch SFDocument.factory(path: (domain.webroot + "/" + FORGOT_PASSWORD_EMAIL_TEXT_TEMPLATE)) {
    case .success(let messageTemplate):

        let env = Functions.Environment(request: request, connection: connection, domain: domain, response: response, serviceInfo: info)
        request.info["link"] = verificationLink
        message = String(data: messageTemplate.getContent(with: env), encoding: .utf8) ?? "Click the following link (or copy it into the url field of a browser) to create a new password.\r\n Link = \(verificationLink)\r\n\r\n"

    case .error(let err):
    
        Log.atError?.log("Failed to read template with error: \(err)")
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


fileprivate func executeRequestNewPassword(_ request: Request, _ domain: Domain) -> String {
    
    guard let code = request.info[REQUEST_NEW_PASSWORD_CODE_KEY] else {
        Log.atError?.log("Missing \(REQUEST_NEW_PASSWORD_CODE_KEY)")
        return REQUEST_NEW_PASSWORD_FAILED_TEMPLATE
    }
    
    var account: Account?
    for a in domain.accountsWaitingForNewPassword {
        if code == a.newPasswordVerificationCode {
            domain.accountsWaitingForNewPassword.removeObject(object: a)
            account = a
            break
        }
    }
    
    if let account = account {
        
        // Set the account name and request the set new password page
        request.info[SET_NEW_PASSWORD_ACCOUNT_ID_KEY] = account.uuid.uuidString
        return SET_NEW_PASSWORD_TEMPLATE
        
    } else {
        
        Log.atError?.log("The account was not found, possible time-out or double-try?")
        return REQUEST_NEW_PASSWORD_FAILED_TEMPLATE
    }
}


fileprivate func executeSetNewPassword(_ request: Request, _ domain: Domain) -> String {
    
    guard let accountId = request.info[SET_NEW_PASSWORD_ACCOUNT_ID_KEY], let uuid = UUID(uuidString: accountId) else {
        Log.atError?.log("Missing account id")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard let account = domain.accounts.getAccount(for: uuid) else {
        Log.atError?.log("Unknown account for uuid: \(accountId)")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard account.newPasswordRequestTimestamp != 0 else {
        Log.atNotice?.log("Somebody seems to be trying to set a new password for `\(account.name)` without a pending request")
        return ATTEMPT_NOT_ALLOWED_TEMPLATE
    }
    
    
    // The request info should contain a Password1 key

    guard let password1 = request.info[SET_NEW_PASSWORD_PASSWORD1_KEY] else {
        Log.atError?.log("No '\(SET_NEW_PASSWORD_PASSWORD1_KEY)' found")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard password1.count > 4 else {
        Log.atDebug?.log("Password should contain more than 4 characters")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Password should contain more than 4 characters"
        return SET_NEW_PASSWORD_TEMPLATE
    }

    
    // The request info should contain a Password2 key

    guard let password2 = request.info[SET_NEW_PASSWORD_PASSWORD2_KEY] else {
        Log.atError?.log("No '\(SET_NEW_PASSWORD_PASSWORD2_KEY)' found")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    guard password1 == password2 else {
        Log.atDebug?.log("Passwords are not the same")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "First and second password must be equal"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    
    // Set the new password
    
    guard account.updatePassword(password1) else {
        Log.atError?.log("Could not changethe password")
        request.info[PREVIOUS_ATTEMPT_MESSAGE_KEY] = "Server error, please contact the administrator"
        return SET_NEW_PASSWORD_TEMPLATE
    }
    
    account.newPasswordVerificationCode = ""
    account.newPasswordRequestTimestamp = 0
    
    return SET_NEW_PASSWORD_SUCCESS_TEMPLATE
}


