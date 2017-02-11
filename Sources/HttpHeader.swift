// =====================================================================================================================
//
//  File:       HttpHeader.swift
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
// v0.9.15 - General update and switch to frameworks
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.9  - Replaced header logging code by Logfile usage
// v0.9.7  - Added header logging
// v0.9.6  - Header update
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation
import Ascii
import SwifterLog


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = "HttpHeader"


/// This enum encodes the different kinds of operations

enum HttpOperation: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case trace = "TRACE"
    case connect = "CONNECT"
    
    // If operations are added, be sure to include them in "allValues".
    
    static let all: Array<HttpOperation> = [.get, .head, .post, .put, .delete, .trace, .connect]
}


/// This enum encodes the different versions of the HTTP protocol

enum HttpVersion: String {
    case http1_0 = "HTTP/1.0"
    case http1_1 = "HTTP/1.1"
    case http1_x = "HTTP/1.x"
    
    // If operations are added, be sure to include them in "allValues".
    
    static let all: Array<HttpVersion> = [.http1_0, .http1_1, .http1_x]
}


/// This enum encodes the different kinds of header fields

enum HttpHeaderField: String {
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
}


// The normal line endings

let CRLF = "\r\n"


// The ending of the header

let CRLFCRLF = "\r\n\r\n"


// Returns the string after the ':' sign of the request field, without leading blanks
// Returns nil if the requested field is not present

private func getRequestFieldValue(request: HttpHeaderField, inLine line: String) -> String? {
    
    
    // Split the string in request and value
    
    var subStrings = line.components(separatedBy: ":")
    
    
    // The count of the array must be 2 or more, otherwise there is something wrong
    
    if subStrings.count < 2 { return nil }
    
    
    // The first string should be equal to the request field raw value
    
    if subStrings[0].compare(request.rawValue, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != ComparisonResult.orderedSame { return nil }
    
    
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


/// This class encodes the http request header and offers functions to access its content.

final class HttpHeader {
    
    
    // The end-of-header sequence
    
    static let endOfHeaderSequence = Data(bytes: [Ascii._CR, Ascii._LF, Ascii._CR, Ascii._LF])
    
    
    // The lines in the header
    
    private var lines: [String]
    
    
    /// The number of bytes in the header (including the CRLFCRLF)
    
    let headerLength: Int
    
    
    /// - Note: The headerLength is not used internally, its just a place to keep this information handy - if necessary.
    
    init(lines: [String], headerLength: Int) {
        self.lines = lines
        self.headerLength = headerLength
    }
    
    
    /// Returns a HTTP header from the given data if the data contains a complete header. Otherwise returns nil.
    
    init?(data: Data) {
        
        // Check if the header is complete by searching for the end of the CRLFCRLF sequence
        guard let endOfHeaderRange = data.range(of: HttpHeader.endOfHeaderSequence) else { return nil }
        
        // Convert the header to lines
        let headerRange = Range(uncheckedBounds: (lower: 0, upper: endOfHeaderRange.lowerBound))
        guard let headerString = String(data: data.subdata(in: headerRange), encoding: String.Encoding.utf8) else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Cannot create string from received data")
            return nil
        }
        lines = headerString.components(separatedBy: CRLF)
        
        // Set the headerlength
        headerLength = endOfHeaderRange.upperBound
    }
    
    
    // Create and return a copy from self
    
    var copy: HttpHeader {
        let cp = HttpHeader(lines: self.lines, headerLength: self.headerLength)
        // Don't copy the lazy variables, they will be recreated when necessary.
        return cp
    }
    
    
    /// - Returns: The header as a Data object containing the lines as an UTF8 encoded string separated by CRLF en closed by a CRLFCRLF sequence. Nil if the lines could not be encoded as an UTF8 coding.
    
    func asData() -> Data? {
        var str = ""
        for line in lines {
            str += line + CRLF
        }
        str += CRLF
        return str.data(using: String.Encoding.utf8)
    }
    
    
    /// Writes the lines in the header to the logger at level DEBUG.
    
    func writeToDebugLog(logId: Int32) {
        var i = 0
        for line in lines {
            let message = "Line " + i.description + ": " + line
            log.atLevelDebug(id: logId, source: SOURCE + ".writeToDebugLog", message: message)
            i += 1
        }
    }
    
    
    /// Returns the operation or nil if none present
    
    lazy var operation: HttpOperation? = {
        for t in HttpOperation.all {
            let operatorRange = self.lines[0].range(of: t.rawValue, options: NSString.CompareOptions(), range: nil, locale: nil)
            if let range = operatorRange {
                if range.lowerBound == self.lines[0].startIndex { return t }
            }
        }
        return nil
    }()
    
    
    /// Returns the URL or nil if none present
    
    var url: String? {
        get {
            return _url
        }
        set {
            _url = newValue
            
            var parts = self.lines[0].components(separatedBy: " ")
            
            if parts.count == 3 {
                parts[1] = newValue ?? ""
                lines[0] = parts[0] + " " + parts[1] + " " + parts[2]
            }
        }
    }
    
    private lazy var _url: String? = {
    
        
        // The first line should in 3 parts: Operation, url and version
        
        let parts = self.lines[0].components(separatedBy: " ")
        
        if parts.count == 3 { return parts[1] }
        
        return nil
    }()
    
    
    /// Returns the version of the http header or nil if it cannot be found
    
    lazy var httpVersion: HttpVersion? = {
        
        
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
    
    
    /// Return the length of the body content or 0 if no length field is found
    
    lazy var contentLength: Int = {
        
        for line in self.lines {
            
            if let str = getRequestFieldValue(request: HttpHeaderField.contentLength, inLine: line) {
                
                if let val = Int(str) {
                    
                    return val }
            }
        }
        
        return 0
    }()
    
    
    /// - Returns: True if the connection must be kept alive, false otherwise.
    /// - Note: Defaults to 'false' if the Connection field is not present.
    
    lazy var connectionKeepAlive: Bool = {
        
        for line in self.lines {
            
            if let str = getRequestFieldValue(request: HttpHeaderField.connection, inLine: line) {
                
                if (str as NSString).compare("keep-alive", options: NSString.CompareOptions.caseInsensitive) == ComparisonResult.orderedSame {
                    return true;
                } else {
                    return false;
                }
            }
        }
        
        return false
    }()
    
    
    /// - Returns: The host field components if available, nil otherwise.
    /// - Note: If the port is not specified, this component is set to 'nil'.
    
    var host: Host? {
        get {
            return _host
        }
        set {
            _host = newValue
            
            for (i, line) in lines.enumerated() {
                
                var subStrings = line.components(separatedBy: ":")
                
                if subStrings[0].compare(HttpHeaderField.host.rawValue, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) == ComparisonResult.orderedSame {
                    
                    lines[i] = HttpHeaderField.host.rawValue + ": " + (newValue?.description ?? "")
                    
                    break
                }
            }
        }
    }
    private lazy var _host: Host? = {
       
        for line in self.lines {
            
            if let val = getRequestFieldValue(request: HttpHeaderField.host, inLine: line) {
                                
                let values = val.components(separatedBy: ":")
                
                if values.count == 0 { return nil }
                
                if values.count == 1 { return Host(address: values[0], port: nil) }
                
                if values.count == 2 { return Host(address: values[0], port: values[1]) }
                
                return nil
            }
        }

        return nil
    }()
    
    
    // MARK: Header logging
    
    private static var headerLogFile = Logfile(filename: "HeaderLog", fileExtension: "txt", directory: FileURLs.headerLoggingDir, options: .newFileDailyAt(WallclockTime(hour: 0, minute: 0, second: 0)), .maxFileSize(parameters.maxFileSizeForHeaderLogging))

    static func closeHeaderLoggingFile() {
        if let file = self.headerLogFile {
            file.close()
            self.headerLogFile = nil
        }
    }
    
    func record(connection: HttpConnection) {
        
        if let file = HttpHeader.headerLogFile {
            
            var message = "--------------------------------------------------------------------------------\n"
            message += "Time      : \(Logfile.dateFormatter.string(from: connection.timeOfAccept as Date))\n"
            message += "IP Address: \(connection.remoteAddress)\n"
            message += "Log Id    : \(connection.logId)\n\n"
            message = self.lines.reduce(message) { $0 + $1 + "\n" }
            message += "\n"
            
            file.record(message: message)
            if parameters.flushHeaderLogfileAfterEachWrite { file.flush() }
        }
    }
}
