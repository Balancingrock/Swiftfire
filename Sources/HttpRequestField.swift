// =====================================================================================================================
//
//  File:       HttpRequestField.swift
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
//  Copyright:  (c) 2014-2017 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Initial release, split off from HttpHeader
// =====================================================================================================================

import Foundation


/// This enum encodes the different kinds of header fields

public enum HttpRequestField: String {
    
    case accept                 = "Accept"
    case acceptCharset          = "Accept-Charset"
    case acceptEncoding         = "Accept-Encoding"
    case acceptLanguage         = "Accept-Language"
    case acceptDatetime         = "Accept-Datetime"
    case cacheControl           = "Cache-Control"
    case connection             = "Connection"
    case cookie                 = "Cookie"
    case contentLength          = "Content-Length"
    case contentMd5             = "Content-MD5"
    case contentType            = "Content-Type"
    case date                   = "Date"
    case expect                 = "Expect"
    case from                   = "From"
    case host                   = "Host"
    case ifMatch                = "If-Match"
    case ifModifiedSince        = "If-Modified-Since"
    case ifNoneMatch            = "If-None-Match"
    case ifRange                = "If-Range"
    case ifUnmodifiedRange      = "If-Unmodified-Since"
    case maxForwards            = "Max-Forwards"
    case origin                 = "Origin"
    case pragma                 = "Pragma"
    case proxyAuthorization     = "Proxy-Authorization"
    case range                  = "Range"
    case referer                = "Referer"
    case te                     = "TE"
    case userAgent              = "User-Agent"
    case upgrade                = "Upgrade"
    case warning                = "Warning"
    
    
    /// Checks if the line starts with this field and returns the value part if it does.
    ///
    /// - Parameter line: The string to be examined.
    ///
    /// - Returns: nil if the requested field is not present, otherwise the string after the ':' sign of the request field, without leading or trailing blanks
    
    public func getFieldValue(from line: String) -> String? {
        
        
        // Split the string in request and value
        
        var subStrings = line.components(separatedBy: ":")
        
        
        // The count of the array must be 2 or more, otherwise there is something wrong
        
        if subStrings.count < 2 { return nil }
        
        
        // The first string should be equal to the request field raw value
        
        if subStrings[0].caseInsensitiveCompare(self.rawValue) != ComparisonResult.orderedSame { return nil }
        
        
        // Remove the raw field value
        
        subStrings.removeFirst()
        
        
        // Assemble the rest of the string value again
        
        var strValue = ""
        
        for (i, str) in subStrings.enumerated() {
            strValue += str
            if i < (subStrings.count - 1) { strValue += ":" }
        }
        
        
        // Strip leading and trailing blanks
        
        return strValue.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}
