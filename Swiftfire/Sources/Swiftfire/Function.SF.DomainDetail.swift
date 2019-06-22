// =====================================================================================================================
//
//  File:       Function.SF.DomainDetail.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Returns a detail of the current domain.
//
//
// Signature:
// ----------
//
// .sf-domainDetail(item)
//
//
// Parameters:
// -----------
//
// item: An identifier with the name of the detail. Cuurently supported = "name".
//
//
// Other Input:
// ------------
//
// service[.postInfoKey]["DomainName"] must contain the name of an existing domain.
//
//
// Returns:
// --------
//
// The requested item or "***Error" in case of error.
//
//
// Other Output:
// -------------
//
// None.
//
//
// =====================================================================================================================

import Foundation


/// - Returns: A detail of the current domain.

func function_sf_domainDetail(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {

    
    // Check argument validity
    
    guard case .array(let arr) = args, arr.count == 1 else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Check that a server admin is logged in
    
    guard let session = environment.serviceInfo[.sessionKey] as? Session else {
        return "Session error".data(using: String.Encoding.utf8)
    }
    
    guard let account = session.info[.accountKey] as? Account else {
        return "Account error".data(using: String.Encoding.utf8)
    }
    
    guard serverAdminDomain.accounts.contains(account.uuid) else {
        return "Illegal access".data(using: String.Encoding.utf8)
    }

    
    // Check that a valid domain name was specified
    
    guard let postInfo = environment.serviceInfo[.postInfoKey] as? PostInfo,
          let name = postInfo["DomainName"] else { return "***Error***".data(using: String.Encoding.utf8) }
    
    guard let domain = domains.domain(forName: name) else { return "***Error***".data(using: String.Encoding.utf8) }
    
    
    // Return the asked for value
    
    let parameter = arr[0].lowercased()
    
    switch parameter {
    case "name": return domain.name.data(using: String.Encoding.utf8)
    case "wwwincluded": return domain.wwwIncluded.description.data(using: String.Encoding.utf8)
    case "root": return domain.root.data(using: String.Encoding.utf8)
    case "forewardurl": return domain.forwardUrl.data(using: String.Encoding.utf8)
    case "enabled": return domain.enabled.description.data(using: String.Encoding.utf8)
    case "accesslogenabled": return domain.accessLogEnabled.description.data(using: String.Encoding.utf8)
    case "404logenabled": return domain.four04LogEnabled.description.data(using: String.Encoding.utf8)
    case "sessionlogenabled": return domain.sessionLogEnabled.description.data(using: String.Encoding.utf8)
    case "sfresources": return domain.sfresources.data(using: String.Encoding.utf8)
    case "sessiontimeout": return domain.sessionTimeout.description.data(using: String.Encoding.utf8)
    default: return "***Error***".data(using: String.Encoding.utf8)
    }
}
