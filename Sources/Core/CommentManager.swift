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
// The _comment_ URL table is updated or 'touched' when comments are added/edited/removed.
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


fileprivate let COMMENT_BLOCK_TEMPLATE = "/pages/comment-block.sf.html"
fileprivate let COMMENT_REMOVED_TEMPLATE = "/pages/comment-removed.sf.html"


// For the comment URL table

fileprivate let COMMENT_SEQUENCE_NUMBER_NF = NameField("sn")!
fileprivate let COMMENT_SEQUENCE_NUMBER_CS = ColumnSpecification(type: .uint16, nameField: COMMENT_SEQUENCE_NUMBER_NF, byteCount: 2)
fileprivate let COMMENT_SEQUENCE_NUMBER_CI = 0

fileprivate let COMMENT_URL_NF = NameField("cu")!
fileprivate let COMMENT_URL_CS = ColumnSpecification(type: .string, nameField: COMMENT_URL_NF, byteCount: 128)
internal let COMMENT_URL_CI = 1

fileprivate var COMMENT_URL_TABLE_SPECIFICATION = [COMMENT_SEQUENCE_NUMBER_CS, COMMENT_URL_CS]


// The comment URL table (above) is wrapped in a dictionary

fileprivate let URL_TABLE_NF = NameField("ctb")! // The table itself
fileprivate let NOF_COMMENTS_NF = NameField("nofc")! // The number of comments made (may be higher than the number of rows in the table)


/// Manages the comments for a domain.

public final class CommentManager {
    
    
    /// The table item manager cache.
    
    private class TableCache {

        
        /// A reference to the domain to enable name access
        
        unowned var domain: Domain
        
        
        /// The dictionary with identifier/item-manager associations
        
        var dict: Dictionary<String, ItemManager> = [:]
        
        
        /// Associate a URL with an identifier (note: This dictionary is kept in sync with the item manager dictionary.
        
        var urls: Dictionary<String, URL> = [:]
        
        
        /// The array for least-used detection
        
        var arr: Array<String> = []
        
        
        /// Create new table cache
        
        init(_ domain: Domain) {
            self.domain = domain
        }
        
                
        /// Add a new entry to the cache
        ///
        /// Can also remove older entries if the number of entries is too large
    
        private func add(_ id: String, _ im: ItemManager, _ url: URL) {
            
            while arr.count > 50 {
                let str = arr.removeLast()
                dict.removeValue(forKey: str)
                urls.removeValue(forKey: str)
                // The (table) item manager is now removed from the cache, when another operation -including in another thread- is still using it, it will be deallocated when that operation is ready.
            }

            dict[id] = im
            urls[id] = url
            arr.insert(id, at: 0)
        }
        
        
        /// The filename for the comment table files
        
        let filename = "comment-table.brbon"
        
        
        /// Return the path to the domain's root comment path
        
        private func commentTableDirPath(forId id: String) -> NSString? {
            
            guard let relativePath = CommentManager.identifier2RelativePath(id) else { return nil }
            
            let rootDirPath = Urls.domainCommentsRootDirPath(for: domain.name)
            
            return rootDirPath.appendingPathComponent(relativePath) as NSString
        }
        
        
        /// Return the path to the commentTable.
        ///
        /// - Parameter relativePath: The relative path (to the comments-root of the domain) to the directory in which the comment table must be located.
        ///
        /// - Returns: The path for the file (either present or when it can be created). Nil when an error occured. If an error occured, an error log entry wil have been made.
        
        private func commentTableFilePath(forId id: String) -> String? {
            
            guard let fileDirPath = commentTableDirPath(forId: id) else { return nil }
            
            switch FileManager.default.testFor(fileDirPath, file: filename, createDir: true) {
            
            case .fail:
                Log.atError?.log("Cannot read or write comment table for identifier: \(id)")
                return nil
            
            case .isReadableFile:
                Log.atError?.log("Cannot write to comment table for identifier: \(id)")
                return nil

            case .isWriteableFile:
                return fileDirPath.appendingPathComponent(filename)
                
            case .isReadableDir:
                Log.atError?.log("Cannot read directory for comment table for identifier: \(id)")
                return nil

            case .isWriteableDir:
                return fileDirPath.appendingPathComponent(filename)
            }
        }

                
        /// Returns a comment table manager if the corresponding file exists. Returns nil if the file does not exist.
        
        func getCommentTableForExistingFile(forId id: String) -> ItemManager? {
                                
            
            // If it is present, return it
            
            if let im = dict[id] {
                let i = arr.firstIndex(of: id)!
                arr.insert(arr.remove(at: i), at: 0) // Move it to the 'most recent used' place
                return im
            }
            
            
            // The target file
            
            guard let fileDirPath = commentTableDirPath(forId: id) else { return nil }
                        
            
            // Read the item manager from file
            
            guard FileManager.default.testFor(fileDirPath, file: filename, createDir: false) == .isWriteableFile else { return nil }
            
            
            // Create the URL for the file
            
            let fileUrl = URL(fileURLWithPath: fileDirPath.appendingPathComponent(filename), isDirectory: false)
            
            
            // Read the item manager from file
            
            guard let im = ItemManager.init(from: fileUrl) else {
                Log.atError?.log("Could not read file at: \(fileUrl.path)")
                return nil
            }
            
            
            // Add the new item manager
            
            add(id, im, fileUrl)


            return im
        }
        
        
        /// Returns a comment table manager and creates one if it does not exist. Returns nil if the file cannot be created.
        
        func getCommentTable(forId id: String) -> ItemManager? {
            
            
            // Try if it is available
            
            if let im = getCommentTableForExistingFile(forId: id) { return im }
            
            
            // It needs to be created
            
            
            // Get the path to the file (fail now if the file cannot be created)
            
            guard let filePath = commentTableFilePath(forId: id) else { return nil }
            
            
            // Create a new ItemManager for the table
            
            let im = ItemManager.createDictionaryManager()
            let tm = ItemManager.createTableManager(columns: &COMMENT_URL_TABLE_SPECIFICATION)
            im.root.updateItem(tm, withNameField: URL_TABLE_NF)
            im.root.updateItem(UInt16(0), withNameField: NOF_COMMENTS_NF)
            
            
            // Create the URL for storage
            
            let fileUrl = URL(fileURLWithPath: filePath, isDirectory: false)
            
            
            // Store the (empty table) file

            do {
                try im.data.write(to: fileUrl)
            } catch let error {
                Log.atError?.log("Could not write table to file, error: \(error.localizedDescription)")
                return nil
            }

            
            // Add the new table to the cache
            
            add(id, im, fileUrl)
            
            
            return im
        }
        
        
        /// Touches the content modification date of the associated file
        
        func touch(tableFor id: String) {
            
            guard getCommentTableForExistingFile(forId: id) != nil else {
                Log.atError?.log("No such file exists for id: \(id)")
                return
            }
            
            guard var url = urls[id] else {
                Log.atError?.log("Programming error")
                return
            }
            
            do {
                var rv = try url.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey])
                Log.atDebug?.log("Old modification date: \(rv.contentModificationDate?.javaDate ?? -1)")
                rv.contentModificationDate = Date()
                try url.setResourceValues(rv)
                rv = try url.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey])
                Log.atDebug?.log("New modification date: \(rv.contentModificationDate?.javaDate ?? -1)")
            } catch let error {
                Log.atError?.log("Unable to update content modification date file at \(url.path) with error: \(error.localizedDescription)")
            }
        }
        
        
        /// Returns the content modification date of the file, will create the file if it does not exist yet.
        ///
        /// - Returns: the msec since 1970.01.01 (Java Date), returns nil if the file does not exist or an error occured.
        
        func modificationDate(for id: String) -> Int64? {
            
            // Force loading/creation of the file
            
            guard getCommentTableForExistingFile(forId: id) != nil else { return nil }
            
            guard let url = urls[id] else {
                Log.atError?.log("Programming error")
                return nil
            }
            
            do {
                guard let ts = try url.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey]).contentModificationDate else {
                    Log.atError?.log("")
                    return nil
                }
                
                Log.atDebug?.log("Returning modification date: \(ts.javaDate)")
                
                return ts.javaDate
                
            } catch let error {
                
                Log.atError?.log("An error occured with message: \(error.localizedDescription)")
                return nil
            }
        }
        
        
        /// Store the table manager for the given id to file
        
        func store(tableFor id: String) {
        
            guard let url = urls[id] else {
                Log.atError?.log("Cannot find corresponding URL, cannot save, data may be lost")
                return
            }
            
            guard let im = dict[id] else {
                Log.atError?.log("Cannot find corresponding item manager, cannot save, data may be lost")
                return
            }
            
            do {
                try im.data.write(to: url)
            } catch let error {
                Log.atError?.log("Cannot save item manager, error message: \(error.localizedDescription)")
            }
        }
    }
    
    
    /// Creates a relative directory path from a base url and the identifier
    
    static func identifier2RelativePath(_ identifier: String) -> String? {
        
        
        // Reform the identifier and remove all leading dots
        
        var pid = identifier.lowercased()
        while pid.first == "." { pid.removeFirst() }
        
        
        // There must be at least one character left
        
        guard !pid.isEmpty else {
            Log.atError?.log("Cannot transform identifier '\(identifier)' into a relative path")
            return nil
        }

        
        // Transform the identifier into a relative path

        return pid.replacingOccurrences(of: ".", with: "/")
    }
    
    
    /// The queue on which all work will be serialized.
    
    fileprivate let queue = DispatchQueue.init(label: "CommentsAccess", qos: DispatchQoS.userInitiated, attributes: DispatchQueue.Attributes.init(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem, target: nil)
    
    
    /// The (table) item manager cache
    
    private let tableCache: TableCache
    
    
    /// The list with comments to be approaved
    
    public var forApproval: Array<Comment> = [] {
        didSet {
            storeCommentsForApproval()
        }
    }

    
    // A pointer to the domain for these comments
    
    unowned let domain: Domain
    
    
    /// Create a new comment handler
    
    init(_ domain: Domain) {
        self.domain = domain
        tableCache = TableCache(domain)
        loadCommentsForApproval()
    }
    
    
    /// Return the modificationdate of the content for the file with the given ID.
    ///
    /// Returns nil if an error occured. It will create the file if the file did not exist yet.
    
    public func modificationDate(for id: String) -> Int64? { return tableCache.modificationDate(for: id) }
    
    
    /// Return the comment table for the identifier
    
    public func commentTable(for id: String) -> Portal? {
        let itemManager = tableCache.getCommentTable(forId: id)
        return itemManager?.root[URL_TABLE_NF].portal
    }
    
    
    /// The number of comments in a comment-table
    
    public func nofComments(for id: String) -> Int {
        let itemManager = tableCache.getCommentTable(forId: id)
        return itemManager?.root[URL_TABLE_NF].rowCount ?? 0
    }
    

    /// Updates the comments section for the given comment. This may invalidate cached values.
    ///
    /// - Parameters:
    ///   - text: The comment that was made.
    ///   - identifier: The identifier for the comment section.
    ///   - displayName: A display name for the Anon account.
    ///   - account: The account for the comment.

    public func newComment(text: String, identifier: String, displayName: String, account: Account?) {
        
        queue.sync {

            
            // Make sure there is an account
        
            guard let account = account ?? domain.accounts.getActiveAccount(withName: "Anon", andPassword: "Anon") else {
                Log.atError?.log("Failed to retrieve Anon account")
                return
            }
        
            
            // Get the relative path for the comment
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return
            }

            
            // To determine the sequence number of a comment, retrieve the comment table (create if needed)
            
            guard let commentTable: ItemManager = tableCache.getCommentTable(forId: identifier) else { return }
            
            
            // Get the sequence number of this comment
            
            guard let oldCount = commentTable.root[NOF_COMMENTS_NF].uint16 else {
                Log.atError?.log("Cannot read comment count in comment table")
                return
            }
            
            
            // Increase the count
            
            let newCount = oldCount + 1
            commentTable.root[NOF_COMMENTS_NF] = newCount
            
            
            // Create (and store) the comment
            
            guard let comment = Comment(text: text, identifier: identifier, sequenceNumber: newCount, relativePath: relativePath, displayName: displayName, account: account) else {
                Log.atError?.log("Failed to create a new comment")
                return
            }


            // For the Anon account, always store the comment in the wait-for-approval list
            
            if account.name == "Anon" {
                
                domain.comments.forApproval.append(comment)
            
            } else {
            
            
                // For all other account, only store the comment in the wait-for-approval list if the auto-approve threshold has not yet been reached.
            
                if account.nofComments <= domain.autoCommentApprovalThreshold {
            
                    domain.comments.forApproval.append(comment)
            
                } else {
                
                    account.nofComments += 1
                    appendToTable(comment, relativePath)
                }
            }
            
            
            // Update the comment table file
            
            tableCache.store(tableFor: identifier)
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
            
            guard let comment = self.loadComment(relativePath, account, originalTimestamp) else {
                // Error log has been made
                return
            }

            
            // Update comment
            
            comment.replaceText(with: text) // autosave

            
            // Touch the comment table file to ensure an update of cached content
            
            tableCache.touch(tableFor: identifier)
        }
    }
    
    
    /// Rejects a comment that was waiting for approval
    ///
    /// - Parameters:
    ///   - uuid: The identifier for the comment section.

    public func rejectComment(uuid: String) {
        
        queue.async { [uuid, weak self] in
            
            
            // Make sure the comment manager is available
            
            guard let self = self else { return }

            
            // Get the comment to be removed from the forApproval list
            
            guard let i = self.forApproval.firstIndex( where: { $0.uuid == uuid }) else {
                Log.atError?.log("Could not find comment for uuid: \(uuid)")
                return
            }
            
            
            // Remove it from the waiting list
            
            let comment = self.forApproval.remove(at: i)
            
            
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
                        
            guard let comment = loadComment(relativePath, account, originalTimestamp) else { return }
                        
            
            // Get the comment table itemmanager
            
            guard let itemManager = tableCache.getCommentTableForExistingFile(forId: identifier) else { return }
            
            
            // Get the table
            
            guard let table = itemManager.root[URL_TABLE_NF].portal else {
                Log.atError?.log("Cannot locate url table")
                return
            }
            
            
            // Get the index for the comment to be removed
            
            guard let index = table.index(of: comment) else {
                Log.atError?.log("Comment \(comment.url.path) not found in table")
                return
            }
            
            
            // Update table
            
            table.removeRow(index)
            
            
            // Remove it from the account comment area (and any empty directories that might result)
            
            FileManager.default.removeFileAndEmptyDirectories(from: comment.url)
            
            
            // Save the table
            
            tableCache.store(tableFor: identifier)
        }
    }
    
    
    /// Removes a comment from the waiting-for-approval list and adds it to the comment table
    ///
    /// - Parameters:
    ///   - uuid: The identifier for the comment section.

    public func approveComment(uuid: String) {
        
        queue.async { [uuid, weak self] in
            
            
            // Make sure the comments are available
            
            guard let self = self else { return }
            
                        
            // Get the comment to be removed from the forApproval list
            
            guard let i = self.forApproval.firstIndex( where: { $0.uuid == uuid }) else {
                Log.atError?.log("Could not find comment for uuid: \(uuid)")
                return
            }

            
            // Remove it from the waiting list
            
            let comment = self.forApproval.remove(at: i)

            
            // Get the table
            
            guard let itemManager = self.tableCache.getCommentTableForExistingFile(forId: comment.identifier) else { return }
            guard let table = itemManager.root[URL_TABLE_NF].portal else {
                Log.atError?.log("")
                return
            }
            
            
            // Find the proper place in the table
            
            var insertionIndex = 0
            table.itterateFields(ofColumn: COMMENT_SEQUENCE_NUMBER_CI) { (portal, index) -> Bool in
                if comment.sequenceNumber < (portal.uint16 ?? 0) {
                    return true
                } else {
                    insertionIndex = index
                    return false
                }
            }
            
            
            // Insert it into the comment table
            
            if table.count == 0 {
                switch (table.addRows(1, values: { (portal) in
                    switch portal.column! {
                    case COMMENT_SEQUENCE_NUMBER_CI: portal.uint16 = comment.sequenceNumber
                    case COMMENT_URL_CI: portal.string = comment.url.path
                    default:
                        Log.atError?.log("Unknown table column with column index: \(portal.column!)")
                    }
                })) {
                    case .success: break
                    case .error(let error): Log.atError?.log("Error code received: \(error.description)")
                    case .noAction: Log.atError?.log("Unexpected code executed")
                }
            } else {
                switch table.insertRows(atIndex: insertionIndex, amount: 1, defaultValues: { (portal) in
                    switch portal.column! {
                    case COMMENT_SEQUENCE_NUMBER_CI: portal.uint16 = comment.sequenceNumber
                    case COMMENT_URL_CI: portal.string = comment.url.path
                    default:
                        Log.atError?.log("Unknown table column with column index: \(portal.column!)")
                    }}) {
                case .success: break
                case .error(let error): Log.atError?.log("Error code received: \(error.description)")
                case .noAction: Log.atError?.log("Unexpected code executed")
                }
            }
            
            
            // Store the updated table
            
            self.tableCache.store(tableFor: comment.identifier)
        }
    }
    
    
    
    /// Updates (or creates) the comment block for a new comment
    ///
    /// - Note: Should only be called from operations that run on the comment queue.
    ///
    /// - Parameters:
    ///   - comment: The comment to be added.
    ///   - identifier: The identifier of the webpage where the comment is placed.

    private func appendToTable(_ comment: Comment, _ identifier: String) {
        
    
        // Get the comment table
        
        guard let itemManager = tableCache.getCommentTableForExistingFile(forId: identifier) else { return }

        
        // Get the table itself
        
        guard let table = itemManager.root[URL_TABLE_NF].portal else {
            Log.atError?.log("Table manager does not contain table")
            return
        }
        
        
        // Update the table
        
        table.addRows(1) { (portal) in
            switch portal.column {
            case COMMENT_URL_CI: portal.crcString = BRCrcString(comment.url.path)
            case COMMENT_SEQUENCE_NUMBER_CI: portal.uint16 = comment.sequenceNumber
            default:
                Log.atError?.log("Unknown table index \(portal.column ?? -1)")
            }
        }
        
        
        // Save the table
        
        tableCache.store(tableFor: identifier)
    }
    
    
    /// Load a comment
    ///
    /// - Parameters:
    ///   - relativePath: The relative path of the comment and the comment table.
    ///   - account: The account for the comment.
    ///   - timestamp: The timestamp the comment was made.

    private func loadComment(_ relativePath: String, _ account: Account, _ timestamp: String) -> Comment? {
        
        let commentUrl = account.dir.appendingPathComponent(relativePath, isDirectory: true).appendingPathComponent(timestamp, isDirectory: false).appendingPathExtension("brbon")
        
        guard let comment = Comment(url: commentUrl) else {
            Log.atError?.log("Comment not found for path \(commentUrl.path)")
            return nil
        }

        return comment
    }


    /// Stores the comments waiting for approval in a list of paths
    
    private func storeCommentsForApproval() {
        
        guard let url = Urls.domainCommentsForApprovalFile(for: domain.name) else {
            Log.atError?.log("Cannot get url for domainCommentsForApprovalFile")
            return
        }
        
        let commentUrls = forApproval.map { $0.url.path }
        
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
        
        forApproval = commentUrls.compactMap { Comment(url: URL(fileURLWithPath: $0)) }
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
