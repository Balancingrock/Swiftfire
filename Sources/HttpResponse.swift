// =====================================================================================================================
//
//  File:       HttpResponse.swift
//  Project:    Swiftfire
//
//  Version:    0.9.15
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
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
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
// v0.9.15 - General update and switch to frameworks, initial release.
// =====================================================================================================================

import Foundation

final class HttpResponse {
    
    /**
     Builds a buffer with a HTTP error response in it. The response will contain an error code, and can contain a specified error message as well.
     
     - Parameter code: The HTTP Response Code to be included in the header.
     - Parameter message: The HTML code to be included as visible message to the client. Note that any text should be enclosed in (at a minimum) a paragraph (<p>...</p>).
     
     - Returns: The buffer with the response.
     
     - Note: If the message contains characters that cannot be converted to an UTF8 string, then the response will not contain any visible data.
     */
    
    static func withCode(_ code: HttpResponseCode, version: HttpVersion, message: String? = nil) -> Data {
        
        let message = message ?? "HTTP Request rejected with: \(code.rawValue)"
        
        let body =
            "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">" + CRLF +
                "<html><head><title>\(code.rawValue)</title></head>" + CRLF +
                "<body>\(message)</body></html>" + CRLF
        
        let bodyData = body.data(using: String.Encoding.utf8, allowLossyConversion: true) ?? Data()
        
        let response = HttpResponse.withCode(code, version: version, mimeType: mimeTypeHtml, body: bodyData)
        
        return response
    }
    
    
    /**
     Builds a buffer with a HTTP response.
     
     - Parameter code: The code to be used in the header.
     - Parameter andBody: The body to be included.
     
     - Return: A buffer with the response.
     */
    
    static func withCode(_ code: HttpResponseCode, version: HttpVersion, mimeType: String, body: Data) -> Data {
        
        let header = "\(version.rawValue) \(code.rawValue)" + CRLF +
            "Date: \(Date())" + CRLF +
            "Server: Swiftfire/\(parameters.version)" + CRLF +
            "Content-Type: \(mimeType); charset=UTF-8" + CRLF +
            "Content-Length: \(body.count)" + CRLFCRLF
        
        var headerData = header.data(using: String.Encoding.utf8)!
        headerData.append(body)
        
        return headerData
    }
}
