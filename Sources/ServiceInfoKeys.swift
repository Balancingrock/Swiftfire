// =====================================================================================================================
//
//  File:       ServiceInfoKeys.swift
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
// 0.10.7 - Added getInfoKey
//        - Added postInfoKey
// 0.10.6 - Initial release (split off from Service.swift)
//
// =====================================================================================================================

import Foundation


/// Service Info key's

public enum ServiceInfoKey: String {
    
    
    /// [String] set by the service that determines the URL of the resource to be fetched. (DomainService.GetResourcePathFromUrl)
    ///
    /// This path is relative to the root of the file system. It is used to fetch the requested resource.
    
    case absoluteResourcePathKey = "AbsoluteResourcePath"
    
    
    /// [String] set by the service that determines the URL of the resource to be fetched. (DomainService.GetResourcePathFromUrl)
    ///
    /// This path is relative to the root of the domain. It is used for statistics purposes.
    
    case relativeResourcePathKey = "RelativeResourcePath"
    
    
    /// [Int64] set by HttpConnection.Worker before first domain service call.
    ///
    /// It is the time stamp at the start of the HTTP request processing. It is used for statistics purposes.
    
    case responseStartedKey = "ResponseStarted"
    
    
    /// [Session] set by the service that determines the session for this request.
    
    case sessionKey = "SessionId"
    
    
    /// [Dictionary<String, String>] The name/value pairs for a GET request that returns form data.
    ///
    /// Set by the service: GetResourcePathFromUrl
    
    case getInfoKey = "GetInfo"
    
    
    /// [Dictionary<String, String>] The name/value pairs for a POST request that returns form data x-www-form-urlencoded.
    ///
    /// Set by the service: DecodePostFormUrlEncoded
    
    case postInfoKey = "PostInfo"
}

