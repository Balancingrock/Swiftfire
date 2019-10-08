// =====================================================================================================================
//
//  File:       Comment.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Initial version
//
// =====================================================================================================================

import Foundation

import BRBON


fileprivate let ORIGINAL_NF = NameField("orig")!
fileprivate let HTMLIFIED_NF = NameField("html")!
fileprivate let HTMLIFIED_VERSION_NF = NameField("vers")!
fileprivate let ID_NF = NameField("id")!
fileprivate let ORIGINAL_TIMESTAMP_NF = NameField("ots")!
fileprivate let LAST_UPDATE_TIMESTAMP_NF = NameField("lut")!
fileprivate let NOF_UPDATES_NF = NameField("nup")!
fileprivate let DISPLAY_NAME_NF = NameField("dname")!


/// Every comment made by a use will be wrapped in an object of this class before it is written to permanent storage.

public final class Comment {
    
    
    /// Remove all '<'and '>' signs.
    
    public static func removeHtml(_ comment: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<|>", options: .init())
        let result = regex.stringByReplacingMatches(in: comment, options: .init(), range: NSRange(location: 0, length: comment.count), withTemplate: "")
        return result
    }
    
    
    /// Version number of the htmlify-er
    
    static let htmlifyVersion: UInt8 = 1


    /// Creates a string with HTML formatting for italics and bold text.
    ///
    /// -Note: Be sure to update the 'htmlifyVersion' if this operation is changed
    ///
    /// Accepted formatting: [i][/], [b][/]
    
    public static func htmlify(_ comment: String) -> String {
        
        let replace: Dictionary<String, String> = [
            "[i]" : "<span style=\"font-style:italic\"",
            "[b]" : "<span style=\"font-weigth:bold\"",
            "[/]" : "</span>"
        ]
        
        var result = comment
        
        for (key, value) in replace {
            result = result.replacingOccurrences(of: key, with: value)
        }
        
        return result
    }
    
    
    /// The storage manager
    
    let db: ItemManager
    
    
    /// The URL where this comment was/will-be stored
    
    let url: URL
    
    
    /// Creates a new comment. The new comment will be HTMLified and immediately written to storage.
    ///
    /// Empty comments will not result in a new object, but will return nil.
    ///
    /// The name of the associated file will be the current UNIX timestamp (as string)
    ///
    /// - Parameters:
    ///     - text: The text for the comment as typed in by the user. Note that the characters '<' and '>' will be removed.
    ///     - relativePath: The path where the comment will be stored relative to the account directory..
    ///     - displayName: Will be stored alongside the text, intended to be used as replacement for the author field when the Anon account is used.
    ///     - account: The account to use to store this comment
    
    public init?(text: String, relativePath: String, displayName: String, account: Account) {
        
        guard !text.isEmpty else { return nil }
        
        
        // Make sure the comments directory is available
        
        let dir = account.dir.appendingPathComponent(relativePath, isDirectory: true)
        
        guard (try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)) != nil else {
            Log.atError?.log("Cannot create directory path for \(dir.path)")
            return nil
        }

        
        // If a file already exists, increment the timestamp until a non-existing file URL is created
        
        var i = Date().unixTime
        var flag = false
        var fileUrl: URL!
        while !flag {
            fileUrl = dir.appendingPathComponent(i.description).appendingPathExtension("brbon")
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                i += 1
            } else {
                flag = true
            }
            if i > 10 {
                Log.atAlert?.log("Too many post attempts by single user: \(account.name)")
                return nil
            }
        }
        self.url = fileUrl
        
        // Make the input save by removing the < and >
        
        let noHtml = Comment.removeHtml(text)
        
        
        // Add formatting
        
        let markedUp = Comment.htmlify(noHtml)
        
        
        // Initialize the db
        
        db = ItemManager.createDictionaryManager()
        db.root.updateItem(noHtml, withNameField: ORIGINAL_NF)
        db.root.updateItem(markedUp, withNameField: HTMLIFIED_NF)
        db.root.updateItem(Comment.htmlifyVersion, withNameField: HTMLIFIED_VERSION_NF)
        db.root.updateItem(UUID().uuidString, withNameField: ID_NF)
        db.root.updateItem(i, withNameField: ORIGINAL_TIMESTAMP_NF)
        db.root.updateItem(UInt16(0), withNameField: NOF_UPDATES_NF)
        db.root.updateItem(i, withNameField: LAST_UPDATE_TIMESTAMP_NF)
        db.root.updateItem(displayName, withNameField: DISPLAY_NAME_NF)
        
        
        // Save it
        
        if (try? db.data.write(to: url)) != nil {
            Log.atError?.log("Failed to write comment to file \(url.path)")
        }
    }
    
    
    /// Read a comment from file. The htmlified expression will be updated if a new verion of the htmlifier is available. Any change will immediately be saved.
    
    public init?(url: URL?) {
        
        guard let url = url else { return nil }
        
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else {
            Log.atError?.log("Cannot read comment file at \(url.path)")
            return nil
        }
                
        guard let im = ItemManager(from: url) else {
            Log.atDebug?.log("Cannot create item manager from file at \(url.path)")
            return nil
        }
        
        self.url = url
        self.db = im
        
        
        // Upgrade htmlified if there is a new version
        
        if self.htmlifiedVersion < Comment.htmlifyVersion {
            
            db.root.updateItem(Comment.htmlify(self.original), withNameField: HTMLIFIED_NF)
            db.root.updateItem(Comment.htmlifyVersion, withNameField: HTMLIFIED_VERSION_NF)
            
            // Save it
            
            if (try? db.data.write(to: url)) != nil {
                Log.atError?.log("Failed to write comment to file \(url.path)")
            }
        }
    }
    
    
    /// The original comment (after removing the < and >)
    
    public var original: String { return db.root[ORIGINAL_NF].string ?? "" }
    
    
    /// The formatted comment (replace [] with HTML)
    
    public var htmlified: String { return db.root[HTMLIFIED_NF].string ?? "" }
    
    
    /// The ID of this comment
    
    public var id: String { return db.root[ID_NF].string ?? "" }
    
    
    /// The version of the htmlified conversion
    
    private var htmlifiedVersion: UInt8 { return db.root[HTMLIFIED_VERSION_NF].uint8 ?? 0 }


    /// The original timestamp of posting
    
    public var originalTimestamp: Int64 { return db.root[ORIGINAL_TIMESTAMP_NF].int64 ?? 0 }
    
    
    /// The last update timestamp
    
    public var lastUpdateTimestamp: Int64 { return db.root[LAST_UPDATE_TIMESTAMP_NF].int64 ?? 0 }
    
    
    /// The total number f updates
    
    public var totalNumberOfUpdates: UInt16 { return db.root[NOF_UPDATES_NF].uint16 ?? 0 }

    
    /// Replace the original comment. Stores immediately after updating.
    /// Increments the total number of updates
    /// Updates the timestamp of last update.
    
    public func replaceText(with comment: String) {
        
        
        // Make the input save by removing the < and >
        
        let noHtml = Comment.removeHtml(comment)
        
        
        // Add formatting
        
        let markedUp = Comment.htmlify(noHtml)
        
        
        // Update the db
        
        db.root.updateItem(noHtml, withNameField: ORIGINAL_NF)
        db.root.updateItem(markedUp, withNameField: HTMLIFIED_NF)
        db.root.updateItem(Comment.htmlifyVersion, withNameField: HTMLIFIED_VERSION_NF)
        db.root.updateItem((totalNumberOfUpdates + 1), withNameField: NOF_UPDATES_NF)
        db.root.updateItem(Date().unixTime, withNameField: LAST_UPDATE_TIMESTAMP_NF)

        
        if (try? db.data.write(to: url)) != nil {
            Log.atError?.log("Failed to write updated comment to file \(url.path)")
        }
    }
}
