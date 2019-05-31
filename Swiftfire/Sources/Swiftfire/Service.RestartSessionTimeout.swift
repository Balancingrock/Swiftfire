// =====================================================================================================================
//
//  File:       Service.RestartSessionTimeout.swift
//  Project:    Swiftfire
//
//  Version:    0.10.12
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.12 - Initial release, copied from SFConnection.Worker.swift
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// If a session is active (i.e. present in the 'info') then it will add a session cookie to restart the timeout for
// the session.
//
// This service should appear after "getSession". There should be no time consuming services after this one.
//
// Input:
// ------
//
// domain.sessionTimeout: If < 1, then session support is disabled.
// info[.sessionKey] = Active session.
//
//
// Output:
// -------
//
// response.cookies: A new cookie has been added for the session timeout.
//
//
// Return:
// -------
//
// .next
//
// =====================================================================================================================

import Foundation
import Http
import SwifterLog


/// Ensures that a session exists if the sessionTimeout for the given domain is > 0.
///
/// - Note: For a full description of all effects of this operation see the file: Service.RestartSessionTimeout.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The SFConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abort, on success .next.

func service_restartSessionTimeout(_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result {
    
    
    // Check if session support is enabled
    
    guard domain.sessionTimeout >= 1 else { return .next }


    // If a session is present, set the cookie request in the response to restart the session timeout

    if let session = info[.sessionKey] as? Session {
        if session.isActiveKeepActive {
            response.cookies.append(session.cookie)
            Log.atDebug?.log(
                "Session cookie added to response with id = \(session.id.uuidString)",
                from: Source(id: connection.logId, file: #file, function: #function, line: #line)
            )
        }
    }
    
    return .next
}
