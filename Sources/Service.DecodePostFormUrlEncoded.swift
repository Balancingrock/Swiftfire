// =====================================================================================================================
//
//  File:       Service.DecodePostFormUrlEncoded.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
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
// 0.10.7 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Decodes the name/value pairs in the body of a post if the content type is set to 'application/x-www-form-urlencoding'
//
//
// Input:
// ------
//
// request.contentType: Only if set to 'application/x-www-form-urlencoding'.
// request.payload: As UTF-8 data.
//
//
// On success:
// -----------
//
// info[.postInfo] = [Dictionary<String, String>] with the name/value pairs.
//
// return: .next
//
//
// On error:
// ---------
//
// return: .next
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterSockets


/// Takes the data (utf-8 ncoded) from the request body and transforms it into a series of name/value pairs.
///
/// - Note: For a full description of all effects of this operation see the file: Service.DecodePostFormUrlEncoded.swift
///
/// - Parameters:
///   - request: The HTTP request.
///   - connection: The HttpConnection object that is used for this connection.
///   - domain: The domain that is serviced for this request.
///   - info: A dictionary for communication between services.
///   - response: An object that can receive information to be returned in response to the request.
///
/// - Returns: On error .abort, on success .next.

func service_decodePostFormUrlEncoded(_ request: HttpRequest, _ connection: Connection, _ domain: Domain, _ info: inout Service.Info, _ response: inout HttpResponse) -> Service.Result {
    
    
    // Abort immediately if there is already a response code
    
    if response.code != nil { return .next }
    
    
    // Aliases
    
    guard let connection = (connection as? SFConnection) else {
        Log.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Type conflict: should be an SFConnection")
        return .next
    }
    
    
    // Check for data
    
    guard let strData = request.payload, !strData.isEmpty else {
        Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "No data to decode.")
        return .next
    }
    
    
    // Convert data to string
    
    guard let str = String.init(data: strData, encoding: String.Encoding.utf8) else {
        Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Cannot convert form urlencoded data to an UTF8 string")
        return .next
    }
    

    // Split into multiple name/value pairs
    
    var postInfo: Dictionary<String, String> = [:]
    
    var nameValuePairs = str.components(separatedBy: "&")
    
    while nameValuePairs.count > 0 {
        let nvPair = nameValuePairs.removeFirst()
        var nameValue = nvPair.components(separatedBy: "=")
        switch nameValue.count {
        case 0: break // error, don't do anything
        case 1: postInfo[nameValue[0]] = ""
        case 2: postInfo[nameValue[0]] = nameValue[1].removingPercentEncoding?.replacingOccurrences(of: "+", with: " ")
        default:
            let name = nameValue.removeFirst()
            postInfo[name] = nameValue.joined(separator: "=")
        }
    }
    
    
    // Add the post dictionary to the service info
    
    if postInfo.count > 0 { info[.postInfoKey] = postInfo }
    
    
    Log.atDebug?.log(id: connection.logId, source: #file.source(#function, #line), message: "Found \(postInfo.count) items")
    
    return .next
}

