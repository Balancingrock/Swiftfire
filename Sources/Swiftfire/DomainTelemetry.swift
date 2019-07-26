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

final class DomainTelemetry {
    
    
    /// The total number of requests processed. Includes error replies, but excludes forwarding.
    
    let nofRequests = NamedIntValue(
        name: "Nof Requests:",
        about: "The total number of requests",
        value: 0,
        resetValue: 0)
    
    
    /// The total number of blacklisted accesses
    
    let nofBlacklistedAccesses = NamedIntValue(
        name: "Nof Blacklisted Accesses:",
        about: "The number of access by blacklisted clients",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 200 (Successfull reply)
    
    let nof200 = NamedIntValue(
        name: "Nof code 200:",
        about: "The number of code 200 (successful) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 400 (Bad Request)
    
    let nof400 = NamedIntValue(
        name: "Nof code 400:",
        about: "The number of code 400 (Bad Request) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 403 (Forbidden)
    
    let nof403 = NamedIntValue(
        name: "Nof code 403:",
        about: "The number of code 403 (Forbidden) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 404 (File/Resource Not Found)
    
    let nof404 = NamedIntValue(
        name: "Nof code 404:",
        about: "The number of code 404 (Not found) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 500 (Server Error)
    
    let nof500 = NamedIntValue(
        name: "Nof code 500:",
        about: "The number of code 500 (Server error) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 501 (Not Implemented)
    
    let nof501 = NamedIntValue(
        name: "Nof code 501:",
        about: "The number of code 501 (Not implemented) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The number of 505 (HTTP version not supported)
    
    let nof505 = NamedIntValue(
        name: "Nof code 505:",
        about: "The number of code 505 (Version not supported) accesses",
        value: 0,
        resetValue: 0)
    
    
    /// The array with all domain telemetry items
    
    let all: Array<NamedIntValue>
    

    /// Allow default initializer
    
    init() {
        all = [nofRequests, nofBlacklistedAccesses, nof200, nof400, nof403, nof404, nof500, nof501, nof505]
    }
}


// MARK: - Operational

extension DomainTelemetry {
    
    /// Reset all telemetry values to their default value.
    
    func reset() {
        all.forEach({ $0.reset() })
    }
}


// MARK: - CustomStringConvertible

extension DomainTelemetry: CustomStringConvertible {
    
    var description: String {
        var str = ""
        str += all.map({ " \($0.name): \($0.value)" }).joined(separator: "\n")
        return str
    }
}


// MARK: - VJsonConvertible

extension DomainTelemetry: VJsonConvertible {
    
    
    /// The VJson hierarchy representation for this object
    
    var json: VJson {
        let json = VJson()
        all.forEach({ json[$0.name] &= $0.value })
        return json
    }
    
    
    /// The recreation from JSON code
    
    convenience init?(json: VJson?) {
        
        guard let json = json else { return nil }
        
        self.init()
        
        var allCopy = all
        
        OUTER: for (name, value) in json.dictionaryValue {
            for (index, item) in allCopy.enumerated() {
                if item.name == name {
                    if let newValue = value.intValue {
                        item.value = newValue
                        allCopy.remove(at: index)
                        continue OUTER
                    }
                }
            }
        }
        
        assert (allCopy.count == 0)
        
        guard allCopy.count == 0 else { return nil }
    }
}
