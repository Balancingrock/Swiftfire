// =====================================================================================================================
//
//  File:       HttpResponse.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.7
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
// 0.10.7 - Replaces SWIFTFIRE_VERSION with serverVersion.
// 0.10.6 - Introduced HttpResponse class. (Complete rewrite)
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks, initial release.
// =====================================================================================================================

import Foundation
import SwifterLog


/// This class is used to create the HTTP response data.

public final class HttpResponse: CustomStringConvertible {
    
    
    /// The default kind of document (returned when 'doctype' is nill when creating the response)
    
    public static let docTypeHtml401Transitional = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
    
    
    /// Enable public instantiation
    
    public init() {}
    
    
    /// The HTTP version of the response, defaults to empty if not set.
    
    public var version: HttpVersion?
    
    
    /// The HTTP code for the response, *must* be set before creating the response data
    
    public var code: HttpResponseCode?
    
    
    /// The date of the response, defaults to the current date/time if not set.
    
    public var date: Date?
    
    private func addDate() -> String {
        return "Date: \(date ?? Date())" + CRLF
    }

    
    /// The MIME type indicator for the data to be returned, defaults to "Unknown" if not set.
    
    public var contentType: String?
    
    private func addContentType() -> String {
        return "Content-Type: \(contentType ?? "Unknown"); charset=UTF-8" + CRLF
    }

    
    /// The cookies to be set on the client
    
    public var cookies: Array<HttpCookie> = []
    
    private func addCookies() -> String {
        var str = ""
        for cookie in cookies {
            str += cookie.description + CRLF
        }
        return str
    }

    
    /// The server information, defaults to Swiftfire + version number if not set.
    
    public var server: String?
    
    private func addServer() -> String {
        return "Server: Swiftfire/\("0-0-0")" + CRLF
    }

    
    /// The payload data to be added to the response
    
    public var payload: Data?
    
    private func addContentLength(size: Int) -> String {
        return "Content-Length: \(size)" + CRLFCRLF
    }

    
    /// Create a response from the members that have been assigned previously.
    ///
    /// - Note: The code and payload *must* be set before calling this function. The version and contentType should be set.
    
    public var data: Data? {
        
        assert (code != nil)
        assert (payload != nil)
        
        var header: String = "\(version?.rawValue ?? "") \(code?.rawValue ?? "")" + CRLF
        header.append(addDate())
        header.append(addServer())
        header.append(addContentType())
        header.append(addCookies())
        header.append(addContentLength(size: payload?.count ?? 0))
        
        var data: Data? = header.data(using: String.Encoding.utf8)
        
        assert (data != nil)
        
        if let payload = self.payload { data?.append(payload) }
        
        return data
    }
    
    
    /// Create a payload with an error message in it. If no error message is given, a simple default message will be generated.
    ///
    /// - Note: A 'code' *must* be set before this function is called.
    ///
    /// - Parameter message: Optional message.
    
    public func createErrorPayload(message: String? = nil) {
        
        
        // Create default message if no message is given.
        
        let message = message ?? "HTTP Request rejected with: \(code?.rawValue ?? "Unknown")"
        
        
        // Create the payload
        
        var content: String = HttpResponse.docTypeHtml401Transitional + CRLF
        content.append("<html><head><title>\(code?.rawValue ?? "Unknown")</title></head>" + CRLF)
        content.append("<body>\(message)</body></html>" + CRLF)
        
        self.payload = content.data(using: String.Encoding.utf8, allowLossyConversion: true)
    }
    
    
    /// CustomStringConvertible
    
    public var description: String {
        var str = "Http Response:\n"
        str += " Version: \(version?.rawValue ?? "Not set")\n"
        str += " Code: \(code?.rawValue ?? "Not set")\n"
        str += " Date: \(date == nil ? "Not set" : date!.description)\n"
        str += " Content Type: \(contentType ?? "Not set")\n"
        if cookies.count == 0 {
            str += " Cookies: None\n"
        } else {
            str += " Cookies:\n"
            cookies.forEach({ str += "  \($0)\n" })
        }
        str += " Server: \(server ?? "Not set")\n"
        str += " Payload: \(payload?.count ?? 0) bytes"
        return str
    }
}

