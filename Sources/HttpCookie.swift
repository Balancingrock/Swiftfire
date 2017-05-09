// =====================================================================================================================
//
//  File:       HttpCookie.swift
//  Project:    Swiftfire
//
//  Version:    0.10.6
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.6 - Initial release.
// =====================================================================================================================

import Foundation


/// An HTTP Cookie.
///
/// There are two types of cookies: Those in HTTP requests and those in HTTP Responses.
/// The request cookies consist of a name and value only. The response cookies can have attributes.

public final class HttpCookie: CustomStringConvertible {
    
    
    public typealias Cookies = Array<HttpCookie>

    
    private static let noCookies = Cookies()

    
    /// The kind of timout for cookies.
    
    public enum Timeout {
        
        
        /// The cookie expires after this date.
        
        case expiry(Date)
        
        
        /// The cookie expires after this many seconds.
        
        case maxAge(Int)
    }
    
    
    /// The name of the cookie
    
    public let name: String
    
    
    /// The value of the cookie
    
    public let value: String
    
    
    /// Expiration date of the cookie
    
    public let timeout: Timeout?
    
    
    /// The path for which the cookie is valid
    
    public let path: String?
    
    
    /// The domain for which the cookie is valid
    
    public let domain: String?
    
    
    /// If true, then the cookie may only be transferred securely
    
    public let secure: Bool?
    
    
    /// If true, then the cookie may only be used by the HTTP protocol
    
    public let httpOnly: Bool?
    
    
    /// Create a new cookie from the given values.
    ///
    /// - Note: The name and value parameters are not checked on validity. Be sure to use only valid characters in the strings.
    ///
    /// - Parameters:
    ///   - name: The name of the cookie.
    ///   - value: The value of the cookie.
    ///   - expiration: An optional expiration date.
    ///   - path: An optional path that specifies where the cookie must be used.
    ///   - domain: An optional domain for which the cookie may be used.
    ///   - secure: An optional flag that will limit the cookie to secure connections.
    ///   - httpOnly: An optional flag that limits the cookie to HTTP only.
    
    public init(name: String, value: String, timeout: Timeout? = nil, path: String? = nil, domain: String? = nil, secure: Bool? = nil, httpOnly: Bool? = nil) {

        self.name = name
        self.value = value
        
        self.timeout = timeout
        self.path = path
        self.domain = domain
        
        self.secure = secure
        self.httpOnly = httpOnly
    }
        
    
    /// For the HTTP request. Reads the cookies that are included in a HTTP header line.
    
    public static func factory(string: String?) -> Cookies {
        
        
        // Ensure the string is present
        
        guard let string = string else { return noCookies }
        
        
        // Create the character set of characters that split the string into substrings
        
        let separatorSet: CharacterSet = CharacterSet(charactersIn: ":;=")
        
        
        // Create the substrings
        
        var subs: [String] = string.replacingOccurrences(of: " ", with: "").components(separatedBy: separatorSet)
        
        
        // There must be at least 3 substrings
        
        if subs.count < 3 { return noCookies }
        
        
        // The first substring must be "Cookie"
        
        if subs[0].caseInsensitiveCompare("Cookie") == ComparisonResult.orderedSame {
            
            
            // Remove the cookie text
            
            subs.removeFirst()
        
        
            // Now a sequence of key/value pairs should follow
        
            var arr: [HttpCookie] = []
        
            while subs.count >= 2 {
            
            
                // The next substring is the name of the cookie
            
                let name = subs.removeFirst()
            
            
                // Next is the value
                
                let value = subs.removeFirst()

                
                // Add a new cookie to the result
                
                arr.append(HttpCookie(name: name, value: value))
            }
        
            return arr
            
        } else {
            
            return noCookies
        }
    }
    
    
    /// Creates a description, is used by the HTTP response to create a cookie setting.
    
    public var description: String {
        var str = "Set-Cookie: \(name)=\(value)"
        switch timeout {
        case nil: break
        case .expiry(let date)?: str += "; Expires=\(date)"
        case .maxAge(let age)?:  str += "; Max-Age=\(age)"
        }
        if let path = path { str += "; Path=\(path)" }
        if let domain = domain { str += "; Domain=\(domain)" }
        if let secure = secure, secure == true { str += "; Secure" }
        if let httpOnly = httpOnly, httpOnly == true { str += "; HttpOnly" }
        return str
    }
    
    
    /// Creates an expired "copy" of self.
    
    public func expired() -> HttpCookie {
        let invalidDate = Date().addingTimeInterval(TimeInterval(-24*60*60))
        return HttpCookie(name: name, value: "", timeout: .expiry(invalidDate))
    }
}
