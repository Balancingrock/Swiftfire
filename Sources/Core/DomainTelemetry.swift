// =====================================================================================================================
//
//  File:       DomainTelemetry.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
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


/// Telemetry items associated with a single domain.

public final class DomainTelemetry {
    
    
    /// The total number of requests processed. Includes error replies, but excludes forwarding.
    
    public let nofRequests = NamedIntValue(
        name: "Nof Requests:",
        about: "The total number of requests",
        value: 0,
        resetValue: 0)
    
    
    /// The total number of blacklisted accesses
    
    public let nofBlacklistedAccesses = NamedIntValue(
        name: "Nof Blacklisted Accesses:",
        about: "The number of access by blacklisted clients",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 200 (Successfull reply)
    
    public let nof200 = NamedIntValue(
        name: "Nof code 200:",
        about: "The number of code 200 (successful) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 400 (Bad Request)
    
    public let nof400 = NamedIntValue(
        name: "Nof code 400:",
        about: "The number of code 400 (Bad Request) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 403 (Forbidden)
    
    public let nof403 = NamedIntValue(
        name: "Nof code 403:",
        about: "The number of code 403 (Forbidden) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 404 (File/Resource Not Found)
    
    public let nof404 = NamedIntValue(
        name: "Nof code 404:",
        about: "The number of code 404 (Not found) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 500 (Server Error)
    
    public let nof500 = NamedIntValue(
        name: "Nof code 500:",
        about: "The number of code 500 (Server error) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 501 (Not Implemented)
    
    public let nof501 = NamedIntValue(
        name: "Nof code 501:",
        about: "The number of code 501 (Not implemented) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 505 (HTTP version not supported)
    
    public let nof505 = NamedIntValue(
        name: "Nof code 505:",
        about: "The number of code 505 (Version not supported) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The array with all domain telemetry items
    
    public let all: Array<NamedIntValue>
    

    /// Allow default initializer
    
    public init() {
        all = [nofRequests, nofBlacklistedAccesses, nof200, nof400, nof403, nof404, nof500, nof501, nof505]
    }
}


// MARK: - Functional Interface

extension DomainTelemetry {
    
    
    /// Reset all telemetry values to their default value.
    
    func reset() { all.forEach({ $0.reset() }) }
    
    
    /// Store all telemetry values to file in the JSON format.
    
    public func store(to dir: URL?) {
        
        guard let file = timestampedFileUrl(dir: dir, name: "telemetry", ext: "json") else { return }
        
        Log.atNotice?.log("Storing domain telemetry to \(file.path)")
        
        let json = VJson.object()
        all.forEach { json[$0.name] &= $0.value }
        _ = json.save(to: file)
    }
}


// MARK: - Auxillary

extension DomainTelemetry {
    
    
    /// - Returns: A string represenattion of this object.
    
    public var description: String {
        var str = ""
        str += all.map({ " \($0.name): \($0.value)" }).joined(separator: "\n")
        return str
    }
}
