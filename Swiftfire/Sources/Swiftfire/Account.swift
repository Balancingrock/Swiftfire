// =====================================================================================================================
//
//  File:       Account.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
import SwifterLog
import VJson
import KeyedCache
import COpenSsl


/// An account within swiftfire. Used for admin account and can be used for domain accounts as well.

final class Account: EstimatedMemoryConsumption {
    
    // Note: It uses the default EstimatedMemoryConsumption implementation.
    
    
    /// A public unique identifier that can be used to reference this account
    
    private(set) var uuid: String

    
    /// The name for this account. When the name is updated, it is automatically persisted. If persistence fails, the name is not updated. Protected against empty names, too long names (max 32 char) and too many name changes (max 19).
    ///
    /// - Note: Updates are not thread safe, make sure that the session is 'exclusive' before updating.
    
    var name: String {
        get {
            if names.count > 0 {
                return names[0]
            } else {
                Log.atError?.log("Array with names is empty", type: "Account")
                return ""
            }
        }
        set {
            
            // Protection
            
            if newValue.isEmpty { return }
            if newValue.utf8.count > 32 { return }
            if names.count > 20 { return }
            
            
            // Do not add if the name did not change.
            
            if names.count > 0, newValue == names[0] { return }
            
            
            // Add the new name
            
            names.insert(newValue, at: 0)
            
            
            // Save the new values, if the save fails, then undo the change.
            assertionFailure("The call to saveUserData below this line is wrong!, replace with correct code")
            if let error = saveUserData() {
                Log.atError?.log("Cannot save account \(self), error message = \(error)", type: "Account")
                
            } else {
                
                names.removeFirst()
            }
        }
    }

    
    /// A unique id for this account, used for storage purposes only.
    
    fileprivate var id: Int
    
    
    /// A name that uniquely identifies an account.
    
    private var names: Array<String> = []
    
    
    /// The digest for the user password.
    
    private var digest: String!
    
    
    /// The password salt
    
    private var salt: String!
    
    
    /// The path of the file containing this account
    
    fileprivate var url: URL
    
    
    /// Convenience data storage for data that needs to be associated with the account. Use for small amounts only. Not thread save.
    ///
    /// - Note: Updates to this member are __not__ saved automatically. You must call _save_ immediately after updating to ensure persistence of the data.
    ///
    /// - Note: Intended for small parameters only. If larger data storage is needed, use the _dirUrl_ instead and store the data directly to disk.
    ///
    /// - Note: Updates are not thread safe, make sure that the session is 'exclusive' before updating.
    ///
    /// - Note: Be carefull: attackers may try to bring a site down by storing illegal or too much data. Never store data untested for validity and size.
    
    var info = VJson()
    
    
    /// Create a new instance
    ///
    /// - Paramaters:
    ///   - id: A unique integer
    ///   - name: String, should be unique for this account.
    ///   - passwordHash: An integer that must be matched to allow somebody to use this account.
    ///   - accountsRoot: A URL pointing to the root directory for all accounts.
    
    fileprivate init?(id: Int, name: String, password: String, accountsRoot: URL) {
        
        self.id = id
        self.uuid = UUID().uuidString
        self.names.insert(name, at: 0)
        self.url = Account.createFileUrl(in: accountsRoot, with: id)
        
        let salt = createSalt()
        guard let digest = createDigest(for: password, with: salt) else { return nil }
        
        self.salt = salt
        self.digest = digest
        
        if let error = saveUserData() {
            Log.atError?.log("Cannot save account\n\n\(self),\n\n Error message = \(error)\n", type: "Account")
            return nil
        }
    }
    
    
    /// Deserialize from a VJson file
    
    fileprivate init?(url: URL) {
        
        self.url = url
        
        guard let json = ((try? VJson.parse(file: url)) as VJson??) else { return nil }
        
        guard let jjnames = (json|"Names")?.arrayValue else { return nil }
        guard jjnames.count > 0 else { return nil }
        var jnames: Array<String> = []
        for jname in jjnames {
            guard let name = jname.stringValue else { return nil }
            jnames.append(name)
        }
        guard let jid = (json|"Id")?.intValue else { return nil }
        guard let juuid = (json|"Uuid")?.stringValue else { return nil }
        guard let jdigest = (json|"Digest")?.stringValue else { return nil }
        guard let jsalt = (json|"Salt")?.stringValue else { return nil }
        guard let jinfo = json|"Info" else { return nil }
        guard jinfo.isObject else { return nil }
        
        self.names = jnames
        self.id = jid
        self.uuid = juuid
        self.digest = jdigest
        self.salt = jsalt
        self.info = jinfo
    }


    /// Serialize to VJson
    
    private var json: VJson {
        let json = VJson()
        for (index, name) in names.enumerated() {
            json["Names"][index] &= name
        }
        json["Id"] &= id
        json["Uuid"] &= uuid
        json["Digest"] &= digest
        json["Salt"] &= salt
        json["Info"] = info
        
        return json
    }

    
    /// Save the user data to file.
    ///
    /// - Returns: On success nil, on failure a description of the error that occured.
    
    func saveUserData() -> String? {
        return self.json.save(to: url)
    }
}


// MARK: - Class Static

extension Account {
    
    /// The path for the file containing the account with the given ID
    
    static func createFileUrl(in directory: URL, with id: Int) -> URL {
        return createDirUrl(in: directory, for: id).appendingPathComponent("Account").appendingPathExtension("json")
    }
    
    
    /// Create an account directory url from the given account ID relative to the given root url
    ///
    /// Example 1: id 2345 will result in: root/45/23/_Account/
    ///
    /// Example 2: id 12345 will result in: root/45/23/01/_Account/
    
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
        url.appendPathComponent("_Account")
        
        try? FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        
        return url
    }
}


// MARK:- JSON

extension Account: CustomStringConvertible {
    
    
    /// CustomStringConvertible
    
    var description: String {
        var str = "Account\n"
        str += " Id: \(id)\n"
        str += " Uuid: \(uuid)\n"
        str += " Name: \(name)\n"
        //str += " fileUrl: \(fileUrl.path)\n"
        str += " Digest: \(String(describing: digest))"
        if parameters.debugMode.value {
            str += "\n Salt: \(String(describing: salt))\n"
            if historicalNames.count == 0 {
                str += " No old names\n"
            } else {
                str += " Old names:\n"
                historicalNames.forEach({ str += "  \($0)\n"})
            }
            str += " Info: \(info.description)"
        }
        return str
    }
}
    

// MARK: - Functional interface

extension Account {
    

    /// A list of all the old names this account has had.
    
    var historicalNames: Array<String> {
        var old = names
        if old.count > 0 { old.removeFirst() }
        return old
    }
    

    /// Update password (digest). A new salt is created also. If the operation fails, the values of the salt and the digest will remain as they are.
    ///
    /// - Note: Updates are not thread safe, make sure that the session is 'exclusive' before updating.
    ///
    /// - Parameter str: The new password. Note that the password itself is not stored, only the digest.
    ///
    /// - Returns: True if the operation succeeded, false if not.
    
    func updatePassword(_ str: String) -> Bool {
        
        // Keep the old values until we are sure the old ones are saved.
        
        let oldSalt = self.salt
        let oldDigest = self.digest
        
        
        // Create and set the new values
        
        let salt = createSalt()
        guard let digest = createDigest(for: str, with: salt) else { return false }
        
        self.salt = salt
        self.digest = digest
        
        
        // Save the new values, if the save fails, then restore the old values.
        
        if let error = saveUserData() {
            Log.atError?.log("Cannot save account \(self), error message = \(error)", type: "Account")
            self.salt = oldSalt
            self.digest = oldDigest
            return false
            
        } else {
            
            return true
        }
    }
    
    
    /// Returns 'true' if the digest for the given password matches the digest of this account.
    ///
    /// - Parameters:
    ///   - as: The password to be checked.
    ///
    /// - Returns: False if the digest cannot be created or when it does not match.
    
    fileprivate func hasSameDigest(as pwd: String) -> Bool {
        
        guard let testDigest = createDigest(for: pwd, with: salt) else {
            Log.atCritical?.log("Cannot create digest", type: "Account")
            return false
        }
        
        return digest == testDigest
    }
    
    
    /// Create salt for password digest creation.
    ///
    /// - Returns: A string with the hexadecimal representation of the salt.
    
    private func createSalt() -> String {
        
        
        // Use 20 bytes (160 bits)
        
        let saltSize = 20
        
        
        // Use /dev/urandom
        
        let rand = open("/dev/urandom", O_RDONLY)
        
        
        // Allocate a buffer
        
        let randBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: saltSize)
        defer { randBytes.deallocate() }
        
        
        // Fill the buffer
        
        var count = 0
        while count < saltSize {
            let rb = read(rand, UnsafeMutableRawPointer(randBytes), saltSize - count)
            count = count + rb
        }
        
        
        // Convert the buffer content to string
        
        let randBuffer = UnsafeMutableBufferPointer(start: randBytes, count: saltSize)
        var str = ""
        randBuffer.forEach({ str.append($0.hexString) })
        
        
        // Return the string
        
        return str
    }

    
    /// Creates a digest for the given string and salt combination.
    
    private func createDigest(for str: String, with salt: String) -> String? {
        
        
        // Create the digest generator
        
        guard let digester = EVP_MD_CTX_new() else {
            Log.atEmergency?.log("Cannot allocate digest generator", type: "Account")
            return nil
        }
        defer { EVP_MD_CTX_free(digester) }
        
        
        // Initialize the digester
        
        if EVP_DigestInit(digester, EVP_sha384()) == 0 {
            Log.atEmergency?.log("Cannot initialize digest generator", type: "Account")
            return nil
        }
        
        
        // Add the salt to the digester
        
        if let saltData = salt.data(using: String.Encoding.utf8) {
            if saltData.withUnsafeBytes({ (ptr) -> Bool in
                return EVP_DigestUpdate(digester, UnsafeRawPointer(ptr), saltData.count) == 0
            }) {
                Log.atEmergency?.log("Cannot update digest generator with salt", type: "Account")
                return nil
            }
        }
        
        
        // Add the string to the digester
        
        if let strData = str.data(using: String.Encoding.utf8) {
            if strData.withUnsafeBytes({ (ptr) -> Bool in
                return EVP_DigestUpdate(digester, UnsafeRawPointer(ptr), strData.count) == 0
            }) {
                Log.atEmergency?.log("Cannot update digest generator with string", type: "Account")
                return nil
            }
        }
        
        
        // Extract the result
        
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(EVP_MAX_MD_SIZE))
        var outputLength: UInt32 = 0
        if EVP_DigestFinal(digester, outputBuffer, &outputLength) == 0 {
            Log.atEmergency?.log("Cannot extract digest generator result", type: "Account")
            return nil
        }
        
        var result = ""
        var ptr = UnsafeMutablePointer(outputBuffer.advanced(by: 0))
        if outputLength > 0 {
            for _ in 1 ... outputLength {
                result.append(ptr.pointee.hexString)
                ptr = ptr.advanced(by: 1)
            }
        }
        
        outputBuffer.deallocate()
        
        return result
    }
}


// MARK: - An accounts manager

class AccountManager {

    
    // The queue for concurrent access protection
    
    private static var queue = DispatchQueue(label: "Accounts", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)

    
    /// The root folder for all accounts
    
    private var root: URL!
    
    
    /// The file for the lookup table that associates an account name with an account id
    
    private var lutFile: URL {
        return root.appendingPathComponent("AccountsLut").appendingPathExtension("json")
    }
    

    /// The lookup table that associates an account name with an account id
    
    private var nameLut: Dictionary<String, Int> = [:]
    
    
    /// The lookup table that associates an uuid with an account name
    
    private var uuidLut: Dictionary<String, String> = [:]
    
    
    /// The id of the last account created
    
    private var lastAccountId: Int = 0
    
    
    /// The number of accounts
    
    var count: Int { return nameLut.count }
    
    
    /// Returns 'true' if there are no accounts yet
    
    var isEmpty: Bool { return nameLut.isEmpty }
    
    
    /// The account cache
    
    private var accountCache: MemoryCache = MemoryCache<String, Account>(limitStrategy: .byItems(100), purgeStrategy: .leastRecentUsed)
    
    
    /// Initialize from file
    
    init(root: URL) {
        self.root = root
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: lutFile.path, isDirectory: &isDir) && !isDir.boolValue {
            loadLuts()
        } else {
            if regenerateLuts() {
                saveLuts()
            }
        }
    }
    
}


// MARK: - Storage

extension AccountManager {
    
    /// Save the accounts
    
    func save() {
        saveLuts()
    }
    
    
    /// Load the lookup tables from file
    
    private func loadLuts() {
        
        if let json = VJson.parse(file: lutFile, onError: { (_, _, _, mess) in
            Log.atCritical?.log("Failed to load accounts lookup table from \(self.lutFile.path), error message = \(mess)", type: "Accounts")
        }) {
            
            for item in json {
                if  let name = (item|"Name")?.stringValue,
                    let uuid = (item|"Uuid")?.stringValue,
                    let id = (item|"Id")?.intValue {
                    nameLut[name] = id
                    uuidLut[uuid] = name
                    if id > lastAccountId { lastAccountId = id }
                } else {
                    Log.atCritical?.log("Failed to load accounts lookup table from \(lutFile.path), error message = Cannot read name, uuid or id from entry \(item)", type: "Accounts")
                    return
                }
            }
        }
    }
    
    
    /// Save the lookup tables to file
    
    private func saveLuts() {
        
        var once = true // Prevents repeated entries in the log
        
        let json = VJson.array()
        
        uuidLut.forEach {
            (uuid, name) in
            if let id = nameLut[name] {
                let child = VJson()
                child["Name"] &= name
                child["Uuid"] &= uuid
                child["Id"] &= id
                json.append(child)
            } else {
                if once {
                    once = false
                    Log.atCritical?.log("Account lookup tables are damaged, possible account loss. Regenerate the luts to recover the accounts", type: "Accounts")
                }
            }
        }
        
        // Prevent saving of empty LUTs to avoid situations where an empty LUT prevents regeneration of LUT.
        // (This is apotential problem for admin accounts which would cause repeated requesting of admin credentials)
        
        if uuidLut.count > 0 {
            json.save(to: lutFile)
        }
    }
    
    
    /// Regenerates the lookup table from the contents on disk
    
    func regenerateLuts() -> Bool {
        
        var nameLut: Dictionary<String, Int> = [:]
        var uuidLut: Dictionary<String, String> = [:]
        
        
        func processDirectory(dir: URL) -> Bool {
            
            let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            
            if let urls = urls {
                
                for url in urls {
                    
                    // If the url is a directory, then process it (recursive), if it is a file, try to read it as an account.
                    
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue {
                        
                        if !processDirectory(dir: url) {
                            return false
                        }
                        
                    } else {
                        
                        if let account = Account(url: url) {
                            
                            nameLut[account.name] = account.id
                            uuidLut[account.uuid] = account.name
                            
                        } else {
                            
                            Log.atCritical?.log("Failed to read account from \(url.path)", type: "Accounts")
                            return false
                        }
                    }
                }
                
                return true
                
            } else {
                
                Log.atCritical?.log("Failed to read account directories from \(dir.path)", type: "Accounts")
                return false
            }
        }
        
        Log.atWarning?.log("Attempting to recreate account LUT from raw account data", type: "Accounts")
        
        if processDirectory(dir: root) {
            
            self.nameLut = nameLut
            self.uuidLut = uuidLut
            
            Log.atNotice?.log("Regenerated the account LUT", type: "Accounts")
            return true
            
        } else {
            
            Log.atCritical?.log("Could not recreate account LUT from raw account data, accounts may have been lost!", type: "Accounts")
            return false
        }
    }

    
    /// Change the root directory url.
    ///
    /// - Note: This will only change the URL, not the disk contents.
    
    func changeRoot(to url: URL) {
        AccountManager.queue.async {
            self.root = url
        }
    }
}


// MARK: - Operational interface

extension AccountManager {
    
    
    /// Returns the account for the given name and password. First it will try to read the account from the cache. If the cache does not contain the account it will try to find it in the lookup table and if found, load it from file. The password hash must matches the account hash.
    ///
    /// - Parameters:
    ///   - for: The name of the account to find. May not be empty.
    ///   - using: The password over which to calculate the hash and compare it with the stored hash. May not be empty.
    ///
    /// - Returns: On success the account, otherwise nil.
    
    func getAccount(for name: String, using password: String) -> Account? {

        
        // Only valid parameters
        
        if password.isEmpty { return nil }
        if name.isEmpty { return nil }
        
        return AccountManager.queue.sync {

            
            // Try to extract it from the cache
            
            var account = accountCache[name]
            
            if account == nil {
                
                // Check the lookup table
            
                if let id = nameLut[name] {
                    if let a = Account(url: Account.createFileUrl(in: root, with: id)) {
                        accountCache[name] = a
                        account = a
                    }
                }
            }
            
            
            // Was an existing account found?
            
            if account == nil { return nil }
            
            
            // Check the password
            
            if account?.hasSameDigest(as: password) ?? false {
                return account
            } else {
                return nil
            }
        }
    }
    
    
    /// Create a new account and adds it to the cache.
    ///
    /// - Parameters:
    ///   - name: The name for the account, cannot be empty.
    ///   - password: The password over which to determine the password hash, may not be empty.
    ///
    /// - Returns: Nil if the input parameters are invalid or if the account already exists. The new account if it was created.
    
    func newAccount(name: String, password: String) -> Account? {
        
        return AccountManager.queue.sync {

            // Only valid parameters
            
            guard !password.isEmpty else { return nil }
            guard !name.isEmpty else { return nil }
            
            
            // Check if the account already exists
            
            if nameLut[name] != nil { return nil }
            
            
            // Create the new account
            
            lastAccountId += 1
            if let account = Account(id: lastAccountId, name: name, password: password, accountsRoot: root) {
            
                
                // Add it to the lookup's and the cache
            
                uuidLut[account.uuid] = name
                nameLut[name] = lastAccountId
                accountCache[name] = account
            
                
                // Save the lut
                
                saveLuts()
                
                return account
                
            } else {
                
                Log.atError?.log()
                return nil
            }
        }
    }
    
    
    /// Checks if an account exists for the given uuid string.
    ///
    /// - Parameter uuid: The uuid of the account to test for.
    ///
    /// - Returns: True if the uuid is contained in this list. False otherwise.
    
    func contains(_ uuid: String) -> Bool {
        return AccountManager.queue.sync {
            return uuidLut[uuid] != nil
        }
    }
    
    
    /// Checks if an account name is available.
    ///
    /// - Returns: True if the given name is available as an account name.
    
    func available(name: String) -> Bool {
        
        return AccountManager.queue.sync {
            return nameLut[name] == nil
        }
    }
}





