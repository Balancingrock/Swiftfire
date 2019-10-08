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
// 1.3.0 - Redesigned for easier & faster handling of accounts
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

fileprivate let ENABLED_NF = NameField("enab")!
fileprivate let NAME_NF = NameField("name")!
fileprivate let IS_DOMAIN_ADMIN_NF = NameField("isdad")!
fileprivate let IS_MODERATOR_NF = NameField("ismod")!
fileprivate let EMAIL_ADDRESS_NF = NameField("email")!
fileprivate let EMAIL_VERIFICATION_CODE_NF = NameField("emvcd")!
fileprivate let NEW_PWD_VERIFICATION_CODE_NF = NameField("npwdc")!
fileprivate let NEW_PWD_REQUEST_TIMESTAMP_NF = NameField("npwdt")!
fileprivate let DIGEST_NF = NameField("dgst")!
fileprivate let SALT_NF = NameField("salt")!
fileprivate let NOF_COMMENTS_NF = NameField("ncom")!


/// An account within swiftfire. Used for admin account and can be used for domain accounts as well.

public final class Account: EstimatedMemoryConsumption {
    
    // Note: This class uses the default EstimatedMemoryConsumption implementation.
    
    
    // MARK:- Public interface
    
    /// The path of the file containing this account
        
    public let dir: URL

    
    /// True if the account is active.
    ///
    /// An account is active if the email address has been verified and the account is enabled.
    
    public var isActive: Bool {
        return isEnabled && emailVerificationCode.isEmpty
    }
    
    
    /// True if the account is enabled.
    
    public var isEnabled: Bool {
        get {
            if let v = db.root[ENABLED_NF].bool { return v }
            Log.atError?.log("Error retrieving enabled from account store")
            return false
        }
        set {
            //db.root[ENABLED_NF].bool = newValue
            db.root.updateItem(newValue, withNameField: ENABLED_NF)
            store()
        }
    }

    
    /// The name for this account.
    
    public var name: String {
        get {
            if let v = db.root[NAME_NF].string { return v }
            Log.atError?.log("Error retrieving name from account store")
            return "***error***"
        }
        set {
            //db.root[NAME_NF].string = newValue
            db.root.updateItem(newValue, withNameField: NAME_NF)
            store()
        }
    }
    
    
    /// The email address for this account.
    
    public var emailAddress: String {
        get {
            if let v = db.root[EMAIL_ADDRESS_NF].string { return v }
            Log.atError?.log("Error retrieving emailAddress from account store")
            return "***error***"
        }
        set {
            //db.root[EMAIL_ADDRESS_NF].string = newValue
            db.root.updateItem(newValue, withNameField: EMAIL_ADDRESS_NF)
            store()
        }
    }

    
    /// The email verification code for this account.
    ///
    /// Should be empty for verified email addresses, should be a UUID-string when a verification email has been sent.
    
    public var emailVerificationCode: String {
        get {
            if let v = db.root[EMAIL_VERIFICATION_CODE_NF].string { return v }
            Log.atError?.log("Error retrieving emailVerificationCode from account store")
            return "***error***"
        }
        set {
            //db.root[EMAIL_VERIFICATION_CODE_NF].string = newValue
            db.root.updateItem(newValue, withNameField: EMAIL_VERIFICATION_CODE_NF)
            store()
        }
    }
    
    
    /// Controls if this user has access to domain administrator functions.
    ///
    /// Note that this does not control access to domain specific user functions, like forum administrator etc.
    
    public var isDomainAdmin: Bool {
        get {
            if let v = db.root[IS_DOMAIN_ADMIN_NF].bool { return v }
            Log.atError?.log("Error retrieving isAdmin from account store")
            return false
        }
        set {
            //db.root[IS_DOMAIN_ADMIN_NF].bool = newValue
            db.root.updateItem(newValue, withNameField: IS_DOMAIN_ADMIN_NF)
            store()
        }
    }
    
    
    /// The number of comments the user has made.
    
    public var nofComments: Int32 {
        get {
            if db.root[NOF_COMMENTS_NF].int32 == nil {
                db.root.updateItem(Int32(0), withNameField: NOF_COMMENTS_NF)
                store()
            }
            return db.root[NOF_COMMENTS_NF].int32!
        }
        set {
            //db.root[NOF_COMMENTS_NF].bool = newValue
            db.root.updateItem(newValue, withNameField: NOF_COMMENTS_NF)
            store()
        }
    }

    
    /// Controls if this user has moderator capabilities.
    ///
    /// Is always true for domain administrators.
    
    public var isModerator: Bool {
        get {
            if db.root[IS_MODERATOR_NF].bool == nil {
                db.root.updateItem(false, withNameField: IS_MODERATOR_NF)
                store()
            }
            let isMod = db.root[IS_MODERATOR_NF].bool!
            return isDomainAdmin || isMod
        }
        set {
            //db.root[IS_MODERATOR_NF].bool = newValue
            db.root.updateItem(newValue, withNameField: IS_MODERATOR_NF)
            store()
        }
    }
    
    

    /// The new password verification code for this account.
    ///
    /// Should be empty for verified email addresses, should be a UUID-string when a verification email has been sent.
    
    public var newPasswordVerificationCode: String {
        get {
            if let v = db.root[NEW_PWD_VERIFICATION_CODE_NF].string { return v }
            Log.atError?.log("Error retrieving newPasswordVerificationCode from account store")
            return "***error***"
        }
        set {
            //db.root[NEW_PWD_VERIFICATION_CODE_NF].string = newValue
            db.root.updateItem(newValue, withNameField: NEW_PWD_VERIFICATION_CODE_NF)
            store()
        }
    }

    
    /// The timestamp of the last new password request was made.
    ///
    /// Should be empty for verified email addresses, should be a UUID-string when a verification email has been sent.
    
    public var newPasswordRequestTimestamp: Int64 {
        get {
            if let v = db.root[NEW_PWD_REQUEST_TIMESTAMP_NF].int64 { return v }
            Log.atError?.log("Error retrieving newPasswordRequestTimestamp from account store")
            return 0 // always expired
        }
        set {
            //db.root[NEW_PWD_REQUEST_TIMESTAMP_NF].int64 = newValue
            db.root.updateItem(newValue, withNameField: NEW_PWD_REQUEST_TIMESTAMP_NF)
            store()
        }
    }

    
    // MARK:- Private from here
    
    
    /// The internal ID
    
    /// Path to the database that contains the data for this account
    
    private lazy var dbUrl: URL = {
        return dir.appendingPathComponent("account").appendingPathExtension("brbon")
    }()
    
    
    /// Data storage for the account.
    
    private var db: ItemManager!

    
    /// The digest for the user password.
    
    private var digest: String {
        get {
            if let v = db.root[DIGEST_NF].string { return v }
            Log.atError?.log("Error retrieving digest from account store")
            return "***error***"
        }
        set {
            //db.root[DIGEST_NF].string = newValue
            db.root.updateItem(newValue, withNameField: DIGEST_NF)
            // Note: No 'store' operation here, see 'updatePassword' for that
        }
    }
    
    
    /// The password salt
    
    private var salt: String {
        get {
            if let v = db.root[SALT_NF].string { return v }
            Log.atError?.log("Error retrieving salt from account store")
            return "***error***"
        }
        set {
            //db.root[SALT_NF].string = newValue
            db.root.updateItem(newValue, withNameField: SALT_NF)
            // Note: No 'store' operation here, see 'updatePassword' for that
        }
    }
    
    
    /// Create a new instance
    ///
    /// - Paramaters:
    ///   - id: A unique integer
    ///   - name: String, should be unique for this account.
    ///   - password: An integer that must be matched to allow somebody to use this account.
    ///   - accountDir: A URL pointing to the directory for the account. The directory will be created if it does not exist. No attempt will be made to initialize the account from the content of the directory (if any).
    
    init?(name: String, password: String, accountDir: URL) {
        
        do {
            try FileManager.default.createDirectory(atPath: accountDir.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Log.atError?.log("Cannot create account directory for \(name) at \(accountDir.path) with message: \(error.localizedDescription)")
            return nil
        }

        self.dir = accountDir
        self.db = ItemManager.createDictionaryManager()
        
        self.salt = createSalt()
        guard let pwdDigest = createDigest(for: password, with: self.salt) else { return nil }
        self.digest = pwdDigest
        
        self.name = name

        self.emailAddress = ""
        self.emailVerificationCode = ""
        self.isEnabled = true

        store()
    }
    
    
    /// Read the account parameters from a directory.
    
    init?(withContentOfDirectory accountDir: URL?) {
        
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


// MARK:- CustomStringConvertible

extension Account: CustomStringConvertible {
    
    
    /// CustomStringConvertible
    
    public var description: String {
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
    

// MARK: - Functional interface

extension Account {
    
    
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
        
        guard store() else {
            self.salt = oldSalt
            self.digest = oldDigest
            return false
        }
        
        return true
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

