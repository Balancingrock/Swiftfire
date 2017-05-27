// =====================================================================================================================
//
//  File:       StClient.swift
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.9.17 - Header update
// 0.9.15 - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON


/// Client information.

public final class StClient: VJsonConvertible {

    
    /// The address of the client
    
    public var address: String
        
    
    /// If this is set to 'true' then the client info will not be updated for this client.
    
    public var doNotTrace: Bool = false
    
    
    /// A list of all accesses for this client
    
    public var records: [StClientRecord] = []
    
    
    /// Stores all information in a VJson hierarchy

    public var json: VJson {
        let json = VJson()
        json["a"] &= address
        json["d"] &= doNotTrace
        json["r"] &= VJson(records)
        return json
    }

    
    /// Recreates the content from the given VJson hierarchy.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jAddress    = (json|"a")?.stringValue else { return nil }
        guard let jDoNotTrace = (json|"d")?.boolValue else { return nil }
        guard let jRecords    = (json|"r") else { return nil }
        
        for jRecord in jRecords {
            guard let record = StClientRecord(json: jRecord) else { return nil }
            records.append(record)
        }
        
        self.address = jAddress
        self.doNotTrace = jDoNotTrace
    }

    
    /// Create a new object
    
    public init(address: String) {
        self.address = address
    }
}