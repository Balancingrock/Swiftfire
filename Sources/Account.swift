// =====================================================================================================================
//
//  File:       Account.swift
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
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.7 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterJSON
import SwiftfireCore
import KeyedCache


public class Account: EstimatedMemoryConsumption {
    
    
    /// Create an account directory url from the given account ID relative to the given root url
    ///
    /// Example 1: id 2345 will result in: root/45/23/_Account/
    ///
    /// Example 2: id 12345 will result in: root/45/23/01/_Account/
    
    private static func dirUrl(root: URL, accountId: Int) -> URL {
        
        
        // The account number will be broken up into reverse series of 0..99 (centi) fractions
        
        var centiFractions: Array<Int> = []
        
        var num: Int = accountId
        
        while num >= 100 {
            centiFractions.append(num % 100)
            num = num / 100
        }
        centiFractions.append(num)
        
        
        // Convert the centi parts to string
        
        let centiFractionsStr = centiFractions.map({ (num) -> String in
            if num < 10 {
                return "0\(num)"
            } else {
                return num.description
            }
        })
        
        
        // And create the directory url
        
        var url = root
        centiFractionsStr.forEach({ url.appendPathComponent($0) })
        url.appendPathComponent("_Account")

        return url
    }
    
    
    /// A unique id for this account
    ///
    /// In order to store and create links to/from this account a unique and unchanging reference is needed. Since the name with an account can change, it is not possible to use the name, even if the name should also be unique.
    
    public private(set) var id: Int
    
    
    /// A name that uniquely identifies an account.
    
    public var names: Array<String> = []
    
    
    /// The hash value of the user password.
    
    fileprivate var passwordHash: Int
    
    
    /// The information associated with the user.
    
    public var info = VJson()
    
    
    /// The path for the directory associated with this account
    
    public private(set) var dirUrl: URL
    
    
    /// The path for the file containing this account
    
    public var fileUrl: URL {
        return dirUrl.appendingPathComponent("Account").appendingPathExtension("json")
    }
    
    
    /// Create a new instance
    ///
    /// - Paramaters:
    ///   - id: A unique integer
    ///   - name: String, should be unique for this account.
    ///   - passwordHash: An integer that must be matched to allow somebody to use this account.
    
    fileprivate init(id: Int, name: String, passwordHash: Int, rootDir: URL) {
        self.names[0] = name
        self.passwordHash = passwordHash
        self.id = id
        self.dirUrl = Account.dirUrl(root: rootDir, accountId: id)
    }
    
    
    /// Serialize to VJson
    
    fileprivate var json: VJson {
        let json = VJson()
        for (index, name) in names.enumerated() {
            json["Names"][index] &= name
        }
        json["Id:"] &= id
        json["PasswordHash"] &= passwordHash
        json["Info"] = info
        return json
    }
    
    
    /// Recreate from a JSON file
    
    fileprivate convenience init?(root: URL, id: Int) {
        
        // Initialize with dummy's
        self.init(id: id, name: "", passwordHash: 0, rootDir: root)
        
        guard let json = VJson.parse(file: fileUrl, onError: { _,_,_ in } ) else { return nil }
        
        guard let jjnames = (json|"Names")?.arrayValue else { return nil }
        guard jjnames.count > 0 else { return nil }
        var jnames: Array<String> = []
        for jname in jjnames {
            guard let name = jname.stringValue else { return nil }
            jnames.append(name)
        }
        guard let jid = (json|"Id")?.intValue else { return nil }
        guard let jpasswordhash = (json|"PasswordHash")?.intValue else { return nil }
        guard let jinfo = json|"Info" else { return nil }
        guard jinfo.isObject else { return nil }
        
        self.names = jnames
        self.id = jid
        self.passwordHash = jpasswordhash
        self.info = jinfo
    }
    
    
    /// Save the user data to file.
    ///
    /// - Returns: On success nil, on failure a description of the error that occured.
    
    public func save() -> String? {
        return self.json.save(to: fileUrl)
    }
}

public class Accounts {

    
    // The queue for concurrent access protection
    
    private static var queue = DispatchQueue(label: "Accounts", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)

    
    /// The root folder for all accounts
    
    private var root: URL!
    
    
    /// The file for the lookup table that associates an account name with an account id
    
    private var lookupTableFile: URL {
        return root.appendingPathComponent("AccountLookUpTable").appendingPathExtension("json")
    }
    
    
    /// The lookup table that associates an account name with an account id
    
    private var lookupTable: Dictionary<String, Int> = [:]
    
    
    /// The id of the last account created
    
    private var lastAccountId: Int = 0
    
    
    /// The account cache
    
    private var accountCache: MemoryCache = MemoryCache<String, Account>(limitStrategy: .byItems(100), purgeStrategy: .leastRecentUsed)
    
    
    /// Initialize from file
    
    public init(root: URL) {
        self.root = root
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: lookupTableFile.path, isDirectory: &isDir) && !isDir.boolValue {
            loadLookupTable()
        }
    }
    
    
    /// Load the lookuptable from file
    
    private func loadLookupTable() {
        
        if let json = VJson.parse(file: lookupTableFile, onError: { (_, _, error) in
            SwifterLog.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Failed to load account lookup table from \(lookupTableFile.path), error message = \(error)")
        }) {
            
            for item in json {
                if let name = item.nameValue, let id = item.intValue {
                    lookupTable[name] = id
                    if id > lastAccountId { lastAccountId = id }
                } else {
                    SwifterLog.atCritical?.log(id: -1, source: #file.source(#function, #line), message: "Failed to load account lookup table from \(lookupTableFile.path), error message = Cannot read name or id from entry \(item)")
                    return
                }
            }
        }
    }
    
    
    /// Change the root directory url.
    ///
    /// - Note: This will only change the URL, not the disk contents.
    
    public func changeRoot(to url: URL) {
        Accounts.queue.async {
            self.root = url
        }
    }
    
    
    /// Returns the account for the given name and password. First it will try to read the account from the cache. If the cache does not contain the account it will try to find it in the lookup table and if found, load it from file. The password hash must matches the account hash.
    ///
    /// - Parameters:
    ///   - for: The name of the account to find. May not be empty.
    ///   - using: The password over which to calculate the hash and compare it with the stored hash. May not be empty.
    ///
    /// - Returns: On success the account, otherwise nil.
    
    public func getAccount(for name: String, using password: String) -> Account? {
        
        return Accounts.queue.sync {
        
            // Only valid parameters
            
            if password.isEmpty { return nil }
            if name.isEmpty { return nil }
            
            
            // Up the password to 20 characters or more, that makes the hash unpredictable even for minor changes
            
            var pwd = ""
            while pwd.characters.count < 20 { pwd += password }
            
            
            // Check the cache
            
            if let account = accountCache[name] {
                if pwd.hash == account.passwordHash {
                    return account
                }
            }
            
            
            // Check the lookup table
            
            if let id = lookupTable[name] {
                if let account = Account(root: root, id: id) {
                    accountCache[name] = account
                    if pwd.hash == account.passwordHash {
                        return account
                    }
                }
            }
            
            
            // No account matches the criteria
            
            return nil
        }
    }
    
    
    /// Create a new account and adds it to the cache.
    ///
    /// - Parameters:
    ///   - name: The name for the account, cannot be empty.
    ///   - password: The password over which to determine the password hash, may not be empty.
    ///
    /// - Returns: Nil if the input parameters are invalid or if the account already exists. The new account if it was created.
    
    public func newAccount(name: String, password: String) -> Account? {
        
        return Accounts.queue.sync {

            // Only valid parameters
            
            if password.isEmpty { return nil }
            if name.isEmpty { return nil }
            
            
            // Check if the account already exists
            
            if lookupTable[name] != nil { return nil }
            
            
            // Up the password to 20 characters or more, that makes the hash unpredictable even for minor changes
            
            var pwd = ""
            while pwd.characters.count < 20 { pwd += password }
            
            
            // Create the new account
            
            lastAccountId += 1
            let account = Account(id: lastAccountId, name: name, passwordHash: pwd.hash, rootDir: root)
            
            
            // Add it to the lookup and the cache
            
            lookupTable[name] = lastAccountId
            accountCache[name] = account
            
            return account
        }
    }
    
    
    /// Checks if an account name is available.
    ///
    /// - Returns: True if the given name is available as an account name.
    
    public func available(name: String) -> Bool {
        
        return Accounts.queue.sync {

            return lookupTable[name] == nil
        }
    }
    
    
    /// Regenerates the lookup table from the contents on disk
    
    public func regenerateLookupTable(root: URL?) -> Bool {
        fatalError("Not implemented")
    }
    
    
}





