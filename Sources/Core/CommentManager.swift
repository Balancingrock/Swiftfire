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
// An article or blog entry can use an _identifier_ to locate an associated _commentSection_.
//
// The _identifier_ will be expanded into a directory path using the _dot_ ('.') as a subdirectory separator.
//
// The _commentSection_ consist of a series of _commentBlocks_ and a _commentInputField_ at the end.
//
// A (single) _commentBlock_ contains a (single) user _comment_.
//
// A _comment_ is stored in the account directory of the user making the comment, using the directory path derived from the _identifier_.
//
// A _commentSection_ is stored as a table of _comment_ URLs in the domain comment manager, using the directory path derived from the _identifier_.
//
// Along with the _comment_ URL table a _commentCache_ is stored with all the _commentBlocks_ referred to by the table.
//
// The _commentCache_ is updated only when the _commentSection_ needs to be displayed.
//
// The _comment_ URL table is updated when comments are added/edited/removed.
//
// A special user _Anon_ is present that can be used by the to store comments made by users that want to remain anonymous.
//
// _Anon_ users can use a _displayName_ as an unverified identifier.
//
// All _Anon_ _comments_ will be stored under the _Anon_ account and in a list of comments-waiting-for-approval.
//
// A moderator or domain administrator can move the waiting comments to the _comment_ URL Table.
//
// Comments associated with a user-account have to have a certain number of approved comments before comments are auto-approved.
//
// Comments associated with a user-account can be edited or deleted by that user (or a moderator/domain-administrator).


fileprivate let COMMENT_BLOCK_TEMPLATE = "/templates/comment-block.sf.html"
fileprivate let COMMENT_REMOVED_TEMPLATE = "/templates/comment-removed.sf.html"


// For the comment URL table

fileprivate let NEEDS_UPDATE_NF = NameField("nu")!
fileprivate let NEEDS_UPDATE_CS = ColumnSpecification(type: .bool, nameField: NEEDS_UPDATE_NF, byteCount: 1)
fileprivate let NEEDS_UPDATE_CI = 0

fileprivate let COMMENT_URL_NF = NameField("cu")!
fileprivate let COMMENT_URL_CS = ColumnSpecification(type: .string, nameField: COMMENT_URL_NF, byteCount: 128)
fileprivate let COMMENT_URL_CI = 1

fileprivate var COMMENT_URL_TABLE_SPECIFICATION = [NEEDS_UPDATE_CS, COMMENT_URL_CS]


// The comment URL table (above) is wrapped in a dictionary to allow future upgrading

fileprivate let COMMENT_URL_TABLE_NF = NameField("ctb")!


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
    
    public var commentsForApproval: Array<Comment> = [] {
        didSet {
            storeCommentsForApproval()
        }
    }

    
    // A pointer to the domain for these comments
    
    unowned let domain: Domain
    
    
    /// Create a new comment handler
    
    init(_ domain: Domain) {
        self.domain = domain
        loadCommentsForApproval()
    }
    

    /// Returns the entire comment section including the input field for new comments if an account is present.
    ///
    /// Side effect: Sets the request.info[nof-comments] value to the number of comments included
    ///
    /// - Parameters:
    ///   - for: The identifier for the comment section.
    ///   - environment: The environment (request, domain, etc)
    ///
    /// - Returns: The UTF8 encoded HTML code. Will contain '***error***' if an error occured. Each comment will be wrapped in its own HTML element (depending on the comment template) but there is no overall container.
    
    public func commentBlocks(for identifier: String, environment: Functions.Environment) -> Data {
        
        return queue.sync {
            
            
            // Get the relative path for the table, cache and comments
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return htmlErrorMessage
            }

            
            // Get the url of the comment table
            
            guard let commentTableFile = commentTableFile(relativePath) else {
                // Error log has been made
                return htmlErrorMessage
            }

            
            // Load the comment table
            
            guard let (itemManager, table) = loadCommentTable(from: commentTableFile) else {
                Log.atError?.log("ItemManager should be available at \(commentTableFile.path)")
                return htmlErrorMessage
            }

            
            // Side effect: initialize environment.request.info[nof-comments]
            
            environment.request.info["nof-comments"] = String(table.rowCount ?? 0)
            
            
            // Check if the table has update markers
            
            var tableUpdate: Bool = false
            var midTableUpdate: Bool = false
            var indexOfFirstTableUpdate: Int = table.count
            
            table.itterateFields(ofColumn: NEEDS_UPDATE_CI) { (portal, index) -> Bool in

                guard let updated = portal.bool else {
                    Log.atError?.log("Wrong type in table column NEEDS_UPDATE_INDEX")
                    return false
                }
                
                if updated {
                    tableUpdate = true
                    if indexOfFirstTableUpdate == table.count {
                        indexOfFirstTableUpdate = index // set only once, for the first case
                    }
                } else {
                    if tableUpdate {
                        midTableUpdate = true // Use this to find out if the cache can be appended to or not
                    }
                }
                
                
                // Its assumed that the update will be performed, hence reset the need for updates
                
                portal.bool = false
                
                
                // Continue looking for more necessary updates
                
                return true
            }
            
            
            // Save the table changes if there were updates
            
            if tableUpdate {
                do {
                    try itemManager.data.write(to: commentTableFile)
                } catch let error {
                    Log.atError?.log("Could not save the table updates: \(commentTableFile.path) with error: \(error.localizedDescription)")
                }
            }
            
            
            // Three possibilities:
            // 1. Build new comment cache, 2. Append new entries to comment cache, 3. Return comment cache as is
            
            guard let commentCacheFile = commentCacheFile(relativePath) else {
                return htmlErrorMessage
            }

            if !FileManager.default.fileExists(atPath: commentCacheFile.path) {
                // The cache must be created, simulate a mid-cache update
                tableUpdate = true
                midTableUpdate = true
            }
            
            if tableUpdate {
                
                if midTableUpdate {
                    
                    // Rebuild the whole cache
                    
                    return rebuildCache(fromTable: table, fromIndex: 0, toFile: commentCacheFile, environment: environment)
                
                } else {
                
                    // Add the new entries to the cache
                    
                    return rebuildCache(fromTable: table, fromIndex: indexOfFirstTableUpdate, toFile: commentCacheFile, environment: environment)
                }
            }
            
            
            // The cache can be returned as is

            do {
                return try Data.init(contentsOf: commentCacheFile)
            } catch let error {
                Log.atError?.log("Cannot read comment cache error = \(error.localizedDescription)")
                return htmlErrorMessage
            }
        }
    }
    
    
    /// Rebuild the cache from the given table starting at the given index. Write the result to the table.
    ///
    /// - Parameters:
    ///    - fromTable: The table to be used when rebuilding the cache.
    ///    - fromIndex: The index into the table where to start, if starting from 0, the entire table will be rebuild, when starting from non-zero the existing cache will be added to.
    ///    - toFile: The URL where to store the rebuild cache.
    ///    - environment: The environment necessary for the creation of the individual comment blocks.
    ///
    /// - Returns: The content of the rebuild cache.
    
    private func rebuildCache(fromTable table: Portal, fromIndex: Int, toFile file: URL, environment: Functions.Environment) -> Data {
        
        var index = fromIndex
        
        var data: Data = Data()
        
        
        // Load the cache with old content if it does not have to be rebuild entirely
        
        if index != 0 {
            do {
                data = try Data.init(contentsOf: file)
            } catch let error {
                Log.atError?.log("Cannot read comment cache error = \(error.localizedDescription)")
                return htmlErrorMessage
            }
        }
        
        
        // For each table entry that must be added to the cache
        
        while index < table.count {
            
            
            // Get the comment path from the table
            
            guard let commentPath = table[index, COMMENT_URL_NF].string else {
                Log.atError?.log("Cannot retrieve path from comment table at row \(index)")
                return htmlErrorMessage
            }
            
            
            // Add the comment to the cache
            
            appendToCache(commentAtPath: commentPath, cache: &data, environment, sequenceNumber: index)
            
            
            // Mark the table row as being reflected in the cache
            
            table[index, NEEDS_UPDATE_NF].bool = false
            
            
            // Go to next row
            
            index += 1
        }
        
        
        // Store the cache
        
        do {
            
            try data.write(to: file)
            
        } catch let error {
            
            Log.atError?.log("Error updating the comment cache, error = \(error.localizedDescription)")
            return htmlErrorMessage
        }
        
        return data
    }
    
    
    /// Add the HTML code of the comment to the data using the comment template
    ///
    /// - Parameters:
    ///   - commentAtPath: The path to the comment file
    ///   - cache: The (html) data to add the comment (html) data to
    ///   - environment: The environment to be used for the template processing
    ///   - sequenceNumber: The sequence number for the comment at the given path.
    
    private func appendToCache(commentAtPath commentPath: String, cache data: inout Data, _ environment: Functions.Environment, sequenceNumber: Int) {
        
        let templatePath = (domain.webroot as NSString).appendingPathComponent(COMMENT_BLOCK_TEMPLATE)
        
        guard case .success(let template) = SFDocument.factory(path: templatePath) else {
            Log.atDebug?.log("Cannot create document from templatePath \(templatePath)")
            return
        }
        
        guard let comment = Comment(url: URL(fileURLWithPath: commentPath)) else {
            Log.atDebug?.log("Cannot load comment from \(commentPath)")
            return
        }
        
        comment.addToRequestInfo(environment.request, index: sequenceNumber)
                
        data.append(template.getContent(with: environment))
    }
        

    /// Updates the comments section for the given comment. This may invalidate cached values.
    ///
    /// - Parameters:
    ///   - text: The comment that was made.
    ///   - identifier: The identifier for the comment section.
    ///   - displayName: A display name for the Anon account.
    ///   - account: The account for the comment.

    public func newComment(text: String, identifier: String, displayName: String, account: Account?) {
        
        
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

            
            // Create (and store) the comment
            
            guard let comment = Comment(text: text, identifier: identifier, relativePath: relativePath, displayName: displayName, account: account) else {
                Log.atError?.log("Failed to create a new comment")
                return
            }


            // For the Anon account, always store the comment in the wait-for-approval list
            
            if account.name == "Anon" {
                domain.comments.commentsForApproval.append(comment)
                return
            }
            
            
            // For all other account, only store the comment in the wait-for-approval list if the auto-approve threshold has not yet been reached.
            
            if account.nofComments <= domain.autoCommentApprovalThreshold {
            
                domain.comments.commentsForApproval.append(comment)
            
            } else {
                
                account.nofComments += 1
                appendToTable(comment, relativePath)
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

    public func updateComment(text: String, identifier: String, account: Account, originalTimestamp: String) {
        
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

            
            // Get the comment table file reference
            
            guard let commentTableFile = commentTableFile(relativePath) else {
                // Error log has been made
                return
            }
            
            
            // Get the table and its manager
            
            guard let (itemManager, table) = loadCommentTable(from: commentTableFile) else {
                Log.atError?.log("ItemManager should be available at \(commentTableFile.path)")
                return
            }

            
            // Get the index of the comment to be updated
            
            guard let index = table.index(of: comment) else {
                Log.atError?.log("Comment \(comment.url.path) not found in table \(commentTableFile.path)")
                return
            }
            
            
            // Update table and comment
            
            comment.replaceText(with: text) // autosave
            table[index, NEEDS_UPDATE_CI].bool = true
            
            
            // Save the table
            
            guard (try? itemManager.data.write(to: commentTableFile)) != nil else {
                Log.atError?.log("Error saving updated table \(commentTableFile.path)")
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

    public func rejectComment(identifier: String, account: Account, originalTimestamp: String) {
        
        queue.async { [identifier, account, originalTimestamp, weak self] in
            
            
            // Make sure the comment manager is available
            
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

    public func removeComment(identifier: String, account: Account, originalTimestamp: String) {
        
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
            
            guard let commentTableFile = commentTableFile(relativePath) else {
                // Error log has been made
                return
            }
            
            
            // Load the cooment table and its manager
            
            guard let (itemManager, table) = loadCommentTable(from: commentTableFile) else {
                Log.atError?.log("ItemManager should be available at \(commentTableFile.path)")
                return
            }
            
            
            // Get the index for the comment to be removed
            
            guard let index = table.index(of: comment) else {
                Log.atError?.log("Comment \(comment.url.path) not found in table \(commentTableFile.path)")
                return
            }
            
            
            // Update table
            
            table[index, COMMENT_URL_CI].string = ""
            
            
            // Remove it from the account comment area
            
            if (try? FileManager.default.removeItem(at: comment.url)) == nil {
                Log.atCritical?.log("Cannot remove coment at \(comment.url.path), the file for this comment is now orphaned!")
            }
            
            
            // Save the table
            
            guard (try? itemManager.data.write(to: commentTableFile)) != nil else {
                Log.atError?.log("Error saving updated table \(commentTableFile.path)")
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

    public func approveComment(identifier: String, account: Account, originalTimestamp: String) {
        
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
            
            self.appendToTable(comment, relativePath)
        }
    }
    
    
    
    /// Updates (or creates) the comment block for a new comment
    ///
    /// - Note: Should only be called from operations that run on the comment queue.
    ///
    /// - Parameters:
    ///   - comment: The comment to be added.
    ///   - relativePath: The relative path of the comment and the comment table.

    private func appendToTable(_ comment: Comment, _ relativePath: String) {
        
    
        // Get the url for the table
        
        guard let commentTableFile = commentTableFile(relativePath) else {
            // Error log entry has already been generated
            return
        }

        
        // Get the comment table
        
        guard let (itemManager, table) = loadCommentTable(from: commentTableFile, createIfMissing: true) else {
            Log.atError?.log("Cannot add to comment table")
            return
        }
        
        
        // Update the table
        
        table.addRows(1) { (portal) in
            switch portal.column {
            case COMMENT_URL_CI: portal.crcString = BRCrcString(comment.url.path)
            case NEEDS_UPDATE_CI: portal.bool = true
            default:
                Log.atError?.log("Unknown table index \(portal.column ?? -1)")
            }
        }
        
        
        // Save the table
        
        guard (try? itemManager.data.write(to: commentTableFile)) != nil else {
            Log.atError?.log("Cannot write comment table file to \(commentTableFile.path)")
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
    
    private func commentTableFile(_ relativePath: String) -> URL? {
        
        
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
    
    private func commentCacheFile(_ relativePath: String) -> URL? {
        
        
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
    
    private func loadCommentTable(from url: URL, createIfMissing: Bool = false) -> (ItemManager, Portal)? {
        
        
        // Ensure the comments table exists
                
        let itemManager = ItemManager(from: url) ?? createCommentTableItemManager()
        
        guard let table = itemManager.root[COMMENT_URL_TABLE_NF].portal else {
            Log.atError?.log("Missing \(COMMENT_URL_TABLE_NF.string) in \(url.path)")
            return nil
        }

        
        return (itemManager, table)
    }

    
    /// Creates a new comment table block item manager.
    ///
    /// Note that the actual table is wrapped in a block to ensure future upgradability.
    
    private func createCommentTableItemManager() -> ItemManager {
    
        let dm = ItemManager.createDictionaryManager()
        let tm = ItemManager.createTableManager(columns: &COMMENT_URL_TABLE_SPECIFICATION)
        dm.root.updateItem(tm, withNameField: COMMENT_URL_TABLE_NF)
        
        return dm
    }


    /// Stores the comments waiting for approval in a list of paths
    
    private func storeCommentsForApproval() {
        
        guard let url = Urls.domainCommentsForApprovalFile(for: domain.name) else {
            Log.atError?.log("Cannot get url for domainCommentsForApprovalFile")
            return
        }
        
        let commentUrls = commentsForApproval.map { $0.url.path }
        
        commentUrls.store(to: url)
    }
    
    
    /// Loads the comments waiting for approval from a list of paths
    
    private func loadCommentsForApproval() {
        
        guard let url = Urls.domainCommentsForApprovalFile(for: domain.name) else {
            Log.atError?.log("Cannot get url for domainCommentsForApprovalFile")
            return
        }

        var commentUrls: Array<String> = []

        commentUrls.load(from: url)
        
        commentsForApproval = commentUrls.compactMap { Comment(url: URL(fileURLWithPath: $0)) }
    }
}


fileprivate extension Portal {
    
    
    /// Find the index into the table for a given comment
    ///
    /// - Note: Should only be called from operations that run on the comment queue.

    func index(of comment: Comment) -> Int? {
                        
        var matchIndex: Int?
        itterateFields(ofColumn: COMMENT_URL_CI) { (portal, index) -> Bool in
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
