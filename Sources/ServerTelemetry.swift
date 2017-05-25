// =====================================================================================================================
//
//  File:       Telemetry.swift
//  Project:    Swiftfire
//
private let version = "0.10.8"
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
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
// 0.10.8 - Version number update
// 0.10.7 - Version number update
//        - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Renamed from Telemetry to ServerTelemetry
//        - Added ServerTelemetryName
// 0.9.18 - Added http and https server status
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Updated description for nofHttp400Replies
//        - Added nofHttp500Replies
//        - Renamed to Telemetry
//        - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Moved global definition from main.swift to here.
// 0.9.6  - Header update
// 0.9.3  - Renamed from Telemetry to ServerTelemetry
//        - Moved domain related telemetry to DomainTelemetry
//        - Moved TelemetryProtocol to its own file
//        - Moved UIntTelemetry to its own file
//        - Removed singleton limitation and definition
// 0.9.0  - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import BRUtils


public final class ServerTelemetry: CustomStringConvertible, VJsonConvertible {
    
    
    /// The version number of the server & console software
    
    public var serverVersion = NamedStringValue(
        name: "ServerVersion",
        about: "The version number of the server & console",
        value: version,
        resetValue: version)
    
    
    /// The status of the HTTP server
    
    public var httpServerStatus = NamedStringValue(
        name: "HttpServerStatus",
        about: "The status of the HTTP server.",
        value: "Not set",
        resetValue: "Not set")
    
    
    /// The status of the HTTPS server
    
    public var httpsServerStatus = NamedStringValue(
        name: "HttpsServerStatus",
        about: "The status of the HTTPS server.",
        value: "Not set",
        resetValue: "Not set")
    
    
    /// Counts the number of times an accept had to wait for a free connection object. Wraps around at 999_999.
    ///
    /// This is 'for info' only. It does not indicate a serious error. Simply monitor this value, it should ideally stay at zero. For each time it increases it means that one or more client(s) had to wait for 1 second. If this is incremented often, it may be advantageous to increase the number of connection objects. However keep in mind that when more connection objects are available, there will be more requests executing in parallel and other bottlenecks may occur.
    
    public let nofAcceptWaitsForConnectionObject = NamedIntValue(
        name: "NofAcceptWaitsForConnectionObject",
        about: "The number of times a connection object wasn't available.",
        value: 0,
        resetValue: 0)

    
    /// The number of accepted HTTP requests. Wraps around at 999_999.
    ///
    /// For information only.
    
    public let nofAcceptedHttpRequests = NamedIntValue(
        name: "NofAcceptedHttpRequests",
        about: "The number of accepted HTTP requests.",
        value: 0,
        resetValue: 0)
    
    
    /// The number of bad HTTP requests. Wraps around at 999_999.
    ///
    /// It is incremented in HttpConnection.HttpWorker when a request cannot be mapped to a (hosted) domain or when no HTTP version is present in the request. Check the logfile and see why the domain could not be mapped. If necessary enable the domain or fix/add a domain.
    
    public let nofHttp400Replies = NamedIntValue(
        name: "NofHttp400Replies",
        about: "The number of HTTP response code 400 at the server wide level.",
        value: 0,
        resetValue: 0)
    
    
    /// The number of "Server Error" replies for HTTP 1.0 requests. Wraps around at 999_999.
    ///
    /// The parameter "http1_0DomainName" does not refer to an existing domain specification. Update the parameter or add the domain specification.
    
    public let nofHttp500Replies = NamedIntValue(
        name: "NofHttp500Replies",
        about: "The number of HTTP response code 500 at the server wide level.",
        value: 0,
        resetValue: 0)
    
    
    /// The VJson representation
    
    public var json: VJson {
        let json = VJson()
        all.forEach({ json[$0.name] &= $0.stringValue })
        return json
    }
    
    
    /// A collection of all items
    
    public let all: Array<NamedValueProtocol>
    
    
    /// Make it available
    
    public init() {
        all = [serverVersion, httpServerStatus, httpsServerStatus, nofAcceptWaitsForConnectionObject, nofAcceptedHttpRequests, nofHttp400Replies, nofHttp500Replies]
    }
    
    
    /// Create from JSON
    
    public convenience init?(json: VJson?) {
        guard let json = json else { return nil }
        self.init()
        for item in all {
            if let strval = (json|item.name)?.stringValue {
                if item.setValue(strval) {
                    json.remove(child: (json|item.name)!)
                } else {
                    SwifterLog.atError?.log(id: -1, source: #file.source(#function, #line), message: "Failed to set value for \(item.name) to \(strval)")
                }
            } else {
                SwifterLog.atError?.log(id: -1, source: #file.source(#function, #line), message: "Missing value for \(item.name)")
            }
        }
        if json.nofChildren != 0 {
            SwifterLog.atError?.log(id: -1, source: #file.source(#function, #line), message: "Superfluous items in source: \(json.code)")
            return nil
        }
    }
    
    
    /// Reset all Telemetry
    
    public func reset() {
        all.forEach({ $0.reset() })
    }
    
    
    /// CustomStringConvertible
    
    public var description: String {
        var str = "ServerTelemetry:\n"
        str += all.map({" \($0.name): \($0.stringValue)"}).joined(separator: "\n")
        return str
    }
}
