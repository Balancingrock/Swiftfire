// =====================================================================================================================
//
//  File:       HttpHeader.swift
//  Project:    Swiftfire
//
//  Version:    0.9.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// v0.9.7 - Added header logging
// v0.9.6 - Header update
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation


// For logging purposes, identifies the module which created the logging entry.

private let SOURCE = "HttpHeader"


/// This enum encodes the different kinds of operations

enum HttpOperation: String {
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
    
    // If operations are added, be sure to include them in "allValues".
    
    static let allValues = [HttpOperation.GET, HttpOperation.HEAD, HttpOperation.POST, HttpOperation.PUT, HttpOperation.DELETE, HttpOperation.TRACE, HttpOperation.CONNECT]
}


/// This enum encodes the different versions of the HTTP protocol

enum HttpVersion: String {
    case HTTP_1_0 = "HTTP/1.0"
    case HTTP_1_1 = "HTTP/1.1"
    case HTTP_1_x = "HTTP/1.x"
    
    // If operations are added, be sure to include them in "allValues".
    
    static let allValues = [HttpVersion.HTTP_1_0, HttpVersion.HTTP_1_1, HttpVersion.HTTP_1_x]
}


/// This enum encodes the different kinds of header fields

enum HttpHeaderField: String {
    case ACCEPT                 = "Accept"
    case ACCEPT_CHARSET         = "Accept-Charset"
    case ACCEPT_ENCODING        = "Accept-Encoding"
    case ACCEPT_LANGUAGE        = "Accept-Language"
    case ACCEPT_DATETIME        = "Accept-Datetime"
    case CACHE_CONTROL          = "Cache-Control"
    case CONNECTION             = "Connection"
    case COOKIE                 = "Cookie"
    case CONTENT_LENGTH         = "Content-Length"
    case CONTENT_MD5            = "Content-MD5"
    case CONTENT_TYPE           = "Content-Type"
    case DATE                   = "Date"
    case EXPECT                 = "Expect"
    case FROM                   = "From"
    case HOST                   = "Host"
    case IF_MATCH               = "If-Match"
    case IF_MODIFIED_SINCE      = "If-Modified-Since"
    case IF_NONE_MATCH          = "If-None-Match"
    case IF_RANGE               = "If-Range"
    case IF_UNMODIFIED_SINCE    = "If-Unmodified-Since"
    case MAX_FORWARDS           = "Max-Forwards"
    case ORIGIN                 = "Origin"
    case PRAGMA                 = "Pragma"
    case PROXY_AUTHORIZATION    = "Proxy-Authorization"
    case RANGE                  = "Range"
    case REFERER                = "Referer"
    case TE                     = "TE"
    case USER_AGENT             = "User-Agent"
    case UPGRADE                = "Upgrade"
    case WARNING                = "Warning"
}


// The normal line endings

let CRLF = "\r\n"


// The ending of the header

let CRLFCRLF = "\r\n\r\n"


// Returns the string after the ':' sign of the request field, without leading blanks
// Returns nil if the requested field is not present

private func getRequestFieldValue(request: HttpHeaderField, inLine line: String) -> String? {
    
    
    // Split the string in request and value
    
    var subStrings = line.componentsSeparatedByString(":")
    
    
    // The count of the array must be 2 or more, otherwise there is something wrong
    
    if subStrings.count < 2 { return nil }
    
    
    // The first string should be equal to the request field raw value
    
    if subStrings[0].compare(request.rawValue, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != NSComparisonResult.OrderedSame { return nil }
    
    
    // Remove the raw field value
    
    subStrings.removeFirst()
    
    
    // Assemble the rest of the string value again
    
    var strValue = ""
    
    for (i, str) in subStrings.enumerate() {
        strValue += str
        if i < (subStrings.count - 1) { strValue += ":" }
    }
    
    
    // Strip leading and trailing blanks
    
    return strValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
}


/// This class encodes the http request header and offers functions to access its content.

final class HttpHeader {
    
    
    // The lines in the header
    
    private var lines: [String]
    
    
    // Used to instantiate an object
    
    init(lines: [String]) {
        self.lines = lines
    }
    
    
    // Create and return a copy from self
    
    var copy: HttpHeader {
        let cp = HttpHeader(lines: self.lines)
        // Don't copy the lazy variables, they will be recreated when necessary.
        return cp
    }
    
    
    /// - Returns: The header as a UInt8Buffer object containing the lines as an UTF8 encoded string separated by CRLF en closed by a CRLFCRLF sequence. Nil if the lines could not be encoded as an UTF8 coding.
    
    func asUInt8Buffer() -> UInt8Buffer? {
        var str = ""
        for line in lines {
            str += line + CRLF
        }
        str += CRLF
        return UInt8Buffer(buffers: str.dataUsingEncoding(NSUTF8StringEncoding))
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
        for t in HttpOperation.allValues {
            let operatorRange = self.lines[0].rangeOfString(t.rawValue, options: NSStringCompareOptions(), range: nil, locale: nil)
            if let range = operatorRange {
                if range.startIndex == self.lines[0].startIndex { return t }
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
            
            var parts = self.lines[0].componentsSeparatedByString(" ")
            
            if parts.count == 3 {
                parts[1] = newValue ?? ""
                lines[0] = parts[0] + " " + parts[1] + " " + parts[2]
            }
        }
    }
    
    private lazy var _url: String? = {
    
        
        // The first line should in 3 parts: Operation, url and version
        
        let parts = self.lines[0].componentsSeparatedByString(" ")
        
        if parts.count == 3 { return parts[1] }
        
        return nil
    }()
    
    
    /// Returns the version of the http header or nil if it cannot be found
    
    lazy var httpVersion: HttpVersion? = {
        
        
        // The first line should in 3 parts: Operation, url and version

        let parts = self.lines[0].componentsSeparatedByString(" ")
        
        if parts.count == 3 {
            
            
            // The last part should be equal to the raw value of a HttpVersion enum
            
            for version in HttpVersion.allValues {
                
                if let range = parts[2].rangeOfString(
                    version.rawValue,
                    options: NSStringCompareOptions.CaseInsensitiveSearch,
                    range: nil,
                    locale: nil) {
                    
                    if range.startIndex == self.lines[0].startIndex { return version }
                }
            }
        }

        return nil
    }()
    
    
    /// Return the length of the body content or 0 if no length field is found
    
    lazy var contentLength: Int = {
        
        for line in self.lines {
            
            if let str = getRequestFieldValue(HttpHeaderField.CONTENT_LENGTH, inLine: line) {
                
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
            
            if let str = getRequestFieldValue(HttpHeaderField.CONNECTION, inLine: line) {
                
                if (str as NSString).compare("keep-alive", options: NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedSame {
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
            
            for (i, line) in lines.enumerate() {
                
                var subStrings = line.componentsSeparatedByString(":")
                
                if subStrings[0].compare(HttpHeaderField.HOST.rawValue, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) == NSComparisonResult.OrderedSame {
                    
                    lines[i] = HttpHeaderField.HOST.rawValue + ": " + (newValue?.description ?? "")
                    
                    break
                }
            }
        }
    }
    private lazy var _host: Host? = {
       
        for line in self.lines {
            
            if let val = getRequestFieldValue(HttpHeaderField.HOST, inLine: line) {
                                
                let values = val.componentsSeparatedByString(":")
                
                if values.count == 0 { return nil }
                
                if values.count == 1 { return Host(address: values[0], port: nil) }
                
                if values.count == 2 { return Host(address: values[0], port: values[1]) }
                
                return nil
            }
        }

        return nil
    }()
    
    
    // MARK: Storage for header logging
    
    private static let headerLoggingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    
    private static var _headerLoggingFileHandle: NSFileHandle?
    
    private static let dailyTask = TimedClosure(queue: HttpHeader.headerLoggingQueue, wallclockTime: WallclockTime(hour:0, minute:0, second:0), closure: {
        dispatch_async(HttpHeader.headerLoggingQueue, { HttpHeader.closeHeaderLoggingFile() }) // Close file, a new one will be created on demand
    })
}


// MARK: - Header Logging

extension HttpHeader {
    
    private static var headerLoggingDateFormatter: NSDateFormatter = {
        let ltf = NSDateFormatter()
        ltf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return ltf
    }()
    
    
    // This will create a new filename based on the current time.
    
    private static var filename: String {
        return "HeaderLog_" + HttpHeader.headerLoggingDateFormatter.stringFromDate(NSDate()) + ".txt"
    }
    
    
    // This wil create a new file URL based on the current time
    
    private static var fileUrl: NSURL? {
        guard let dirUrl = FileURLs.headerLoggingDir else { return nil }
        return dirUrl.URLByAppendingPathComponent(HttpHeader.filename)
    }
    
    
    // Returns the current file handle if there is one, creates a new one if necessary.
    
    private static var handle: NSFileHandle? {
        
        if _headerLoggingFileHandle == nil {
            
            // Create the file
            if let fileUrl = HttpHeader.fileUrl {
                
                if NSFileManager.defaultManager().createFileAtPath(fileUrl.path!, contents: nil, attributes: [NSFilePosixPermissions : NSNumber(int: 0o640)]) {
                    _headerLoggingFileHandle = NSFileHandle(forUpdatingAtPath: fileUrl.path!)
                } else {
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not generate header logfile at: \(fileUrl.path!)")
                    _headerLoggingFileHandle = nil
                }
                
            } else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not retrieve header logfile fileUrl")
                _headerLoggingFileHandle = nil
            }
        }
        return _headerLoggingFileHandle
    }
    
    
    static func closeHeaderLoggingFile() {
        if let file = self._headerLoggingFileHandle {
            file.closeFile()
            self._headerLoggingFileHandle = nil
        }
    }

    
    func record(connection: HttpConnection) {
        
        // Do everything on the queue to prevent threading errors
        
        dispatch_async(HttpHeader.headerLoggingQueue, {
            
            if let file = HttpHeader.handle {
                if file.seekToEndOfFile() > UInt64(Parameters.asInt(.MAX_FILE_SIZE_FOR_HEADER_LOGGING) * 1024) {
                    HttpHeader.closeHeaderLoggingFile()
                }
            }
            
            if let file = HttpHeader.handle {
                
                var message = "--------------------------------------------------------------------------------\n"
                message += "Time      : \(HttpHeader.headerLoggingDateFormatter.stringFromDate(connection.timeOfAccept))\n"
                message += "IP Address: \(connection.clientIp)\n"
                message += "Log Id    : \(connection.logId)\n\n"
                message = self.lines.reduce(message, combine: { $0 + $1 + "\n"})
                message += "\n"
                
                if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                    file.writeData(data)
                    if Parameters.asBool(.FLUSH_HEADER_LOGFILE_AFTER_EACH_WRITE) { file.synchronizeFile() }
                }
            }
            })
    }
}