// =====================================================================================================================
//
//  File:       Account.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
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
// 1.3.0 - Implemented thread protection
//       - Spilt off the estimated memory consumption protocol into an extension
//       - Redesigned for easier & faster handling of accounts
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


// These are a minor performance enhancement (as using a static namefield reduces runtime overhead, while restricting the name length to 5 chars optimizes memory)

fileprivate let ACCOUNT_ENABLED_NF = NameField("enab")!
fileprivate let ACCOUNT_UUID_NF = NameField("uuid")!
fileprivate let ACCOUNT_NAME_NF = NameField("name")!
fileprivate let ACCOUNT_IS_DOMAIN_ADMIN_NF = NameField("isdad")!
fileprivate let ACCOUNT_IS_MODERATOR_NF = NameField("ismod")!
fileprivate let ACCOUNT_EMAIL_ADDRESS_NF = NameField("email")!
fileprivate let ACCOUNT_EMAIL_VERIFICATION_CODE_NF = NameField("emvcd")!
fileprivate let ACCOUNT_NEW_PWD_VERIFICATION_CODE_NF = NameField("npwdc")!
fileprivate let ACCOUNT_NEW_PWD_REQUEST_TIMESTAMP_NF = NameField("npwdt")!
fileprivate let ACCOUNT_DIGEST_NF = NameField("dgst")!
fileprivate let ACCOUNT_SALT_NF = NameField("salt")!
fileprivate let ACCOUNT_NOF_COMMENTS_NF = NameField("ncom")!


/// An account within swiftfire. Used for admin account and can be used for domain accounts as well.

public final class Account {
    
    
    /// The queue on which all access is performed
    
    fileprivate static var queue = DispatchQueue(
        label: "Accounts",
        qos: DispatchQoS.default,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil
    )
    
    
    /// Data storage for the account.
    
    internal var db: ItemManager!

    
    // MARK:- Public interface

    
    /// The UUID for this account
    
    public lazy var uuid: UUID = {
        Account.queue.sync {
            if let v = db.root[ACCOUNT_UUID_NF].uuid { return v }
            Log.atCritical?.log("Error retrieving uuid from account store")
            // Note a random UUID is extremely unlikely to actually refer to an account, but it could happen. However given that this situation should never happen in the first place, this small risk is accepted. The only alternative would be to make the uuid an optional or to shut down the server.
            return UUID()
        }
    }()

    
    /// The path of the file containing this account
        
    public let dir: URL
    
    
    /// True if this account is the anonymous account
    
    public lazy var isAnon: Bool = {
        Account.queue.sync {
            guard let name = db.root[ACCOUNT_NAME_NF].string else {
                Log.atCritical?.log("Error retrieving name from account store")
                return false
            }
            return name.lowercased() == "anon"
        }
    }()
    
    
    /// True if the account is active.
    ///
    /// An account is active if the email address has been verified and the account is enabled.
    
    public var isActive: Bool {
        Account.queue.sync {
            guard let isEnabled = db.root[ACCOUNT_ENABLED_NF].bool else {
                Log.atCritical?.log("Error retrieving enabled from account store")
                return false
            }
            guard let emailVerificationCode = db.root[ACCOUNT_EMAIL_VERIFICATION_CODE_NF].string else {
                Log.atCritical?.log("Error retrieving emailAddress from account store")
                return false
            }
            return isEnabled && emailVerificationCode.isEmpty
        }
    }
    
    
    /// True if the account is enabled.
    ///
    /// An account is enabled by default. It should only be enabled/disabled by a domain admin.
    
    public var isEnabled: Bool {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_ENABLED_NF].bool { return v }
                Log.atCritical?.log("Error retrieving enabled from account store")
                return false
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_ENABLED_NF)
                store()
            }
        }
    }

    
    /// The name for this account.
    
    public var name: String {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_NAME_NF].string { return v }
                Log.atCritical?.log("Error retrieving name from account store")
                return "***error***"
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_NAME_NF)
                store()
            }
        }
    }
    
    
    /// The email address for this account.
    
    public var emailAddress: String {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_EMAIL_ADDRESS_NF].string { return v }
                Log.atCritical?.log("Error retrieving emailAddress from account store")
                return "***error***"
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_EMAIL_ADDRESS_NF)
                store()
            }
        }
    }

    
    /// The email verification code for this account.
    ///
    /// Should be empty for verified email addresses, should be a UUID-string when a verification email has been sent.
    
    public var emailVerificationCode: String {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_EMAIL_VERIFICATION_CODE_NF].string { return v }
                Log.atCritical?.log("Error retrieving emailVerificationCode from account store")
                return "***error***"
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_EMAIL_VERIFICATION_CODE_NF)
                store()
            }
        }
    }
    
    
    /// Controls if this user has access to domain administrator functions.
    ///
    /// Note that this does not control access to domain specific user functions, like forum administrator etc.
    
    public var isDomainAdmin: Bool {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_IS_DOMAIN_ADMIN_NF].bool { return v }
                Log.atCritical?.log("Error retrieving isAdmin from account store")
                return false
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_IS_DOMAIN_ADMIN_NF)
                store()
            }
        }
    }
    
    
    /// The number of comments the user has made.
    
    public var nofComments: Int32 {
        get {
            Account.queue.sync {
                if db.root[ACCOUNT_NOF_COMMENTS_NF].int32 == nil {
                    db.root.updateItem(Int32(0), withNameField: ACCOUNT_NOF_COMMENTS_NF)
                    store()
                }
                return db.root[ACCOUNT_NOF_COMMENTS_NF].int32!
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_NOF_COMMENTS_NF)
                store()
            }
        }
    }

    
    /// Controls if this user has moderator capabilities.

    public var isModerator: Bool {
        get {
            Account.queue.sync {
                if db.root[ACCOUNT_IS_MODERATOR_NF].bool == nil {
                    db.root.updateItem(false, withNameField: ACCOUNT_IS_MODERATOR_NF)
                    store()
                }
                return db.root[ACCOUNT_IS_MODERATOR_NF].bool!
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_IS_MODERATOR_NF)
                store()
            }
        }
    }
    
    
    /// The new password verification code for this account.
    ///
    /// Should be empty for verified email addresses, should be a UUID-string when a verification email has been sent.
    
    public var newPasswordVerificationCode: String {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_NEW_PWD_VERIFICATION_CODE_NF].string { return v }
                Log.atError?.log("Error retrieving newPasswordVerificationCode from account store")
                return "***error***"
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_NEW_PWD_VERIFICATION_CODE_NF)
                store()
            }
        }
    }

    
    /// The timestamp of the last new password request was made.
    ///
    /// Should be empty for verified email addresses, should be a UUID-string when a verification email has been sent.
    
    public var newPasswordRequestTimestamp: Int64 {
        get {
            Account.queue.sync {
                if let v = db.root[ACCOUNT_NEW_PWD_REQUEST_TIMESTAMP_NF].int64 { return v }
                Log.atError?.log("Error retrieving newPasswordRequestTimestamp from account store")
                return 0 // always expired
            }
        }
        set {
            Account.queue.sync {
                db.root.updateItem(newValue, withNameField: ACCOUNT_NEW_PWD_REQUEST_TIMESTAMP_NF)
                store()
            }
        }
    }

    
    // MARK:- Private from here
    
    
    /// The internal ID
    
    /// Path to the database that contains the data for this account
    
    private lazy var dbUrl: URL = {
        return dir.appendingPathComponent("account").appendingPathExtension("brbon")
    }()
    
    
    /// The digest for the user password.
    
    private var digest: String {
        get {
            if let v = db.root[ACCOUNT_DIGEST_NF].string { return v }
            Log.atError?.log("Error retrieving digest from account store")
            return "***error***"
        }
        set {
            db.root.updateItem(newValue, withNameField: ACCOUNT_DIGEST_NF)
            // Note: No 'store' operation here, see 'updatePassword' for that
        }
    }
    
    
    /// The password salt
    
    private var salt: String {
        get {
            if let v = db.root[ACCOUNT_SALT_NF].string { return v }
            Log.atError?.log("Error retrieving salt from account store")
            return "***error***"
        }
        set {
            db.root.updateItem(newValue, withNameField: ACCOUNT_SALT_NF)
            // Note: No 'store' operation here, see 'updatePassword' for that
        }
    }
    
    
    /// Create a new instance
    ///
    /// - Paramaters:
    ///   - name: String, should be unique for this account.
    ///   - password: An integer that must be matched to allow somebody to use this account.
    ///   - uuid: A unique UUID to identify this account.
    ///   - accountDir: A URL pointing to the directory for the account. The directory will be created if it does not exist. No attempt will be made to initialize the account from the content of the directory (if any).
    
    internal init?(name: String, password: String, uuid: UUID, accountDir: URL) {
        
        do {
            try FileManager.default.createDirectory(atPath: accountDir.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log("Cannot create account directory for \(name) at \(accountDir.path) with message: \(error.localizedDescription)")
            return nil
        }

        self.dir = accountDir

        self.db = ItemManager.createDictionaryManager()
        self.db.root.updateItem(uuid, withNameField: ACCOUNT_UUID_NF)
        self.db.root.updateItem(name, withNameField: ACCOUNT_NAME_NF)
        self.db.root.updateItem("", withNameField: ACCOUNT_EMAIL_ADDRESS_NF)
        self.db.root.updateItem("not verified yet", withNameField: ACCOUNT_EMAIL_VERIFICATION_CODE_NF) // this deactivates the account
        self.db.root.updateItem(true, withNameField: ACCOUNT_ENABLED_NF)
        self.db.root.updateItem(false, withNameField: ACCOUNT_IS_MODERATOR_NF)
        self.db.root.updateItem(false, withNameField: ACCOUNT_IS_DOMAIN_ADMIN_NF)
        self.db.root.updateItem(Int32(0), withNameField: ACCOUNT_NOF_COMMENTS_NF)
        self.db.root.updateItem(Int64(0), withNameField: ACCOUNT_NEW_PWD_REQUEST_TIMESTAMP_NF)
        self.db.root.updateItem("", withNameField: ACCOUNT_NEW_PWD_VERIFICATION_CODE_NF)
        
        let salt = createSalt()
        guard let pwdDigest = createDigest(for: password, with: salt) else { return nil }

        self.db.root.updateItem(salt, withNameField: ACCOUNT_SALT_NF)
        self.db.root.updateItem(pwdDigest, withNameField: ACCOUNT_DIGEST_NF)
        
        store()
    }
    
    
    /// Read the account parameters from a directory.
    
    internal init?(withContentOfDirectory accountDir: URL?) {
        
        guard let accountDir = accountDir else { return nil }
        
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: accountDir.path, isDirectory: &isDir), isDir.boolValue else {
            Log.atError?.log("The account directory at \(accountDir.path) does not exist")
            return nil
        }

        self.dir = accountDir

        guard let im = ItemManager.init(from: dbUrl) else {
            Log.atError?.log("The account db file at \(dbUrl.path) failed to load")
            return nil
        }
        
        self.db = im
    }

    
    /// Save the account data to file.
    
    @discardableResult
    private func store() -> Bool {
        do {
            try db.data.write(to: dbUrl)
        }
        catch let error {
            Log.atError?.log("An error occured when saving the account database: \(error.localizedDescription)")
            return false
        }
        return true
    }
}


// MARK: - EstimatedMemoryConsumption

extension Account: EstimatedMemoryConsumption {

    public var estimatedMemoryConsumption: Int {
        Account.queue.sync { return self.db.root.count }
    }
}


// MARK:- CustomStringConvertible

extension Account: CustomStringConvertible {
    
    
    /// CustomStringConvertible
    
    public var description: String {
        Account.queue.sync {
            guard let name = db.root[ACCOUNT_NAME_NF].string else {
                Log.atCritical?.log("Error retrieving name from account store")
                return "***error***"
            }
            guard let isDomainAdmin = db.root[ACCOUNT_IS_DOMAIN_ADMIN_NF].bool else {
                Log.atCritical?.log("Error retrieving isAdmin from account store")
                return "***error***"
            }
            var str = "Account\n"
            str += " Name: \(name)\n"
            str += " isDomainAdmin: \(isDomainAdmin)\n"
            str += " Digest: \(String(describing: digest))"
            if serverParameters.debugMode.value {
                str += "\n Salt: \(String(describing: salt))\n"
            }
            return str
        }
    }
}
    

// MARK: - Functional interface

extension Account {
    
    
    /// Increase the number of comments associated with this account
    
    public func increaseNofComments() {
        if !isAnon { nofComments += 1 }
    }
    
    
    /// Decrease the number of comments associated with this account
    
    public func decrementNofComments() {
        if !isAnon { nofComments -= 1 }
    }
    
    
    /// Update password (digest). A new salt is created also. If the operation fails, the values of the salt and the digest will remain as they are.
    ///
    /// - Parameter str: The new password. Note that the password itself is not stored, only the digest.
    ///
    /// - Returns: True if the operation succeeded, false if not.
    
    public func updatePassword(_ str: String) -> Bool {
        
        Account.queue.sync {
            
            // Keep the old values until we are sure the old ones are saved.
            
            let oldSalt = self.salt
            let oldDigest = self.digest
            
            
            // Create and set the new values
            
            let salt = createSalt()
            guard let digest = createDigest(for: str, with: salt) else { return false }
            
            self.salt = salt
            self.digest = digest
            
            
            // Save the new values, if the save fails, then restore the old values.
            
            guard store() else {
                self.salt = oldSalt
                self.digest = oldDigest
                return false
            }
            
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
        
        Account.queue.sync {
            guard let testDigest = createDigest(for: pwd, with: salt) else {
                Log.atCritical?.log("Cannot create digest", type: "Account")
                return false
            }
        
            return digest == testDigest
        }
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

extension Account: FunctionsInfoDataSource {
    
    public func addSelf(to info: inout Functions.Info) {
        Account.queue.sync {
            db.root.addSelf(to: &info)
            // Remove sensitive info
            info.removeValue(forKey: ACCOUNT_SALT_NF.string)
            info.removeValue(forKey: ACCOUNT_DIGEST_NF.string)
        }
    }
}
