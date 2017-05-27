// =====================================================================================================================
//
//  File:       HttpRequest.swift
//  Project:    Swiftfire
//
//  Version:    0.10.9
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
// 0.10.9 - HTTP code streamlining (merged HttpRequestField and HttpOperation)
// 0.10.7 - Added decoding of contentType
//        - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Added cookies
//        - Renamed from HttpHeader to HttpRequest
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.9  - Replaced header logging code by Logfile usage
// 0.9.7  - Added header logging
// 0.9.6  - Header update
// 0.9.0  - Initial release
// =====================================================================================================================

import Foundation
import Ascii


// The normal line endings

public let CRLF = "\r\n"


// The ending of the header

public let CRLFCRLF = "\r\n\r\n"


/// This class encodes the http request and offers functions to access its content.

public final class HttpRequest: CustomStringConvertible {
    
    
    // The types of available operations
    
    public enum Operation: String {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case trace = "TRACE"
        case connect = "CONNECT"
        
        // If operations are added, be sure to include them in "allValues".
        
        public static let all: Array<Operation> = [.get, .head, .post, .put, .delete, .trace, .connect]
    }

    
    /// This enum encodes the different kinds of header fields
    
    public enum Field: String {
        
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

    
    /// The end-of-header sequence
    
    public static let endOfHeaderSequence = Data(bytes: [Ascii._CR, Ascii._LF, Ascii._CR, Ascii._LF])
    
    
    /// The lines in the header
    
    public let lines: [String]
    
    
    /// The unprocessed lines, initially this is the same as 'lines' but as the header is decoded the processed lines are removed from this array.
    
    public private(set) var unprocessedLines: [String]
    
    
    /// The number of bytes in the header (including the CRLFCRLF)
    
    public let headerLength: Int
    
    
    /// The payload (if there is any)
    
    public var payload: Data?
    
    
    /// - Note: The headerLength is not used internally, its just a place to keep this information handy - if necessary.
    
    public init(lines: [String], headerLength: Int) {
        self.lines = lines
        self.unprocessedLines = lines
        if lines.count > 1 {
            self.unprocessedLines.removeFirst()
        }
        self.headerLength = headerLength
    }
    
    
    /// Returns a HTTP header from the given data if the data contains a complete header. Otherwise returns nil.
    
    public convenience init?(data: Data) {
        
        // Check if the header is complete by searching for the end of the CRLFCRLF sequence
        guard let endOfHeaderRange = data.range(of: HttpRequest.endOfHeaderSequence) else { return nil }
        
        // Convert the header to lines
        let headerRange = Range(uncheckedBounds: (lower: 0, upper: endOfHeaderRange.lowerBound))
        guard let headerString = String(data: data.subdata(in: headerRange), encoding: String.Encoding.utf8) else {
            return nil
        }
        let headerLines = headerString.components(separatedBy: CRLF)
        
        // Set the headerlength
        let length = endOfHeaderRange.upperBound
        
        self.init(lines: headerLines, headerLength: length)
    }
    
    
    // Create and return a copy from self
    
    public var copy: HttpRequest {
        let cp = HttpRequest(lines: self.lines, headerLength: self.headerLength)
        cp.payload = self.payload
        // Don't copy the lazy variables, they will be recreated when necessary.
        return cp
    }
    
    
    /// - Returns: The header as a Data object containing the lines as an UTF8 encoded string separated by CRLF en closed by a CRLFCRLF sequence. Nil if the lines could not be encoded as an UTF8 coding.
    
    public func asData() -> Data? {
        var str = ""
        for line in lines {
            str += line + CRLF
        }
        str += CRLF
        return str.data(using: String.Encoding.utf8)
    }
    
    
    /// Returns all the lines in the header.
    
    public var description: String {
        return lines.reduce("") { $0 + "\($1)\n" }
    }
        
    
    /// Decodes form data from the given string
    
    public static func decodeUrlEncodedFormData(_ str: String) -> Dictionary<String, String>? {
        
        var dict: Dictionary<String, String> = [:]
        
        var nameValuePairs = str.components(separatedBy: "&")
        
        while nameValuePairs.count > 0 {
            var nameValue = nameValuePairs[0].components(separatedBy: "=")
            switch nameValue.count {
            case 0: break // error, don't do anything
            case 1: dict[nameValue[0]] = ""
            case 2: dict[nameValue[0]] = nameValue[1]
            default:
                let name = nameValue.removeFirst()
                dict[name] = nameValue.joined(separator: "=")
            }
        }
        
        
        // Add the get dictionary to the service info
        
        if dict.count > 0 { return dict } else { return nil }

    }
    
    
    /// Returns the operation or nil if none present
    
    public lazy var operation: Operation? = {
        for t in Operation.all {
            let operatorRange = self.lines[0].range(of: t.rawValue, options: NSString.CompareOptions(), range: nil, locale: nil)
            if let range = operatorRange {
                if range.lowerBound == self.lines[0].startIndex { return t }
            }
        }
        return nil
    }()
    
    
    /// Returns the URL or nil if none present

    public lazy var url: String? = {
    
        
        // The first line should in 3 parts: Operation, url and version
        
        let parts = self.lines[0].components(separatedBy: " ")
        
        if parts.count == 3 { return parts[1] }
        
        return nil
    }()
    
    
    /// Returns the version of the http header or nil if it cannot be found
    
    public lazy var httpVersion: HttpVersion? = {
        
        
        // The first line should in 3 parts: Operation, url and version

        let parts = self.lines[0].components(separatedBy: " ")
        
        if parts.count == 3 {
            
            
            // The last part should be equal to the raw value of a HttpVersion enum
            
            for version in HttpVersion.all {
                
                if let range = parts[2].range(
                    of: version.rawValue,
                    options: NSString.CompareOptions.caseInsensitive,
                    range: nil,
                    locale: nil) {
                    
                    if range.lowerBound == self.lines[0].startIndex { return version }
                }
            }
        }

        return nil
    }()
    
    
    /// Returns the content type (mime type) of the request
    
    public lazy var contentType: String? = {
        
        for (index, line) in self.unprocessedLines.enumerated() {
            
            if let str = HttpRequest.Field.contentType.getFieldValue(from: line) {
                
                self.unprocessedLines.remove(at: index)
                
                return str
            }
        }
        
        return nil
 
    }()
    
    
    /// Return the length of the body content or 0 if no length field is found
    
    public lazy var contentLength: Int = {
        
        for (index, line) in self.unprocessedLines.enumerated() {
            
            if let str = HttpRequest.Field.contentLength.getFieldValue(from: line) {

                self.unprocessedLines.remove(at: index)
                
                if let val = Int(str) { return val }
            }
        }
        
        return 0
    }()
    
    
    /// Returns true if the connection must be kept alive, false otherwise.
    /// - Note: Defaults to 'false' if the Connection field is not present.
    
    public lazy var connectionKeepAlive: Bool = {
        
        for (index, line) in self.unprocessedLines.enumerated() {
            
            if let str = HttpRequest.Field.connection.getFieldValue(from: line) {
                
                self.unprocessedLines.remove(at: index)
                
                if str.caseInsensitiveCompare("keep-alive") == ComparisonResult.orderedSame {
                    return true;
                } else {
                    return false;
                }
            }
        }
        
        return false
    }()
    
    
    /// Returns the host in the header, note that HTTP 1.0 requests do not have a host field.
    
    public lazy var host: HttpHost? = {
       
        for (index, line) in self.unprocessedLines.enumerated() {
            
            if let val = HttpRequest.Field.host.getFieldValue(from: line) {
                                
                let values = val.components(separatedBy: ":")
                
                if values.count == 0 { return nil }
                
                if values.count == 1 {
                    self.unprocessedLines.remove(at: index)
                    return HttpHost(address: values[0], port: nil)
                }
                
                if values.count == 2 {
                    self.unprocessedLines.remove(at: index)
                    return HttpHost(address: values[0], port: values[1])
                }
                
                return nil
            }
        }

        return nil
    }()
    
    
    /// Returns all cookies present in the header.
    
    public lazy var cookies: Array<HttpCookie> = {
        
        var arr: Array<HttpCookie> = []
        
        for (index, line) in self.unprocessedLines.enumerated() {
            
            let cookies = HttpCookie.factory(string: line)
            
            if cookies.count > 0 {
                self.unprocessedLines.remove(at: index)
                arr.append(contentsOf: cookies)
            }
        }
        
        return arr
    }()
}
