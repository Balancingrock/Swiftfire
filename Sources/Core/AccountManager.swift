// =====================================================================================================================
//
//  File:       AccountManager.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2020 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 #9: Prevented same-names with different capitalizations
//       - Changed account handling
// 1.2.0 - Added ability to remove accounts
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation


import KeyedCache
import VJson


public class AccountManager {
    
    static let ACCOUNT_DIRECTORY_NAME = "_Account" // The underscore is for reasons of sorting in the finder
    
    
    // The queue for concurrent access protection
    
    private var queue = DispatchQueue(
        label: "AccountManager",
        qos: DispatchQoS.default,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil
    )
    
    
    /// Create an account directory url from the given account ID relative to the given root url
    ///
    /// Example 1: id 2345 will result in: root/45/23/_Account/
    ///
    /// Example 2: id 12345 will result in: root/45/23/01/_Account/
    ///
    /// - Note: No directory will be created, just the url/path
    
    private static func createDirUrl(in accountsRoot: URL, for id: Int) -> URL {
        
        
        // The account number will be broken up into reverse series of 0..99 (centi) fractions
        
        var centiFractions: Array<Int> = []
        
        var num = id
        
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
        
        var url = accountsRoot
        centiFractionsStr.forEach({ url.appendPathComponent($0) })
        url.appendPathComponent(AccountManager.ACCOUNT_DIRECTORY_NAME)
                
        return url
    }

    
    /// The root folder for all accounts
    
    private var root: URL!
    
    
    /// The lookup table that associates an account name with an account uuid
    
    private var nameLut: Dictionary<String, UUID> = [:]
    
    
    /// The looup table that associates an account uuid with an account url
    
    private var uuidLut: Dictionary<UUID, URL> = [:]
    
    
    /// The id of the last account created
    
    private var lastAccountId: Int = 0
    
    
    /// The number of accounts
    
    public var count: Int { return nameLut.count }
    
    
    /// Returns 'true' if there are no accounts yet
    
    public var isEmpty: Bool { return nameLut.isEmpty }
    
    
    /// The account cache
    
    private var accountCache: MemoryCache = MemoryCache<UUID, Account>(limitStrategy: .byItems(100), purgeStrategy: .leastRecentUsed)
    
    
    /// Initialize from file
    
    public init?(directory: URL?) {
        guard let directory = directory else { return nil }
        self.root = directory
        guard generateLut() else { return nil }
    }
}


// MARK: - Storage

extension AccountManager {
    
    
    
    
    /// Save the accounts
    
    public func store() {}
    
    
    /// Regenerates the lookup tables from the contents on disk
    
    public func generateLut() -> Bool {
        
        var nameLut: Dictionary<String, UUID> = [:]
        
        var uuidLut: Dictionary<UUID, URL> = [:]
        
        let rootPathParts = root.pathComponents

        
        /// Retrieves the account ID from an account URL
        
        func getAccountId(from accountUrl: URL) -> Int {
            
            let accountPathParts = accountUrl.pathComponents
            
            var accountId: Int = 0
            var factor = 1
            
            for i in rootPathParts.count ... accountPathParts.count - 2 {
                if let part = Int(accountPathParts[i]) {
                    accountId = accountId + part * factor
                    factor = factor * 100
                } else {
                    Log.atError?.log("Illegal value for path part: \(accountPathParts[i])")
                }
            }
            
            Log.atDebug?.log("Returning accountId = \(accountId) for url: \(accountUrl.path)")
            
            return accountId
        }

        
        func processDirectory(dir: URL) -> Bool {
            
            let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            
            if let urls = urls {
                
                for url in urls {
                    
                    // If the url is a directory, then process it (recursive), if it is a file, try to read it as an account.
                    
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue {
                        
                        if url.lastPathComponent == AccountManager.ACCOUNT_DIRECTORY_NAME {
                            
                            if let account = Account(withContentOfDirectory: url) {
                                if account.isEnabled {
                                    nameLut[account.name.lowercased()] = account.uuid
                                    uuidLut[account.uuid] = url
                                }
                                lastAccountId = Swift.max(getAccountId(from: url), lastAccountId)
                            } else {
                                return false
                            }
                            
                        } else {
                            
                            if !processDirectory(dir: url) {
                                return false
                            }
                        }
                    }
                }
                
                return true
                
            } else {
                
                Log.atCritical?.log("Failed to read account directories from \(dir.path)")
                return false
            }
        }
        
        Log.atDebug?.log("Recreating account LUTs")
        
        if processDirectory(dir: root) {
            
            self.nameLut = nameLut
            self.uuidLut = uuidLut
            
            Log.atNotice?.log("Regenerated the account LUTs")
            return true
            
        } else {
            
            Log.atCritical?.log("Could not recreate account LUTs, accounts may have been lost!")
            return false
        }
    }
}


// MARK: - Operational interface

extension AccountManager {
    
    
    /// - Returns: The account for the given uuid or nil. If the account exists, it will be placed in the cache.
    
    private func getAccount(_ uuid: UUID) -> Account? {
        
        
        // Retrieve it from chache if possible
        
        if let account = accountCache[uuid] { return account }
        
        
        // Retrieve it from memory and add to the cache
        
        let account = Account(withContentOfDirectory: uuidLut[uuid])
        if let account = account { accountCache[account.uuid] = account }
        
        return account
    }
    
    
    /// - Returns: The account for the given name or nil. If it exists it will be placed in the cache.
    
    private func getAccount(_ name: String) -> Account? {
        
        
        // Retrieve the uuid for the name
        
        guard let uuid = nameLut[name.lowercased()] else { return nil }
        
        return getAccount(uuid)
    }


    /// Returns the account for the given name without using a password, and irrespective of the status of email verification and/or enabled status.
    ///
    /// - Note: The account may be disabled (or the email address unverified)
    ///
    /// - Parameters:
    ///   - for: The name of the account to find. May not be empty.
    ///
    /// - Returns: On success the account, otherwise nil.
    
    public func getAccountWithoutPassword(for name: String) -> Account? {
                
        if name.isEmpty { return nil }
        
        return queue.sync {
            
            return getAccount(name)
        }
    }

    
    /// Returns the account for the given name and password if the account exists and the password matches.
    ///
    /// - Parameters:
    ///   - withName: The name of the account to find. May not be empty.
    ///   - andPassword: The password over which to calculate the hash and compare it with the stored hash. May not be empty.
    ///
    /// - Returns: On success the account, otherwise nil.
    
    public func getAccount(withName name: String, andPassword password: String) -> Account? {
        
        
        // Only valid parameters
        
        if password.isEmpty { return nil }
        if name.isEmpty { return nil }

        return queue.sync {
            
            
            // Get the uuid of the account
            
            guard let account = getAccount(name) else { return nil }
            
            
            // Check the password
            
            guard account.hasSameDigest(as: password) else { return nil }
            
            
            // Is ok
            
            return account
        }
    }
    
    
    /// Returns the account for the given uuid irrespective of the status of email verification and/or enabled status.
    ///
    /// - Note: The account may be disabled (or the email address unverified)
    ///
    /// - Parameters:
    ///   - for: The uuid of the account to find. May not be empty.
    ///
    /// - Returns: On success the account, otherwise nil.
    
    public func getAccount(for uuid: UUID) -> Account? {
        
        return queue.sync {
            
            return getAccount(uuid)
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
        
        return queue.sync {
            
            // Only valid parameters
            
            guard !password.isEmpty else { return nil }
            guard !name.isEmpty else { return nil }
            let lname = name.lowercased()

            
            // Check if the account already exists
            
            if nameLut[lname] != nil { return nil }
            
            
            // Create a unique uuid (unique in self and in the server admin domain accounts)
            
            var uuid = UUID()
            while (uuidLut[uuid] != nil) || (serverAdminDomain.accounts.uuidLut[uuid] != nil) { uuid = UUID() }
            
            
            // Create the new account
            
            lastAccountId += 1
            let dir = AccountManager.createDirUrl(in: root, for: lastAccountId)
            if let account = Account(name: name, password: password, uuid: uuid, accountDir: dir) {
                
                
                // Add it to the lookup's and the cache
                
                nameLut[lname] = uuid
                uuidLut[uuid] = dir
                accountCache[uuid] = account
                
                
                Log.atNotice?.log("Created account with name: '\(name)' and id: \(lastAccountId).")
                
                return account
                
            } else {
                
                Log.atError?.log()
                return nil
            }
        }
    }
    
    
    /// Checks if an account name is available.
    ///
    /// - Returns: True if the given name is available as an account name.
    
    public func available(name: String) -> Bool {
        return queue.sync {
            return nameLut[name.lowercased()] == nil
        }
    }
    
    
    /// Disables an account
    ///
    /// - Note: Make sure the user removing the account has sufficient privelidges!
    ///
    /// - Parameter uuid: The uuid of the account to remove.

    public func disable(uuid: UUID) {
        
        return queue.sync {
            
            
            // Get the account
            
            guard let account = getAccount(uuid) else {
                Log.atError?.log("No account found for uuid: \(uuid.uuidString)")
                return
            }
            
            
            // Disable the account
            
            account.isEnabled = false

            
            // Remove it from the luts & cache
            
            _ = accountCache.remove(account.uuid)
            uuidLut.removeValue(forKey: account.uuid)
            nameLut.removeValue(forKey: account.name.lowercased())
            
            Log.atNotice?.log("Disabled account with name: \(account.name)")
        }
    }
}


/// Allows itterating over all the account names

extension AccountManager: Sequence {

    public struct AccountNameGenerator: IteratorProtocol {
        
        public typealias Element = String
        
        // The object for which the generator generates
        private var source: Array<String> = []
        
        // The objects already delivered through the generator
        private var sent: Array<String> = []
        
        public init(source: AccountManager) {
            self.source = source.nameLut.compactMap({$0.key})
        }
        
        // The GeneratorType protocol
        public mutating func next() -> Element? {
            
            // Only when the source has values to deliver
            if source.count > 0 {
                
                let values = source
                let sortedValues = values.sorted(by: {$0 < $1})
                
                // Find a value that has not been sent already
                OUTER: for i in sortedValues {
                    
                    // Check if the value has not been sent already
                    for s in sent {
                        
                        // If it was sent, then try the next value
                        if i == s { continue OUTER }
                    }
                    // Found a value that was not sent yet
                    // Remember that it will be sent
                    sent.append(i)
                    
                    // Send it
                    return i
                }
            }
            // Nothing left to send
            return nil
        }
    }
    
    
    public func makeIterator() -> AccountNameGenerator {
        return queue.sync {
            return AccountNameGenerator(source: self)
        }
    }
}

extension AccountManager: ControlBlockIndexableDataSource {
    
    public var nofElements: Int {
        if getAccountWithoutPassword(for: "Anon") != nil {
            return count - 1
        } else {
            return count
        }
    }
    
    public func addElement(at index: Int, to info: inout Functions.Info) {
        
        // Get the index of the asked-for account
        var lutIndex = uuidLut.index(uuidLut.startIndex, offsetBy: index)

        // If the index of the anon account exists, and it is lower or equal than the asked index, then increase the asked for index by 1 to compensate for the anon account that may not be returned
        if let anon = getAccountWithoutPassword(for: "Anon") {
            let anonIndex = uuidLut.index(forKey: anon.uuid)!
            if anonIndex <= lutIndex {
                lutIndex = uuidLut.index(after: lutIndex)
            }
        }
        
        // Add the account at lutIndex to info
        if let account = getAccount(uuidLut[lutIndex].key) { account.addSelf(to: &info) }
    }
}
