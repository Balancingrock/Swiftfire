// =====================================================================================================================
//
//  File:       Telemetry.swift
//  Project:    Swiftfire
//
private let version = "1.0.0b"
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2019 Marinus van der Lugt, All rights reserved.
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
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import VJson
import SwifterLog


public final class ServerTelemetry {
    
    
    /// The version number of the server & console software
    
    public let serverVersion = NamedStringValue(
        name: "ServerVersion",
        about: "The version number of the server & console",
        value: version,
        resetValue: version)
    
    
    /// The status of the HTTP server
    
    public let httpServerStatus = NamedStringValue(
        name: "HttpServerStatus",
        about: "The status of the HTTP server.",
        value: "Not set",
        resetValue: "Not set")
    
    
    /// The status of the HTTPS server
    
    public let httpsServerStatus = NamedStringValue(
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
    
    
    /// A collection of all items
    
    public let all: Array<NamedValueProtocol>
    
    
    /// Make it available
    
    public init() {
        all = [serverVersion, httpServerStatus, httpsServerStatus, nofAcceptWaitsForConnectionObject, nofAcceptedHttpRequests, nofHttp400Replies, nofHttp500Replies]
    }
}


// MARK: - Operational interface

extension ServerTelemetry {
    
    /// Reset all Telemetry
    
    public func reset() {
        all.forEach({ $0.reset() })
    }
}


// MARK: - VJsonConvertible

extension ServerTelemetry: VJsonConvertible {
    
    
    public convenience init?(json: VJson?) {
        guard let json = json else { return nil }
        self.init()
        for item in all {
            if let strval = (json|item.name)?.stringValue {
                if item.setValue(strval) {
                    _ = json.removeChild((json|item.name)!)
                } else {
                    Log.atError?.log("Failed to set value for \(item.name) to \(strval)")
                }
            } else {
                Log.atError?.log("Missing value for \(item.name)")
            }
        }
        if json.nofChildren != 0 {
            Log.atError?.log("Superfluous items in source: \(json.code)")
            return nil
        }
    }

    
    public var json: VJson {
        let json = VJson()
        all.forEach({ json[$0.name] &= $0.stringValue })
        return json
    }
}


// MARK: - CustomStringConvertible

extension ServerTelemetry: CustomStringConvertible {
    
    public var description: String {
        var str = "ServerTelemetry:\n"
        str += all.map({" \($0.name): \($0.stringValue)"}).joined(separator: "\n")
        return str
    }
}
