// =====================================================================================================================
//
//  File:       CommentManager.swift
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


// The Comment System:
//
// The raw comments are stored in the user account of the user that made the comment.
// If anonymous users are allowed to comment, the user "Anon" will be the designated user.
// The comments will have the filename: <timestamp>.brbon
//
// <timestamp> = Unix timestamp, i.e. seconds since 1 Jan 1970, of the time the comment was made.
//
//
// There is a second (comments) directory hierarchy in the domain which has a directory for each webpage that has comments.
// In this directory a table is stored that maintains a list of file URLs pointing to the raw comments in the account directories.
// Also, in this directory a pre-parsed (cached) HTML block is present that contains the comments as they should be displayed.
//
// When a comment is added the file url is added to the table, but the comment itself is not added to the processed html comment block.
// If a comment was updated, the table will be updated to reflect this, but the comment block will not be updated immediately.
//
// The comment block will be returned upon request, but when there are pending updates, it will be updated or recreated first when necessary.
//
// There is a feature that will prevent a comment from beiing shown until a moderator has reviewed it.
// This will happen for the first N comments where N can be set by a domain admin.
// Once an account surpasses N, all comments will be published immediately.
// If N is set to >99, it will permanently block all comments until review.
//
// Comments under review will be referenced from the comments-review list
//
// Access to the comments system must be serialized to prevent illegal situations where multiple users are updaing the comments simultaniously.


fileprivate let COMMENT_BLOCK_TEMPLATE = "/templates/commentBlock.sf.html"
fileprivate let COMMENT_INPUT_TEMPLATE = "/templates/commentInput.sf.html"


// For the comment block table

fileprivate let COMMENT_URL_NF = NameField("cu")!
fileprivate let COMMENT_URL_CS = ColumnSpecification(type: .string, nameField: COMMENT_URL_NF, byteCount: 128)
fileprivate let COMMENT_URL_INDEX = 0

fileprivate let NEEDS_UPDATE_NF = NameField("nu")!
fileprivate let NEEDS_UPDATE_CS = ColumnSpecification(type: .bool, nameField: NEEDS_UPDATE_NF, byteCount: 1)
fileprivate let NEEDS_UPDATE_INDEX = 1

fileprivate var COMMENT_TABLE_SPECIFICATION = [NEEDS_UPDATE_CS, COMMENT_URL_CS]


// The comment table (above) is wrapped in a dictionary to ease upgrading

fileprivate let COMMENT_TABLE_NF = NameField("ctb")!


/// Manages the comments for a domain.

public final class CommentManager {
    
    
    /// Creates a relative directory path from a base url and the identifier
    
    static func identifier2RelativePath(_ identifier: String) -> String? {
        
        
        // Reform the identifier and remove all leading dots
        
        var pid = identifier.lowercased()
        while pid.first == "." { pid.removeFirst() }
        
        
        // There must be at least one character left
        
        guard !pid.isEmpty else { return nil }

        
        // Transform the identifier into a relative path

        return pid.replacingOccurrences(of: ".", with: "/")
    }

    
    /// The queue on which all work will be serialized.
    
    private let queue = DispatchQueue.init(label: "CommentsAccess", qos: DispatchQoS.userInitiated, attributes: DispatchQueue.Attributes.init(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem, target: nil)
    
    
    /// The list with comments to be approaved
    
    public var commentsForApproval: Array<Comment> = []

    
    // A pointer to the domain for these comments
    
    unowned let domain: Domain
    
    
    /// Create a new comment handler
    
    init(_ domain: Domain) {
        self.domain = domain
    }
    

    /// Returns the entire comment section including the input field for new comments if an account is present.
    ///
    /// - Parameters:
    ///   - for: The identifier for the comment section.
    ///   - account: The account for the input sub-section. If nil, there will be no input subsection.
    ///
    /// - Returns: The UTF8 encoded HTML code. Will contain '***error***' if an error occured. May be empty if there are no comments and no account is given.
    
    func getCommentSection(for identifier: String, account: Account?) -> Data {
        
        return queue.sync {
            
            
            // Get the relative path for the comment table
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return "***error***".data(using: .utf8)!
            }

            
            // Get the url of the comment table
            
            guard let commentTableUrl = commentTableFileUrl(relativePath: relativePath) else {
                // Error log has been made
                return "***error***".data(using: .utf8)!
            }

            
            // Get the comment table
            
            guard let (itemManager, table) = loadCommentTable(url: commentTableUrl) else {
                Log.atError?.log("ItemManager should be available at \(commentTableUrl.path)")
                return "***error***".data(using: .utf8)!
            }

            
            // Check for updates to the comment table
            
            var midTableUpdate: Bool = false
            var endTableUpdate: Bool = false
            var indexOfEndTableUpdate: Int = table.count
            
            table.itterateFields(ofColumn: NEEDS_UPDATE_INDEX) { (portal, index) -> Bool in

                guard let updated = portal.bool else {
                    Log.atError?.log("Wrong type in table column NEEDS_UPDATE_INDEX")
                    return false
                }
                
                if updated {
                    endTableUpdate = true
                    indexOfEndTableUpdate = index
                } else {
                    if endTableUpdate {
                        midTableUpdate = true
                    }
                }
                
                return true
            }
            
            
            // Three possibilities:
            // 1. Build new comment cache, 2. Append new entries to comment cache, 3. Return comment cache as is
            
            guard let commentCacheUrl = commentCacheFileUrl(relativePath: relativePath) else {
                return "***error***".data(using: .utf8)!
            }

            if !FileManager.default.fileExists(atPath: commentCacheUrl.path) {
                // The cache must be created, simulate a mid-cache update
                endTableUpdate = true
                midTableUpdate = true
            }
            
            if !endTableUpdate { // Nothing to update (or create), the cache is still valid
                
                do {
                    return try Data.init(contentsOf: commentCacheUrl)
                } catch let error {
                    Log.atError?.log("Cannot read comment cache error = \(error.localizedDescription)")
                    return "***error***".data(using: .utf8)!
                }
            }
            
            if !midTableUpdate { // Append to the end of the cache
                
                
            }
            
            return Data()
        }
    }
    

    /// Updates the comments section for the given comment. This may invalidate cached values.
    ///
    /// - Parameters:
    ///   - text: The comment that was made.
    ///   - identifier: The identifier for the comment section.
    ///   - displayName: A display name for the Anon account.
    ///   - account: The account for the comment.

    func add(text: String, identifier: String, displayName: String, account: Account?) {
        
        
        // Make sure there is an account
        
        guard let account = account ?? domain.accounts.getAccountWithoutPassword(for: "Anon") else {
            Log.atError?.log("Failed to retrieve Anon account")
            return
        }
        
        guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
            Log.atError?.log("The relative path cannot be empty (identifier error)")
            return
        }
        
        queue.sync {
            
            guard let comment = Comment(text: text, relativePath: relativePath, displayName: displayName, account: account) else {
                Log.atError?.log("Failed to create a new comment")
                return
            }

            if account.name == "Anon" {
                domain.comments.commentsForApproval.append(comment)
            } else {
                if account.nofComments <= domain.autoCommentApprovalThreshold {
                    domain.comments.commentsForApproval.append(comment)
                } else {
                    account.nofComments += 1
                    addCommentToCommentTable(comment, relativePath)
                }
            }
        }
    }
    
    
    /// Updates the text of an existing comment.
    ///
    /// - Parameters:
    ///   - text: The comment that was made.
    ///   - identifier: The identifier for the comment section.
    ///   - account: The account for the comment.
    ///   - originalTimestamp: The timestamp the comment was made.

    func update(text: String, identifier: String, account: Account, originalTimestamp: String) {
        
        queue.sync {
            
            
            // Get the relative path from the identifier
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return
            }

            
            // Get the comment itself
            
            guard let comment = self.loadComment(relativePath, account, timestamp: originalTimestamp) else {
                // Error log has been made
                return
            }

            
            // Get the comment table field that must be updated (search algo)
            
            guard let commentTableUrl = commentTableFileUrl(relativePath: relativePath) else {
                // Error log has been made
                return
            }
            
            
            // Get the table and its manager
            
            guard let (itemManager, table) = loadCommentTable(url: commentTableUrl) else {
                Log.atError?.log("ItemManager should be available at \(commentTableUrl.path)")
                return
            }

            
            // Get the index of the comment to be updated
            
            guard let index = table.indexForComment(comment) else {
                Log.atError?.log("Comment \(comment.url.path) not found in table \(commentTableUrl.path)")
                return
            }
            
            
            // Update table and comment
            
            comment.replaceText(with: text) // autosave
            table[index, NEEDS_UPDATE_INDEX].bool = true
            
            
            // Save the table
            
            guard (try? itemManager.data.write(to: commentTableUrl)) != nil else {
                Log.atError?.log("Error saving updated table \(commentTableUrl.path)")
                return
            }
        }
    }
    
    
    /// Rejects a comment that was waiting for approval
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the comment section.
    ///   - account: The account for the comment.
    ///   - originalTimestamp: The timestamp the comment was made.

    func reject(identifier: String, account: Account, originalTimestamp: String) {
        
        queue.async { [identifier, account, originalTimestamp, weak self] in
            
            
            // Make sure the comments are available
            
            guard let self = self else { return }

            
            // Get the relative path from the identifier
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return
            }

            
            // Load the comment itself
                        
            guard let comment = self.loadComment(relativePath, account, timestamp: originalTimestamp) else {
                // Error log has been made
                return
            }

            
            // Remove it from the waiting list
            
            self.commentsForApproval.removeObject(object: comment)
            
            
            // And remove it from the account comment area
            
            if (try? FileManager.default.removeItem(at: comment.url)) == nil {
                Log.atCritical?.log("Cannot remove coment at \(comment.url.path), the file for this comment is now orphaned!")
            }
        }
    }
    
    
    /// Removes a comment from both the comment table and the account.
    ///
    /// It is assumed that only registered users and the admin can remove comments.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the comment section.
    ///   - account: The account for the comment.
    ///   - originalTimestamp: The timestamp the comment was made.

    func remove(identifier: String, account: Account, originalTimestamp: String) {
        
        queue.sync {
            
            // Get the relative path from the identifier
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return
            }

            
            // Get the comment itself
                        
            guard let comment = loadComment(relativePath, account, timestamp: originalTimestamp) else {
                // Error log has been made
                return
            }
                        
            
            // Get the comment table url
            
            guard let commentTableUrl = commentTableFileUrl(relativePath: relativePath) else {
                // Error log has been made
                return
            }
            
            
            // Load the cooment table and its manager
            
            guard let (itemManager, table) = loadCommentTable(url: commentTableUrl) else {
                Log.atError?.log("ItemManager should be available at \(commentTableUrl.path)")
                return
            }
            
            
            // Get the index for the comment to be removed
            
            guard let index = table.indexForComment(comment) else {
                Log.atError?.log("Comment \(comment.url.path) not found in table \(commentTableUrl.path)")
                return
            }
            
            
            // Update table
            
            table.removeRow(index)
            
            
            // Remove it from the account comment area
            
            if (try? FileManager.default.removeItem(at: comment.url)) == nil {
                Log.atCritical?.log("Cannot remove coment at \(comment.url.path), the file for this comment is now orphaned!")
            }
            
            
            // Save the table
            
            guard (try? itemManager.data.write(to: commentTableUrl)) != nil else {
                Log.atError?.log("Error saving updated table \(commentTableUrl.path)")
                return
            }
        }

    }
    
    
    /// Removes a comment from the waiting-for-approval list and adds it to the comment block
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the comment section.
    ///   - account: The account for the comment.
    ///   - originalTimestamp: The timestamp the comment was made.

    func approve(identifier: String, account: Account, originalTimestamp: String) {
        
        queue.async { [identifier, account, originalTimestamp, weak self] in
            
            
            // Make sure the comments are available
            
            guard let self = self else { return }
            
            
            // Get the relative path from the identifier
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return
            }

            
            // Load the comment itself
                        
            guard let comment = self.loadComment(relativePath, account, timestamp: originalTimestamp) else {
                // Error log has been made
                return
            }

            
            // Remove it from the waiting list
            
            self.commentsForApproval.removeObject(object: comment)

            
            // Add it to the comment table
            
            self.addCommentToCommentTable(comment, relativePath)
        }
    }
    
    
    
    /// Updates (or creates) the comment block for a new comment
    ///
    /// - Note: Should only be called from operations that run on the comment queue.
    ///
    /// - Parameters:
    ///   - comment: The comment to be added.
    ///   - relativePath: The relative path of the comment and the comment table.

    private func addCommentToCommentTable(_ comment: Comment, _ relativePath: String) {
        
    
        // Get the url for the table
        
        guard let commentTableFileUrl = commentTableFileUrl(relativePath: relativePath) else {
            // Error log entry has already been generated
            return
        }

        
        // Get the comment table
        
        guard let (itemManager, table) = loadCommentTable(url: commentTableFileUrl, createIfMissing: true) else {
            Log.atError?.log("Cannot add to comment table")
            return
        }
        
        
        // Update the table
        
        table.addRows(1) { (portal) in
            switch portal.column {
            case COMMENT_URL_INDEX: portal.crcString = BRCrcString(comment.url.path)
            case NEEDS_UPDATE_INDEX: portal.bool = true
            default:
                Log.atError?.log("Unknown table index \(portal.column ?? -1)")
            }
        }
        
        
        // Save the table
        
        guard (try? itemManager.data.write(to: commentTableFileUrl)) != nil else {
            Log.atError?.log("Cannot write comment table file to \(commentTableFileUrl.path)")
            return
        }
    }
    
    
    /// Load a comment
    ///
    /// - Parameters:
    ///   - relativePath: The relative path of the comment and the comment table.
    ///   - account: The account for the comment.
    ///   - timestamp: The timestamp the comment was made.

    private func loadComment(_ relativePath: String, _ account: Account, timestamp: String) -> Comment? {
        
        let commentUrl = account.dir.appendingPathComponent(relativePath, isDirectory: false).appendingPathComponent(timestamp, isDirectory: false).appendingPathExtension("brbon")
        
        guard let comment = Comment(url: commentUrl) else {
            Log.atError?.log("Comment not found for path \(commentUrl.path)")
            return nil
        }

        return comment
    }
    
    
    /// Return the path to the commentTable.
    ///
    /// - Parameter relativePath: The relative path (to the comments-root of the domain) to the directory in which the comment table must be located.
    ///
    /// - Returns: The url for the file (either present or when it can be created). Nil when an error occured. If an error occured, an error log entry wil have been made.
    
    private func commentTableFileUrl(relativePath: String) -> URL? {
        
        
        // The target directory
        
        guard let rootDir = Urls.domainCommentsRootDir(for: domain.name) else {
            Log.atError?.log("Cannot retrieve comments root directory")
            return nil
        }
        
        let dir = rootDir.appendingPathComponent(relativePath, isDirectory: true)
        
        let name = "commentTable.brbon"
        
        
        switch FileManager.default.testFor(dir.path, file: name, createDir: true) {
        
        case .fail:
            Log.atError?.log("Cannot read or write comment table in \(dir.path)")
            return nil
        
        case .isReadableFile:
            Log.atError?.log("Cannot write comment table in \(dir.path)")
            return nil

        case .isWriteableFile:
            return dir.appendingPathComponent(name, isDirectory: false)
            
        case .isReadableDir:
            Log.atError?.log("Cannot read directory for comment table in \(dir.path)")
            return nil

        case .isWriteableDir:
            return dir.appendingPathComponent(name, isDirectory: false)
        }
    }

    
    /// Return the path to the commentCache.
    ///
    /// - Parameter relativePath: The relative path (to the comments-root of the domain) to the directory in which the comments cache must be located.
    ///
    /// - Returns: The url for the file (either present or when it can be created). Nil when an error occured. If an error occured, an error log entry wil have been made.
    
    private func commentCacheFileUrl(relativePath: String) -> URL? {
        
        
        // The target directory
        
        guard let rootDir = Urls.domainCommentsRootDir(for: domain.name) else {
            Log.atError?.log("Cannot retrieve comments root directory")
            return nil
        }
        
        let dir = rootDir.appendingPathComponent(relativePath, isDirectory: true)
        
        let name = "commentCache.html"
        
        
        switch FileManager.default.testFor(dir.path, file: name, createDir: true) {
        
        case .fail:
            Log.atError?.log("Cannot read or write comment cache in \(dir.path)")
            return nil
        
        case .isReadableFile:
            Log.atError?.log("Cannot write comment cache in \(dir.path)")
            return nil

        case .isWriteableFile:
            return dir.appendingPathComponent(name, isDirectory: false)
            
        case .isReadableDir:
            Log.atError?.log("Cannot read directory for comment cache in \(dir.path)")
            return nil

        case .isWriteableDir:
            return dir.appendingPathComponent(name, isDirectory: false)
        }
    }

    
    /// Load and return the comment table and its item manager.
    
    private func loadCommentTable(url: URL, createIfMissing: Bool = false) -> (ItemManager, Portal)? {
        
        
        // Ensure the comments table exists
                
        let itemManager = ItemManager(from: url) ?? createCommentTableItemManager()
        
        guard let table = itemManager.root[COMMENT_TABLE_NF].portal else {
            Log.atError?.log("Missing \(COMMENT_TABLE_NF.string) in \(url.path)")
            return nil
        }

        
        return (itemManager, table)
    }

    
    /// Creates a new comment table block item manager.
    ///
    /// Note that the actual table is wrapped in a block to ensure future upgradability.
    
    private func createCommentTableItemManager() -> ItemManager {
    
        let dm = ItemManager.createDictionaryManager()
        let tm = ItemManager.createTableManager(columns: &COMMENT_TABLE_SPECIFICATION)
        dm.root.updateItem(tm, withNameField: COMMENT_TABLE_NF)
        
        return dm
    }
}


fileprivate extension Portal {
    
    
    /// Find the index into the table for a given comment
    ///
    /// - Note: Should only be called from operations that run on the comment queue.

    func indexForComment(_ comment: Comment) -> Int? {
                        
        var matchIndex: Int?
        itterateFields(ofColumn: COMMENT_URL_INDEX) { (portal, index) -> Bool in
            if portal.string == comment.url.path {
                matchIndex = index
                return false // stop itterating
            } else {
                return true
            }
        }
        
        return matchIndex
    }
}
