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


// Commands and their templates

// Email verification. This command is received when a new user clicks the link in the confirmation email.

fileprivate let COMMAND_EMAIL_VERIFICATION = "emailverification"

fileprivate let TEMPLATE_EMAIL_VERIFICATION_SUCCESS = "templates/emailVerificationSuccess.sf.html"
fileprivate let TEMPLATE_EMAIL_VERIFICATION_FAILED = "templates/emailVerificationFailed.sf.html"

fileprivate let CEV_VERIFICATION_CODE = "VerificationCode"


// This creates a new account and sends a verification email

fileprivate let COMMAND_CREATE_ACCOUNT = "createaccount"

fileprivate let TEMPLATE_CREATE_ACCOUNT_SUCCESS = "templates/createAccountSuccess.sf.html"
fileprivate let TEMPLATE_CREATE_ACCOUNT_FAILED = "templates/createAccountFailed.sf.html"
fileprivate let TEMPLATE_VERIFICATION_EMAIL_TEXT = "templates/verificationEmailText.sf.txt"

fileprivate let CA_ACCOUNT_NAME_KEY = "AccountName" // Necessary, unique, non-empty
fileprivate let CA_PASSWORD_KEY = "Password" // Necessary, non-empty
fileprivate let CA_EMAIL_KEY = "Email" // Necessary, email-pattern (*@*.*)
fileprivate let CA_OPTIONAL_FROM = "FromAddress" // Optional, unchecked
fileprivate let CA_OPTIONAL_BUBJECT = "Subject" // Optional, unchecked



/// Allows a domain admin to configure the domain. Only active if the URL that was requested started with the domain setup keyword.
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
        request.resourcePathParts.count > 2,
        request.resourcePathParts[0].lowercased() == "command"
        
        else {
        Log.atInfo?.log("Request is not a command")
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
        
    case COMMAND_EMAIL_VERIFICATION: relativePath = executeEmailVerification(request, response, domain, info)
        
    case COMMAND_CREATE_ACCOUNT: relativePath = executeCreateAccount(request, connection, domain, response, info)
        
    default:
        
        Log.atError?.log("Unknown command with name: \(request.resourcePathParts[1])")
        response.code = ._501_NotImplemented
        return .next
    }

    
    // Redirect the request
    
    guard relativePath != nil else {
        if response.code == nil {
            Log.atError?.log("The relative path is still empty!")
            response.code = ._500_InternalServerError
        }
        return .next
    }
    
    
    // Note: For request URLs there should be a test for resource availability, however this is unnecessary for internal generated resource paths.
    
    info[.relativeResourcePathKey] = relativePath!
    info[.absoluteResourcePathKey] = domain.webroot.appending("/\(relativePath!)")
    
    return .next
}

fileprivate func executeEmailVerification(_ request: Request, _ response: Response, _ domain: Domain, _ info: Services.Info) -> String? {
    
    guard let method = request.method, method == .get else {
        Log.atInfo?.log("Wrong method, should be GET")
        response.code = ._400_BadRequest
        return nil
    }
    
    guard let verificationCode = request.getInfo[CEV_VERIFICATION_CODE] else {
        Log.atInfo?.log("Missing verifcation code in command")
        response.code = ._400_BadRequest
        return nil
    }
    
    guard let waitingAccounts = domain.accountNamesWaitingForVerification?.root?.arrayOfString else {
        Log.atCritical?.log("Warning, an attempt was made to verify an account while there are no accounts waiting for verification")
        response.code = ._400_BadRequest
        return nil
    }
    
    var success = false
    for (index, accountName) in waitingAccounts.enumerated() {
        
        guard let account = domain.accounts.getAccountWithoutPassword(for: accountName) else {
            Log.atError?.log("Could not find account with name \(accountName) in domain")
            response.code = ._500_InternalServerError
            return nil
        }
        
        if account.emailVerificationCode == verificationCode {
            
            // Mark the account as verified
            account.emailWasVerified = true
            
            // Keep track in the log
            Log.atNotice?.log("Account with name \(accountName) has been verified")
            
            // Remove the account from the waiting list
            domain.accountNamesWaitingForVerification!.root!.removeElement(atIndex: index)
            
            // Assign the account to the session
            (info[.sessionKey] as? Session)?.info[.accountKey] = account
            
            Log.atDebug?.log("Account with name \(accountName) verified and logged-in")
            
            // Successful account verification
            success = true
            
            break
        }
    }
    
    if success {
        return TEMPLATE_EMAIL_VERIFICATION_SUCCESS
    } else {
        Log.atDebug?.log("Account verification failed for code: \(verificationCode)")
        return TEMPLATE_EMAIL_VERIFICATION_FAILED
    }
}

fileprivate func executeCreateAccount(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ response: Response, _ info: Services.Info) -> String? {

    guard let accountName = request.info[CA_ACCOUNT_NAME_KEY] else {
        Log.atError?.log("No '\(CA_ACCOUNT_NAME_KEY)' found")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }

    guard !accountName.isEmpty else {
        Log.atDebug?.log("Account name is empty")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }

    guard let password = request.info[CA_PASSWORD_KEY] else {
        Log.atError?.log("No '\(CA_PASSWORD_KEY)' found")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }
    
    guard !password.isEmpty else {
        Log.atDebug?.log("Password is empty")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }

    guard let emailAddress = request.info[CA_EMAIL_KEY] else {
        Log.atError?.log("No '\(CA_EMAIL_KEY)' found")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }
    
    let regex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: .init())
    
    guard let count = regex?.numberOfMatches(in: emailAddress, options: .init(), range: NSRange(location: 0, length: emailAddress.count)), count > 0 else {
        Log.atDebug?.log("Given email address seems to be incorrect: \(emailAddress)")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }
    
    guard !domain.accounts.available(name: accountName) else {
        Log.atDebug?.log("An account with this name already exists")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }
    
    guard let account = domain.accounts.newAccount(name: accountName, password: password) else {
        Log.atError?.log("Could not create a new account with name '\(accountName)' and password '\(password)'")
        return TEMPLATE_CREATE_ACCOUNT_FAILED
    }
    
    account.email = emailAddress
    account.emailVerificationCode = UUID().uuidString
    
    let verificationLink = "http://\(domain.name):\(serverParameters.httpServicePortNumber)/command/\(COMMAND_EMAIL_VERIFICATION)?\(CEV_VERIFICATION_CODE)=\(account.emailVerificationCode)"

    
    var message: String = ""
    
    if case .success(let messageTemplate) = SFDocument.factory(path: (domain.webroot + "/" + TEMPLATE_VERIFICATION_EMAIL_TEXT)) {

        var env = Functions.Environment(request: request, connection: connection, domain: domain, response: response, serviceInfo: info)
        request.info["Link"] = verificationLink
        message = String(data: messageTemplate.getContent(with: &env), encoding: .utf8) ?? "Click the following link (or copy it into the url field of a browser) to confirm your account at \(domain.name).\r\n Link = \(verificationLink)"

    } else {
        
        message = "Click the following link (or copy it into the url field of a browser) to confirm your account at \(domain.name).\r\n Link = \(verificationLink)"
    }
    
    let fromAddress = request.info["FromAddress"] ?? "accountVerification@\(domain.name)"

    let email: String = """
        To: \(emailAddress)\n
        From: \(fromAddress)\n
        Content-Type: text/html;\n
        Subject: Confirm Account Creation at \(domain.name)\n\n
        \(message)
    """
    
    return TEMPLATE_CREATE_ACCOUNT_SUCCESS
}
