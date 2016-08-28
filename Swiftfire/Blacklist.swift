// =====================================================================================================================
//
//  File:       Blacklist.swift
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// v0.9.14 - Initial release
// =====================================================================================================================


import Foundation


private let ENTRY = "Entry"
private let ADDRESS = "Address"
private let ACTION = "Action"


final class Blacklist: VJsonSerializable, VJsonDeserializable {
    
    
    /// The kind of actions that can be taken for a client that is refused access.
    
    enum Action: String {
        case closeConnection = "CloseConnection"
        case send503ServiceUnavailable = "Send503ServiceUnavailable"
        case send401Unauthorized = "Send401Unauthorized"
        static var all: Array<Action> = [.closeConnection, .send503ServiceUnavailable, .send401Unauthorized]
    }
    
    
    /// This list associates actions with clients. All clients in this list will be denied access.
    
    var list: Dictionary<String, Action> = [:]

    
    /// The number of clients that are refused access.
    
    var count: Int { return list.count }
    
    
    var json: VJson {
        let j = VJson.array()
        for item in list {
            let ji = VJson.object()
            ji[ADDRESS] &= item.key
            ji[ACTION] &= item.value.rawValue
            j.append(ji)
        }
        return j
    }
    
    
    // Allow default initialization
    
    init() {}
    
    
    // Init from JSON
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jlist = json.arrayValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "JSON code should be an array, is: \(json)")
            return nil
        }
        var temp: Dictionary<String, Action> = [:]
        for j in jlist {
            guard let address = (j|ADDRESS)?.stringValue else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not extract an '\(ADDRESS)' item in JSON code: \(json)")
                return nil
            }
            guard let jactionstr = (j|ACTION)?.stringValue else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not read action string in JSON code: \(json)")
                return nil
            }
            guard let action = Action(rawValue: jactionstr) else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not create Action for \(jactionstr)")
                return nil
            }
            temp[address] = action
        }
        list = temp
    }
    
    
    /// - Returns: Nil if the address is not in the watchlist, a BlacklistAction otherwise.
    
    func action(forAddress address: String) -> Action? {
        return list[address]
    }
    
    
    /// Save's the blacklist content back to the file. If no file exists and no blacklisted data is present it will create an example file.
    /// - Note: The "save" operation will always try to overwrite the file that was read by the "load" operation.
    /// - Returns: True if the operation was sucessfull, false if not.
    
    @discardableResult
    func save(toFileLocation url: URL) -> Bool {
        
        // Special case: If there are no blacklist clients and there is no blacklist file, then create an example blacklist file
        guard list.count != 0 else {
            if !FileManager.default.fileExists(atPath: url.path) {
                let example = Blacklist()
                example.add(ipAddress: "127.1.1.2", action: Action.closeConnection)
                example.json.save(to: url)
            }
            return false
        }
        
        if let message = json.save(to: url) {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not save blacklistedAddresses, message = \(message)")
            return false
        }
        else {
            return true
        }
    }
    
    
    /// Load the blacklist content from the file "address_blacklisting.json" in the settings directory.
    /// - Returns: True if the operation was sucessfull, false if not.

    @discardableResult
    func load(fromFileLocation url: URL) -> Bool {
        
        if !FileManager.default.isReadableFile(atPath: url.path) {
            // If there is no readable file, then assume no blacklisted clients
            return true
        }
        
        let json: VJson
        do {
            json = try VJson.parse(file: url)
        } catch {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not read blacklistedAddresses, message = \(error)")
            return false
        }
        
        guard let items = json.arrayValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not get filelocation for FileURLs.blacklistedAddresses")
            return false
        }

        // A temporary store. Only swap the current list for the new list if the loading did not fail.
        var temp: Dictionary<String, Action> = [:]
        
        for item in items {
            
            guard let address = (item|ADDRESS)?.stringValue, SwifterSockets.isValidIpAddress(address) else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Error reading address from blacklistedAddresses list item")
                return false
            }
            
            guard let jactionstr = (item|ACTION)?.stringValue else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not read action string in JSON code: \(item)")
                return false
            }
            guard let action = Action(rawValue: jactionstr) else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not create Action for \(jactionstr)")
                return false
            }
            temp[address] = action
        }
        
        list = temp
        
        return true
    }
    
    
    /// Removes the given address from the blacklist
    /// - Returns: True if the address was removed, false if it did not occur in the list.

    @discardableResult
    func remove(ipAddress address: String) -> Bool {
        return list.removeValue(forKey: address) != nil
    }
    
    
    /// Adds the given address to the blacklist with the specified action.
    /// If the address already existed, the action will be replaced by the given action.
    
    func add(ipAddress address: String, action: Action) {
        list[address] = action
    }
    
    
    /// Updates the action for the given address.
    /// - Returns: True if the address occured in the list, false if it was not in the list.
    
    @discardableResult
    func update(action: Action, forIpAddress address: String) -> Bool {
        if list[address] != nil {
            list[address] = action
            return true
        } else {
            return false
        }
    }
    
    
    /// Log the blacklisted clients
    
    func writeToLog(atLevel level: SwifterLog.Level) {
        log.atLevel(level, id: -1, source: "Blacklist", message: "Number of blacklisted clients \(list.count).")
        for client in list {
            log.atLevel(level, id: -1, source: "Blacklist", message: "For client \(client.key) action = \(client.value.rawValue)")
        }
    }
}
