// =====================================================================================================================
//
//  File:       Blacklist.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.6
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
// 0.10.6 - Minor description update
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks, SwiftfireCore split.
// 0.9.14 - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterSockets


fileprivate let ENTRY = "Entry"
fileprivate let ADDRESS = "Address"
fileprivate let ACTION = "Action"


/// This class is intended for address blacklisting. It associates a blacklist action with an address.

public final class Blacklist: VJsonSerializable, VJsonDeserializable, CustomStringConvertible {
    
    
    /// The kind of actions that can be taken for a client that is refused access.
    
    public enum Action: String {
        
        
        /// Simply close the connection without giving any indication of why the connetion was dropped.
        
        case closeConnection = "CloseConnection"
        
        
        /// Send a "service unavailable" (Http 503) reply.
        
        case send503ServiceUnavailable = "Send503ServiceUnavailable"
        
        
        /// Send a "unauthorized" (Http 401) reply.
        
        case send401Unauthorized = "Send401Unauthorized"
        
        
        public static var all: Array<Action> = [.closeConnection, .send503ServiceUnavailable, .send401Unauthorized]
    }
    
    
    /// This list associates actions with clients.
    
    public private(set) var list: Dictionary<String, Action> = [:]

    
    /// The number of clients that are refused access.
    
    public var count: Int { return list.count }
    
    
    /// Returns a VJson array representing the content of the list.
    
    public var json: VJson {
        let j = VJson.array()
        for item in list {
            let i = VJson.object()
            i[ADDRESS] &= item.key
            i[ACTION] &= item.value.rawValue
            j.append(i)
        }
        return j
    }
    
    
    /// Create a new and empty blacklist.
    
    public init() {}
    
    
    /// Recreate a blacklist from a VJson array.
    ///
    /// - Parameter json: The VJson hierarchy from which to recontruct the blacklist. Should be an array.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        // Note: Rather than simply using asserts or fatal errors give a reason for a failure since a user might edit a blacklist file by hand.
        let jlist = json.arrayValue
        
        var temp: Dictionary<String, Action> = [:]
        for j in jlist {
            guard let address = (j|ADDRESS)?.stringValue else {
                return nil
            }
            guard let jactionstr = (j|ACTION)?.stringValue else {
                return nil
            }
            guard let action = Action(rawValue: jactionstr) else {
                return nil
            }
            temp[address] = action
        }
        list = temp
    }
    
    
    /// Returns the action for this address
    ///
    /// - Parameter forAddress: The address for which an action is required.
    ///
    /// - Returns: Either a blacklist action or nil. (Nil means: no action)
    
    public func action(forAddress address: String) -> Action? {
        return list[address]
    }
    
    
    /// Save's the blacklist content back to the file. If no file exists and no blacklisted data is present it will create an example file.
    ///
    /// - Parameter to: The URL of the file in which to store the blacklist.
    ///
    /// - Returns: .success(true) if the operation was sucessfull, .error(message: String) if not.
    
    @discardableResult
    public func save(toFile url: URL) -> FunctionResult<Bool> {
        
        // Special case: If there are no blacklist clients and there is no blacklist file, then create an example blacklist file
        guard list.count != 0 else {
            if !FileManager.default.fileExists(atPath: url.path) {
                let example = Blacklist()
                example.add(ipAddress: "127.1.1.2", action: Action.closeConnection)
                example.add(ipAddress: "127.1.1.3", action: Action.send401Unauthorized)
                example.add(ipAddress: "127.1.1.4", action: Action.send503ServiceUnavailable)
                if let message = example.json.save(to: url) {
                    return .error(message: message)
                }
            }
            return .success(true)
        }
        
        if let message = json.save(to: url) {
            return .error(message: message)
        } else {
            return .success(true)
        }
    }
    
    
    /// Load the blacklist content from the file.
    ///
    /// - Parameter fromFile: The URL of the file to read the contents from.
    ///
    /// - Returns: .success(true) if the operation was sucessfull, .error(message) if not.

    public func restore(fromFile url: URL) -> FunctionResult<Bool> {
        
        if !FileManager.default.isReadableFile(atPath: url.path) {
            // If there is no readable file, then assume no blacklisted clients
            return .success(true)
        }
        
        let json: VJson
        do {
            json = try VJson.parse(file: url)
        } catch {
            return .error(message: "Could not read blacklistedAddresses, message = \(error), file: \(url.path)")
        }
        
        let items = json.arrayValue

        // A temporary store. Only swap the current list for the new list if the loading did not fail.
        var temp: Dictionary<String, Action> = [:]
        
        for item in items {
            
            guard let address = (item|ADDRESS)?.stringValue, SwifterSockets.isValidIpAddress(address) else {
                return .error(message: "Missing address from array item: \(item), file: \(url.path)")
            }
            
            guard let jactionstr = (item|ACTION)?.stringValue else {
                return .error(message: "Missing action from array item: \(item), file: \(url.path)")
            }
            
            guard let action = Action(rawValue: jactionstr) else {
                return .error(message: "Could not create blacklist action for value: \(jactionstr), file: \(url.path)")
            }
            
            temp[address] = action
        }
        
        list = temp
        
        return .success(true)
    }
    
    
    /// Removes the given address from the blacklist.
    ///
    /// - Parameter ipAddress: The address to be removed.
    ///
    /// - Returns: True if the address was removed, false if it did not occur in the list.

    @discardableResult
    public func remove(ipAddress address: String) -> Bool {
        return list.removeValue(forKey: address) != nil
    }
    
    
    /// Adds the given address to the blacklist with the specified action.
    ///
    /// If the address already existed, the action will be replaced by the given action.
    ///
    /// - Parameters:
    ///   - ipAddress: The address to be added.
    ///   - action: The action for the address.
    
    public func add(ipAddress address: String, action: Action) {
        list[address] = action
    }
    
    
    /// Updates the action for the given address.
    ///
    /// - Parameters:
    ///   - action: The new action for the given ip address.
    ///   - forIpAddress: The IP address to be updated.
    ///
    /// - Returns: True if the address occured in the list, false if it was not in the list.
    
    @discardableResult
    public func update(action: Action, forIpAddress address: String) -> Bool {
        if list[address] != nil {
            list[address] = action
            return true
        } else {
            return false
        }
    }
    
    
    /// Create a description of the list content.
    
    public var description: String {
        if list.count == 0 {
            return " Empty"
        } else {
            var str = ""
            str += list.map({ key, value in " Client: \(key) action = \(value)" }).joined(separator: "\n")
            /*
            for (index, entry) in list.enumerated() {
                str += " Client: \(entry.key) action = \(entry.value)"
                if index < (list.count - 1) { str += "\n" }
            }*/
            return str
        }
    }
}
