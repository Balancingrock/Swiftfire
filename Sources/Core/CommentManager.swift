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
            
            // Get the list of comment URLs
            
            // Get the cached comment block
            
            // If there is an older comment updated, rebuild the comment block
            
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
    ///
    /// - Returns: The UTF8 encoded HTML code. Will contain '***error***' if an error occured. May be empty if there are no comments and no account is given.

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
                    addCommentToArticleCommentStore(comment, relativePath)
                }
            }
        }
    }
    
    
    /// Updates the text of an existing comment.
    
    func update(text: String, identifier: String, account: Account, originalTimestamp: String) {
        

        // Reject updates for the Anon account
        
        guard account.name != "Anon" else {
            Log.atError?.log("Cannot update comments in the Anon account")
            return
        }

        
        // Get the relative path from the identifier
        
        guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
            Log.atError?.log("The relative path cannot be empty (identifier error)")
            return
        }

        
        queue.sync {
            
            
            // Get the comment itself
            
            let commentUrl = account.dir.appendingPathComponent(relativePath, isDirectory: false).appendingPathComponent(originalTimestamp, isDirectory: false).appendingPathExtension("brbon")
            
            guard let comment = Comment(url: commentUrl) else {
                Log.atError?.log("Comment not found for path \(commentUrl.path)")
                return
            }
                        
            
            // Get the comment table field that must be updated (search algo)
            
            guard let commentTableUrl = commentTableFileUrl(relativeDirPath: relativePath) else {
                // Error log has been made
                return
            }
            
            guard let itemManager = ItemManager(from: commentTableUrl) else {
                Log.atError?.log("ItemManager should be available at \(commentTableUrl.path)")
                return
            }
            
            guard let table = itemManager.root[COMMENT_TABLE_NF].portal else {
                Log.atError?.log("Comment table not found in \(commentTableUrl.path)")
                return
            }
            
            var matchIndex: Int?
            table.itterateFields(ofColumn: COMMENT_URL_INDEX) { (portal, index) -> Bool in
                if portal.string == comment.url.path {
                    matchIndex = index
                    return false // stop itterating
                } else {
                    return true
                }
            }
            
            guard let index = matchIndex else {
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
    
    func reject(identifier: String, account: Account, originalTimestamp: String) {
        
        queue.async {
            
            
            // Get the relative path from the identifier
            
            guard let relativePath = CommentManager.identifier2RelativePath(identifier) else {
                Log.atError?.log("The relative path cannot be empty (identifier error)")
                return
            }

            
            // Get the comment itself
            
            let commentUrl = account.dir.appendingPathComponent(relativePath, isDirectory: false).appendingPathComponent(originalTimestamp, isDirectory: false).appendingPathExtension("brbon")
            
            guard let comment = Comment(url: commentUrl) else {
                Log.atError?.log("Comment not found for path \(commentUrl.path)")
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
    
    
    /// Removes a comment from both the comment block and the account
    
    func remove(identifier: String, id: String, account: Account) {
        
    }
    
    
    /// Removes a comment from the waiting-for-approval list and adds it to the comment block
    
    func approve(identifier: String, id: String, account: Account) {
        
    }
    
    
    /// Updates (or creates) the comment block for a new comment
    ///
    /// - Note: Should only be called from operations that run on the comment queue.
    
    private func addCommentToArticleCommentStore(_ comment: Comment, _ relativePath: String) {
        
        
        // Make sure at least the target directory exists
        
        guard let commentTableFileUrl = commentTableFileUrl(relativeDirPath: relativePath) else {
            // Error log entry has already been generated
            return
        }

        
        // Ensure the comments table exists
                
        let itemManager = ItemManager(from: commentTableFileUrl) ?? createCommentTableItemManager()
        guard let table = itemManager.root[COMMENT_TABLE_NF].portal else {
            Log.atError?.log("Missing \(COMMENT_TABLE_NF.string) in \(commentTableFileUrl.path)")
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
    
    
    /// Creates a new comment table block item manager.
    ///
    /// Note that the actual table is wrapped in a block to ensure future upgradability.
    
    private func createCommentTableItemManager() -> ItemManager {
    
        let dm = ItemManager.createDictionaryManager()
        let tm = ItemManager.createTableManager(columns: &COMMENT_TABLE_SPECIFICATION)
        dm.root.updateItem(tm, withNameField: COMMENT_TABLE_NF)
        
        return dm
    }
    
    
    /// Return the path to the commentTable.
    ///
    /// - Parameter relativePath: The relative path (to the comments-root of the domain) to the directory in which the comment table must be located.
    ///
    /// - Returns: The url for the file (either present or when it can be created). Nil when an error occured. If an error occured, an error log entry wil have been made.
    
    private func commentTableFileUrl(relativeDirPath: String) -> URL? {
        
        
        // The target directory
        
        guard let rootDir = Urls.domainCommentsRootDir(for: domain.name) else {
            Log.atError?.log("Cannot retrieve comments root directory")
            return nil
        }
        
        let dir = rootDir.appendingPathComponent(relativeDirPath, isDirectory: true)
        
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
}

