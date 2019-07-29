// =====================================================================================================================
//
//  File:       Blacklist.swift
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
import SwifterSockets
import BRUtils


fileprivate let ENTRY = "Entry"
fileprivate let ADDRESS = "Address"
fileprivate let ACTION = "Action"


/// The kind of actions that can be taken for a client that is refused access.

public enum BlacklistAction: String {
    
    
    /// Simply close the connection without giving any indication of why the connetion was dropped.
    
    case closeConnection = "CloseConnection"
    
    
    /// Send a "service unavailable" (Http 503) reply.
    
    case send503ServiceUnavailable = "Send503ServiceUnavailable"
    
    
    /// Send a "unauthorized" (Http 401) reply.
    
    case send401Unauthorized = "Send401Unauthorized"
    
    
    static var all: Array<BlacklistAction> = [.closeConnection, .send503ServiceUnavailable, .send401Unauthorized]
}


/// This class is intended for address blacklisting. It associates a blacklist action with an address.

public final class Blacklist {
    
    
    /// This list associates actions with clients.
    
    public private(set) var list: Dictionary<String, BlacklistAction> = [:]

    
    /// The number of clients that are refused access.
    
    public var count: Int { return list.count }
    
    
    /// Create a new and empty blacklist.
    
    public init() {}
}


// MARK: _ VJson support

extension Blacklist: VJsonSerializable, VJsonDeserializable {
    
    
    /// Recreate a blacklist from a VJson array.
    ///
    /// - Parameter json: The VJson hierarchy from which to recontruct the blacklist. Should be an array.
    
    public convenience init?(json: VJson?) {
        
        guard let json = json else { return nil }
        
        self.init()
        // Note: Rather than simply using asserts or fatal errors give a reason for a failure since a user might edit a blacklist file by hand.
        let jlist = json.arrayValue
        
        var temp: Dictionary<String, BlacklistAction> = [:]
        for j in jlist {
            guard let address = (j|ADDRESS)?.stringValue else {
                return nil
            }
            guard let jactionstr = (j|ACTION)?.stringValue else {
                return nil
            }
            guard let action = BlacklistAction(rawValue: jactionstr) else {
                return nil
            }
            temp[address] = action
        }
        list = temp
    }
    
    
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
}
    

// MARK: - Storage

extension Blacklist {
    
    
    /// Save's the blacklist content back to the file. If no file exists and no blacklisted data is present it will create an example file.
    ///
    /// - Parameter to: The URL of the file in which to store the blacklist.
    ///
    /// - Returns: .success(true) if the operation was sucessfull, .error(message: String) if not.
    
    @discardableResult
    public func save(to file: URL) -> Result<Bool> {
        
        // Special case: If there are no blacklist clients and there is no blacklist file, then create an example blacklist file
        guard list.count != 0 else {
            if !FileManager.default.fileExists(atPath: file.path) {
                let example = Blacklist()
                example.add("127.1.1.2", action: .closeConnection)
                example.add("127.1.1.3", action: .send401Unauthorized)
                example.add("127.1.1.4", action: .send503ServiceUnavailable)
                if let message = example.json.save(to: file) {
                    return .error(message: message)
                }
            }
            return .success(true)
        }
        
        if let message = json.save(to: file) {
            return .error(message: message)
        } else {
            return .success(true)
        }
    }
    
    
    /// Load the blacklist content from the file.
    ///
    /// - Parameter from: The URL of the file to read the contents from.
    ///
    /// - Returns: .success(true) if the operation was sucessfull, .error(message) if not.

    public func restore(from file: URL) -> Result<Bool> {
        
        if !FileManager.default.isReadableFile(atPath: file.path) {
            // If there is no readable file, then assume no blacklisted clients
            return .success(true)
        }
        
        let json: VJson!
        do {
            json = try VJson.parse(file: file)
            if json == nil { throw NSError() }
        } catch {
            return .error(message: "Could not read blacklistedAddresses, message = \(error), file: \(file.path)")
        }
        
        let items = json.arrayValue

        // A temporary store. Only swap the current list for the new list if the loading did not fail.
        var temp: Dictionary<String, BlacklistAction> = [:]
        
        for item in items {
            
            guard let address = (item|ADDRESS)?.stringValue, SwifterSockets.isValidIpAddress(address) else {
                return .error(message: "Missing address from array item: \(item), file: \(file.path)")
            }
            
            guard let jactionstr = (item|ACTION)?.stringValue else {
                return .error(message: "Missing action from array item: \(item), file: \(file.path)")
            }
            
            guard let action = BlacklistAction(rawValue: jactionstr) else {
                return .error(message: "Could not create blacklist action for value: \(jactionstr), file: \(file.path)")
            }
            
            temp[address] = action
        }
        
        list = temp
        
        return .success(true)
    }
}


// MARK: - Operational interface

extension Blacklist {
    
    
    /// Returns the action for this address
    ///
    /// - Parameter forAddress: The address for which an action is required.
    ///
    /// - Returns: Either a blacklist action or nil. (Nil means: no action)
    
    public func action(for address: String) -> BlacklistAction? {
        return list[address]
    }
    
    
    /// Removes the given address from the blacklist.
    ///
    /// - Parameter ipAddress: The address to be removed.
    ///
    /// - Returns: True if the address was removed, false if it did not occur in the list.

    @discardableResult
    public func remove(_ address: String) -> Bool {
        return list.removeValue(forKey: address) != nil
    }
    
    
    /// Adds the given address to the blacklist with the specified action.
    ///
    /// If the address already existed, the action will be replaced by the given action.
    ///
    /// - Parameters:
    ///   - ipAddress: The address to be added.
    ///   - action: The action for the address.
    
    public func add(_ address: String, action: BlacklistAction) {
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
    public func update(action: BlacklistAction, for address: String) -> Bool {
        if list[address] != nil {
            list[address] = action
            return true
        } else {
            return false
        }
    }
}


// MARK: - CustomStringConvertibale

extension Blacklist: CustomStringConvertible {
    
    /// Create a description of the list content.
    
    public var description: String {
        if list.count == 0 {
            return " Empty"
        } else {
            var str = ""
            str += list.map({ key, value in " Client: \(key) action = \(value)" }).joined(separator: "\n")
            return str
        }
    }
}
