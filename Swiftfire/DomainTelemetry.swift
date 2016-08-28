// =====================================================================================================================
//
//  File:       DomainTelemetry.swift
//  Project:    Swiftfire
//
//  Version:    0.9.14
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// v0.9.14 - Upgraded to Xcode 8 beta 6
//         - Code upgrade
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.11 - Updated for VJson 0.9.8
// v0.9.6  - Header update
// v0.9.3  - Initial release
// =====================================================================================================================


import Foundation

func == (left: DomainTelemetry.Item, right: DomainTelemetry.Item) -> Bool {
    if left.value != right.value { return false }
    if left.name != right.name { return false }
    return true
}

func == (left: DomainTelemetry, right: DomainTelemetry) -> Bool {
    for lItem in left.all {
        for rItem in right.all {
            if lItem.name == rItem.name {
                if lItem.value != rItem.value { return false }
                continue
            }
        }
    }
    return true
}

class DomainTelemetry: NSObject {
    
    class Item: NSObject {
        
        var name: String
        var value: Int = 0
        
        func copyFrom(_ t: Item) {
            self.name = t.name
            self.value = t.value
        }
        
        var json: VJson {
            let j = VJson()
            j["Name"] &= name
            j["Value"] &= value
            return j
        }
        
        func increment() {
            value += 1
            if value == 1_000_000 { value = 0 }
        }
        
        init(name: String) {
            self.name = name
            super.init()
        }
        
        convenience init(name: String, value: Int) {
            self.init(name: name)
            self.value = value
        }
        
        convenience init?(json: VJson?) {
            guard let json = json else { return nil }
            guard let jname = (json|"Name")?.stringValue else { return nil }
            guard let jvalue = (json|"Value")?.intValue else { return nil }
            self.init(name: jname, value: jvalue)
        }
    }

    
    /// The total number of requests processed. Includes error replies, but excludes forwarding.
    
    let nofRequests = Item(name: "NofRequests")
    
    
    /// The number of 200 (Successfull reply)
    
    let nof200 = Item(name: "Nof200")
    
    
    /// The number of 400 (Bad Request)
    
    let nof400 = Item(name: "Nof400")
    
    
    /// The number of 403 (Forbidden)
    
    let nof403 = Item(name: "Nof403")
    
    
    /// The number of 404 (File/Resource Not Found)
    
    let nof404 = Item(name: "Nof404")
    
    
    /// The number of 500 (Server Error)
    
    let nof500 = Item(name: "Nof500")
    
    
    /// The number of 501 (Not Implemented)
    
    let nof501 = Item(name: "Nof501")
    
    
    /// The number of 505 (HTTP version not supported)
    
    let nof505 = Item(name: "Nof505")
    
    
    /// All the telemetry in an array
    
    var all: Array<Item>
    
    
    /// Creates a duplicate of the telemetry and returns that
    
    var duplicate: DomainTelemetry {
        let new = DomainTelemetry()
        new.all.forEach({
            for item in all {
                if $0.name == item.name {
                    $0.value = item.value
                    continue
                }
            }
        })
        return new
    }

    
    /// The JSON representation for this object
    
    var json: VJson {
        let j = VJson.array()
        all.forEach({ j.append($0.json) })
        return j
    }
    
    
    /// Allow default initializer
    
    override init() {
        all = [nofRequests, nof200, nof400, nof403, nof404, nof500, nof501, nof505]
        super.init()
    }
    
    
    /// The recreation from JSON code
    
    convenience init?(json: VJson?) {
        
        guard let json = json else { return nil }
        guard json.isArray else { return nil }

        // Read all the new items in the json object
        // Make sure all the items are present in the json code by creating a set of all the names
        var itemNames: Set<String> = []
        var items: Set<Item> = []
        
        for jitem in json.arrayValue! {
            if let item = Item(json: jitem) {
                items.insert(item)
                itemNames.insert(item.name)
            }
        }

        self.init()

        // Guarantee that all necessary items are present
        guard itemNames.count == all.count else { return nil }
        
        // Update all telemetry in self with the new values
        all.forEach({
            for item in items {
                if $0.name == item.name {
                    $0.value = item.value
                    continue
                }
            }
        })
    }
    
    
    /// Reset all telemetry values to their default value.
    
    func reset() {
        all.forEach( { $0.value = 0 } )
    }
    
    
    /// Copies the values from the other telemetry to self
    
    func updateWithValues(from otherTelemetry: DomainTelemetry) {
        all.forEach({
            for item in otherTelemetry.all {
                if $0.name == item.name {
                    $0.value = item.value
                    continue
                }
            }
        })
    }
}
