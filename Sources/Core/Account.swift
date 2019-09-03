// =====================================================================================================================
//
//  File:       Account.swift
//  Project:    Swiftfire
//
//  Version:    1.2.0
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
// 1.2.0 - Changed the way the account directory is handled
//       - Added the isAdmin member
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import SwifterLog
import VJson
import KeyedCache
import COpenSsl
import BRBON


/// An account within swiftfire. Used for admin account and can be used for domain accounts as well.

public final class Account: EstimatedMemoryConsumption {
    
    // Note: It uses the default EstimatedMemoryConsumption implementation.
    
    
    /// A public unique identifier that can be used to reference this account
    
    public private(set) var uuid: String

    
    /// The name for this account. When the name is updated, it is automatically persisted. If persistence fails, the name is not updated. Protected against empty names, too long names (max 32 char) and too many name changes (max 19).
    ///
    /// - Note: Updates are not thread safe, make sure that the session is 'exclusive' before updating.
    
    public var name: String {
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

            if let error = store() {
                Log.atError?.log("Cannot save account \(self), name not changed, error message = \(error)", type: "Account")
                names.removeFirst()
            }
        }
    }

    
    /// A unique id for this account, used for storage purposes only.
    
    private(set) var id: Int = 0
    
    
    /// The names that have been associated with this account, the name at index 0 is the used name. Other names are historical.
    
    private var names: Array<String> = []
    
    
    /// The digest for the user password.
    
    private var digest: String!
    
    
    /// The password salt
    
    private var salt: String!
    
    
    /// The path of the file containing this account
    
    fileprivate var dir: URL
    
    
    /// Convenience data storage for data that needs to be associated with the account. Use for small amounts only. Not thread save.
    ///
    /// - Note: Updates are __not__ stored automatically. You must call _storeInfo_ to ensure persistence of the data.
    ///
    /// - Note: Updates are not thread safe, make sure that the session is 'exclusive' before updating.
    ///
    /// - Note: Be carefull: attackers may try to bring a site down by storing illegal or too much data. Never store data untested for validity and size.
    
    public var info: ItemManager!
    
    
    /// Controls access to admin features of a domain. Note that the serveradmin is its own group, not covered by this member.
    
    public var isAdmin: Bool = false {
        didSet {
            if let error = store() {
                Log.atError?.log("Failed to save account update\n\n\(self),\n\n Error message = \(error)\n")
            }
        }
    }
    
    
    /// Create a new instance
    ///
    /// - Paramaters:
    ///   - id: A unique integer
    ///   - name: String, should be unique for this account.
    ///   - password: An integer that must be matched to allow somebody to use this account.
    ///   - accountDir: A URL pointing to the directory for the account. The directory will be created if it does not exist. No attempt will be made to initialize the account from the content of the directory (if any).
    
    init?(id: Int, name: String, password: String, accountDir: URL) {
        
        self.id = id
        self.uuid = UUID().uuidString
        self.names.insert(name, at: 0)
        self.dir = accountDir
        
        do {
            try FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log("Cannot create account directory for \(name) at \(dir.path) with message: \(error.localizedDescription)")
            return nil
        }

        let salt = createSalt()
        guard let digest = createDigest(for: password, with: salt) else { return nil }
        
        self.salt = salt
        self.digest = digest
        
        if let error = store() {
            Log.atError?.log("Cannot save account\n\n\(self),\n\n Error message = \(error)\n")
            return nil
        }
    }
    
    
    /// Read the account parameters from a directory.
    
    init?(withContentOfDirectory dir: URL) {
        
        self.dir = dir
        
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { return nil }
        
        let file = dir.appendingPathComponent("account").appendingPathExtension("json")
        
        guard let json = ((try? VJson.parse(file: file)) as VJson??) else { return nil }
        
        
        // Initial members
        
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

        self.names = jnames
        self.id = jid
        self.uuid = juuid
        self.digest = jdigest
        self.salt = jsalt

        
        // Members added later (with default values)
        
        if let j = (json|"IsAdmin")?.boolValue { self.isAdmin = j }
        
        
        // The info part
        
        loadInfo()
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
        json["IsAdmin"] &= isAdmin
        
        return json
    }

    
    /// Save the user data to file.
    ///
    /// - Returns: On success nil, on failure a description of the error that occured.
    
    func store() -> String? {
        let file = dir.appendingPathComponent("account").appendingPathExtension("json")
        storeInfo()
        return self.json.save(to: file)
    }
    
    
    func storeInfo() {
        let file = dir.appendingPathComponent("info").appendingPathExtension("brbon")
        do {
            if let info = info {
                try info.data.write(to: file)
            }
        } catch let error {
            Log.atError?.log("Failed to store info for account \(name), message = \(error.localizedDescription)")
        }
    }
    
    func loadInfo() {
        let file = dir.appendingPathComponent("info").appendingPathExtension("brbon")
        if FileManager.default.isReadableFile(atPath: file.path) {
            info = ItemManager.init(from: file)
            if info == nil {
                Log.atError?.log("Failed to load info for account \(name), file = \(file.path)")
            }
        }
    }
}


// MARK:- JSON

extension Account: CustomStringConvertible {
    
    
    /// CustomStringConvertible
    
    public var description: String {
        var str = "Account\n"
        str += " Id: \(id)\n"
        str += " Uuid: \(uuid)\n"
        str += " Name: \(name)\n"
        str += " isAdmin: \(isAdmin)\n"
        str += " Digest: \(String(describing: digest))"
        if serverParameters.debugMode.value {
            str += "\n Salt: \(String(describing: salt))\n"
            if historicalNames.count == 0 {
                str += " No old names\n"
            } else {
                str += " Old names:\n"
                historicalNames.forEach({ str += "  \($0)\n"})
            }
        }
        return str
    }
}
    

// MARK: - Functional interface

extension Account {
    

    /// A list of all the old names this account has had.
    
    public var historicalNames: Array<String> {
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
    
    public func updatePassword(_ str: String) -> Bool {
        
        // Keep the old values until we are sure the old ones are saved.
        
        let oldSalt = self.salt
        let oldDigest = self.digest
        
        
        // Create and set the new values
        
        let salt = createSalt()
        guard let digest = createDigest(for: str, with: salt) else { return false }
        
        self.salt = salt
        self.digest = digest
        
        
        // Save the new values, if the save fails, then restore the old values.
        
        if let error = store() {
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
    
    public func hasSameDigest(as pwd: String) -> Bool {
        
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
            if saltData.withUnsafeBytes({ (bptr) -> Bool in
                return EVP_DigestUpdate(digester, bptr.baseAddress, saltData.count) == 0
            }) {
                Log.atEmergency?.log("Cannot update digest generator with salt", type: "Account")
                return nil
            }
        }

        
        // Add the string to the digester
        
        if let strData = str.data(using: String.Encoding.utf8) {
            if strData.withUnsafeBytes({ (bptr) -> Bool in
                return EVP_DigestUpdate(digester, bptr.baseAddress, strData.count) == 0
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

