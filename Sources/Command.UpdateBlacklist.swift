// =====================================================================================================================
//
//  File:       Command.UpdateBlacklist.swift
//  Project:    Swiftfire
//
//  Version:    0.10.0
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
// 0.10.0 - Renamed file from MacCommand to Command
// 0.9.18 - Header update
//        - Replaced log by Log?
// 0.9.15 - General update and switch to frameworks
//        - Renamed from Modify... to Update...
// 0.9.14 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import SwiftfireCore

fileprivate let COMMAND_NAME = "UpdateBlacklistCommand"
fileprivate let SOURCE = "Source"
fileprivate let ADDRESS = "Address"
fileprivate let ACTION = "Action"
fileprivate let REMOVE = "Remove"


/// This command is used to modify the contens of a blacklist

public final class UpdateBlacklistCommand: MacMessage {
    
    
    /// Serialize this object.
    
    public var json: VJson {
        let j = VJson()
        j[COMMAND_NAME][SOURCE] &= source
        j[COMMAND_NAME][ADDRESS] &= address
        j[COMMAND_NAME][ACTION] &= action
        j[COMMAND_NAME][REMOVE] &= remove
        return j
    }
    
    
    /// Deserialize an object.
    ///
    /// - Parameter json: The VJson hierarchy to be deserialized.
    
    public init?(json: VJson?) {
        
        guard let json = json else { return nil }
        
        guard let jsource = (json|COMMAND_NAME|SOURCE)?.stringValue else { return nil }
        guard let jaddress = (json|COMMAND_NAME|ADDRESS)?.stringValue else { return nil }
        guard let jaction = (json|COMMAND_NAME|ACTION)?.stringValue else { return nil }
        guard let jremove = (json|COMMAND_NAME|REMOVE)?.boolValue else { return nil }
        
        self.source = jsource
        self.address = jaddress
        self.action = jaction
        self.remove = jremove
    }
    
    
    /// Either "server" or a domain name.
    
    public private(set) var source: String
    
    
    /// The address to be updated, added or removed.
    
    public private(set) var address: String
    
    
    /// The (new) action for the address.
    
    public private(set) var action: String
    
    
    /// If true, the address must be removed.
    
    public private(set) var remove: Bool
    
    
    /// Creates a new command.
    ///
    /// - Parameters:
    ///   - source: Either "server" or a domain name.
    ///   - address: The address to be updated, added or removed.
    ///   - action: The (new) action for the address.
    ///   - remove: If true, the address must be removed.
    
    public init(source: String, address: String, action: String, remove: Bool) {
        self.source = source
        self.address = address
        self.action = action
        self.remove = remove
    }
}

extension UpdateBlacklistCommand: MacCommand {
    
    public static func factory(json: VJson?) -> MacCommand? {
        return UpdateBlacklistCommand(json: json)
    }
    
    public func execute() {
        
        Log.atNotice?.log(id: -1, source: #file.source(#function, #line))
        
        if source == "Server" {
            
            if remove {
                
                serverBlacklist.remove(ipAddress: address)
                
            } else {

                guard let bAction = Blacklist.Action(rawValue: action) else {
                    Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Cannot create Action type from '\(action)'")
                    return
                }

                serverBlacklist.add(ipAddress: address, action: bAction)
            }
        
        } else {
            
            if let domain = domains.domain(forName: source) {
                
                if remove {
                    
                    domain.blacklist.remove(ipAddress: address)
                    
                } else {
                    
                    guard let bAction = Blacklist.Action(rawValue: action) else {
                        Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Cannot create Action type from '\(action)'")
                        return
                    }

                    domain.blacklist.add(ipAddress: address, action: bAction)
                }
            }
        }
    }
}
