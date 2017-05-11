// =====================================================================================================================
//
//  File:       Command.UpdateDomain.swift
//  Project:    Swiftfire
//
//  Version:    0.10.5
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.5 - Fixed typo (additional ')' at end of log entry)
// 0.10.0 - Renamed file from MacCommand to Command
// 0.9.18 - Header update
//        - Replaced log by Log?
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog


private let COMMAND_NAME = "UpdateDomainCommand"
private let DOMAIN_NAME = "DomainName"
private let ITEM_NAME = "ItemName"
private let VALUE = "Value"


/// Update the settings of a specific domain.

public final class UpdateDomainCommand: MacMessage {
    
    
    /// Serialize this object.
    
    public var json: VJson {
        let json = VJson()
        json[COMMAND_NAME][DOMAIN_NAME] &= domainName
        json[COMMAND_NAME][ITEM_NAME] &= itemName
        json[COMMAND_NAME][VALUE] &= value
        return json
    }
    
    
    /// Deserialize an object.
    ///
    /// - Parameter json: The VJson hierarchy to be deserialized.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jdomainname = (json|COMMAND_NAME|DOMAIN_NAME)?.stringValue else { return nil }
        guard let jitemname = (json|COMMAND_NAME|ITEM_NAME)?.stringValue else { return nil }
        guard let jvalue = (json|COMMAND_NAME|VALUE)?.stringValue else { return nil }
        domainName = jdomainname
        itemName = jitemname
        value = jvalue
    }
    
    
    /// The name of the domain to update.
    
    public let domainName: String
    public let itemName: String
    public let value: String
    
    
    /// Creates a new command.
    ///
    /// - Parameters:
    ///   - oldDomainName: The name of the domain to update.
    ///   - newDomain: The new settings for the domain.
    
    public init?(domainName: String, itemName: String, value: String) {
        self.domainName = domainName
        self.itemName = itemName
        self.value = value
    }
}

extension UpdateDomainCommand: MacCommand {
    
    public static func factory(json: VJson?) -> MacCommand? {
        return UpdateDomainCommand(json: json)
    }
    
    public func execute() {
        
        guard let domain = domains.domain(forName: domainName) else {
            Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "No domain present with name \(domainName)")
            return
        }
        
        domain.update(item: itemName, to: value)
    }
}
