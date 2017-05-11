// =====================================================================================================================
//
//  File:       DomainTelemetry.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Rewrite
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks, SwifterCore split.
// 0.9.14 - Upgraded to Xcode 8 beta 6
//        - Code upgrade
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Updated for VJson 0.9.8
// 0.9.6  - Header update
// 0.9.3  - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterJSON


/// Telemetry items associated with a single domain.

public class DomainTelemetry: CustomStringConvertible {
    
    
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
    
    
    /// A description of all telemetry
    
    public var description: String {
        var str = ""
        str += all.map({ " \($0.name): \($0.value)" }).joined(separator: "\n")
        return str
    }
    
    
    /// The VJson hierarchy representation for this object
    
    public var json: VJson {
        let json = VJson()
        all.forEach({ json[$0.name] &= $0.value })
        return json
    }
    
    
    /// Allow default initializer
    
    public init() {
        all = [nofRequests, nofBlacklistedAccesses, nof200, nof400, nof403, nof404, nof500, nof501, nof505]
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
    
    
    /// Reset all telemetry values to their default value.
    
    public func reset() {
        all.forEach({ $0.reset() })
    }
}
