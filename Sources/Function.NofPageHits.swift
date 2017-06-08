// =====================================================================================================================
//
//  File:       Function.NofPageHits.swift
//  Project:    Swiftfire
//
//  Version:    0.10.10
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
// 0.10.10 - Changed Connection to SFConnection
// 0.10.6 - Renamed chain... to service...
// 0.10.1 - Fixed warnings in xcode 8.3
// 0.10.0 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
/// Returns the number of hits for a resource.
//
//
// Signature:
// ----------
//
// .nofPageHits(path: String)
//
//
// Parameters:
// -----------
//
// path: An optional string representing the path for which to retrieve the page hits. This string should be a relative
// path from the root of the domain. If no path is present the path at '.relativeResourcePathKey' from the
// 'environment.serviceInfo' will be used.
//
//
// Other Input:
// ------------
//
// None.
//
//
// Returns:
// --------
//
// The number of page hits.
//
//
// Other Output:
// -------------
//
// None.
//
// =====================================================================================================================

import Foundation


/// Returns the number of hits for a relative resource path. The path should be relative to the root directory of the domain.
///
/// If the arguments contains a String, then the string will be used as the relative resource path and the count for that resource will be returned.
///
/// If the argument does not contain any arguments, it will return the count for the currently requested resource.

func function_nofPageHits(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data? {
    
    var count: Int64 = -1
    
    var path: String?
    
    if case .array(let arr) = args {
        if arr.count > 0 {
            path = arr[0]
        }
    }
    
    if path == nil {
        path = environment.serviceInfo[.relativeResourcePathKey] as? String
    }

    if let path = path {
        count = statistics.foreverCount(domain: environment.domain.name, path: path)
    }

    Log.atDebug?.log(id: environment.connection.logId, source: #file.source(#function, #line), message: "ForeverCount for \(path ?? "Unknown") = \(count)")

    return count.description.data(using: String.Encoding.utf8)
}
