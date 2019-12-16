// =====================================================================================================================
//
//  File:       SFDocument.swift
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
// 1.3.0 #7 Removed local filemanager
//       - Removed inout from the function.environment signature
//       - Added flow control
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
//
// A SFDocument (Swiftfire Document) is a document that has the 4 magical characters ".sf." in its filename.
//
// A SFDocument will be parsed for function calls. If a functioncall is found, the function call itself will be replaced
// by the data that is returned by the function.
//
// Example:
//
// <p>The total number of visitors to this site is: .siteVisitorCount() </p>
//
// becomes:
//
// <p>The total number of visitors to this site is: 37448 </p>
//
// Assuming of course that the function ".siteVisitorCount()" does indeed return the number 37448.
//
// There is no limit on what a function can do, as long as it returns data that is UTF-8 formatted.
//
// =====================================================================================================================

import Foundation
import SwifterLog
import BRUtils
import KeyedCache
import BRBON


/// This encapsulates a swiftfire document in its parsed form.

public class SFDocument: EstimatedMemoryConsumption {

    
    /// This cache contains SFDocuments that have already been processed.
    
    private static var cache: MemoryCache<String, SFDocument> = {
        let cacheSize = serverParameters.sfDocumentCacheSize.value * 1024 * 1024
        return MemoryCache<String, SFDocument>(limitStrategy: .bySize(cacheSize), purgeStrategy: .leastUsed)
    }()
    
    
    /// Protect the cache processing functions
    
    private static let queue = DispatchQueue(label: "SFDocument cache", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    
    
    /// A root class for .sf. file fragments

    public class Block {
        
        
        /// Returns the data contained in this block
        
        func getData(_ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
            Log.atError?.log("Must be overriden")
            return htmlErrorMessage
        }
    }

    
    /// A block of characters that does not contain a function.
    
    final class CharacterBlock: Block {
        
        
        /// The data in the block
        
        let data: Data
        
        
        /// Create a new instance
        
        init(data: Data) {
            self.data = data
        }
        
        
        /// Returns the data contained in this block

        override func getData(_ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? { return data }
    }
    
    
    /// A block of characters that contains a function, with the details of the function completely parsed.
    
    final class FunctionBlock: Block {
                
        
        /// The name of this function
        
        let name: String
        
        
        /// References the function closure
        
        let function: Functions.Signature?
        
        
        /// The arguments in the function brackets.
        
        var arguments: Functions.Arguments
        

        /// Create a new instance
        
        init(name: String, function: Functions.Signature?, arguments: Functions.Arguments) {
            self.name = name
            self.function = function
            self.arguments = arguments
        }
        
        
        /// Returns the data contained in this block

        override func getData(_ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
            return function?(arguments, &info, environment)
        }
    }
    
    
    /// A control block, contains other blocks that may be executed conditionally or repeatedly
    
    final class ControlBlock: Block {
        
        
        /// The control function of this block
        
        let name: String
        
        
        /// The other blocks that are part of this block
        
        var blocks: Array<Block> = []
        

        /// References the function closure
        
        let function: Functions.Signature?
        
        
        /// The arguments in the function brackets.
        
        var arguments: Functions.Arguments

        
        /// Create a new instance
        
        init(name: String, function: Functions.Signature?, arguments: Functions.Arguments) {
            self.name = name
            self.function = function
            self.arguments = arguments
        }
        
        
        /// Returns the data contained in this block

        override func getData(_ info: inout Functions.Info, _ environment: Functions.Environment) -> Data? {
            
            Log.atDebug?.log("Controlblock: \(name)")
            
            switch name {
            
            case "root":
                
                Log.atDebug?.log("Root")
                
                var data = Data()

                blocks.forEach {
                    if let d = $0.getData(&info, environment) {
                        data.append(d)
                    }
                }
                
                return data
                
                
            case "if": // Note that the 'then' and 'else' blocks have no associated cases but are executed as part of the 'if' case
                
                Log.atDebug?.log("if")

                var data = Data()

                guard case .arrayOfString(let args) = arguments else {
                    Log.atError?.log("Syntax error: No string arguments found")
                    return nil
                }
                                
                if evaluateIf(args, &info, environment) {
                    
                    Log.atDebug?.log("then")

                    if blocks.count > 0 {
                        if let d = blocks[0].getData(&info, environment) {
                            data.append(d)
                        }
                    }
                    
                } else {

                    Log.atDebug?.log("else")

                    if blocks.count > 1 {
                        if let d = blocks[1].getData(&info, environment) {
                            data.append(d)
                        }
                    }
                }
                
                Log.atDebug?.log("endif")

                return data
                
                
            case "then", "else":
                
                Log.atDebug?.log("then-else-execution")

                var data = Data()

                blocks.forEach {
                    if let d = $0.getData(&info, environment) {
                        data.append(d)
                    }
                }

                return data
                
                
            case "for":
            
                Log.atDebug?.log("for")

                var data = Data()

                guard case .arrayOfString(let args) = arguments else {
                    Log.atError?.log("Syntax error: No string arguments found")
                    return nil
                }
                
                guard let source = getForLoopSource(args, &info, environment) else { return nil }
                
                guard let (startIndex, count) = getForLoopRange(args, &info, environment) else { return nil }

                let fcount = count ?? (source.nofElements - startIndex) + 1
                let endIndex = min(startIndex + fcount + 1, source.nofElements)
                
                info["for-start-index"] = String(startIndex)
                info["for-end-index"] = String(endIndex)
                info["for-index"] = String(startIndex)
                
                for i in startIndex ..< endIndex {

                    source.addElement(at: i, to: &info)
                    
                    Log.atDebug?.log("for-index = \(i)")

                    blocks.forEach {
                        if let d = $0.getData(&info, environment) {
                            data.append(d)
                        }
                    }
                    
                    info["for-index"] = String(i)
                }
                
                Log.atDebug?.log("endfor")

                return data

                
            case "cached":
                
                Log.atDebug?.log("cached")

                guard case .arrayOfString(let args) = arguments else {
                    Log.atError?.log("Syntax error: No string arguments found")
                    return nil
                }
                
                guard args.count == 2 else {
                    Log.atError?.log("Syntax error: Expected 2 arguments for 'cache' statement, found \(args.count)")
                    return nil
                }
                
                guard !blocks.isEmpty else {
                    Log.atError?.log("Syntax error: No cache building blocks present")
                    return nil
                }

                guard
                    let value = readKey(args[1], using: info, in: environment),
                    let timestamp = Int64(value) else {
                    Log.atError?.log("Syntax error: invalid timestamp argument: \(args[1])")
                    return nil
                }
                
                Log.atDebug?.log("endcached")
                
                let identifier = readKey(args[0], using: info, in: environment) ?? args[0]

                return cachedData(forIdentifier: identifier, ifCachedAfter: timestamp, elseCreateFrom: blocks, info: &info, environment: environment)
                
                
            case "comment":
                
                Log.atDebug?.log("comment")
                
                return Data()
                
                
            default:
                
                Log.atError?.log("Unknown control function \(name)")
                return nil
            }
        }
    }
    
    
    /// The path on disk of the file
    
    let path: String
    
    
    /// The buffer with all characters in the file
    
    let filedata: String
    
    
    /// The time the file was last modified
    
    let fileModificationDate: Int64
    
    
    /// The results of the parser will be added to this top level control block
    
    internal var blocks: ControlBlock = ControlBlock(name: "root", function: nil, arguments: .arrayOfString([]))
    
    
    /// All function call in prioritized order (lowest index = first to execute)
    
    private var prioritizedFunctions: Array<FunctionBlock> = []
    
    
    /// The side of the data contained in this document
    
    public var estimatedMemoryConsumption: Int
    
    
    /// Create a new SFDocument
    ///
    /// - Parameters:
    ///   - path: The path of the file to read.
    ///   - data: The file content, optional, may be nil.
    ///   - filemanager: The filemanager to use.
    ///
    /// - Returns: nil if the file could not be read.
    
    private init?(path: String, data fileContent: Data?) {
        
        
        if let d = fileContent, let str = String(bytes: d, encoding: .utf8) {
            
            self.path = path
            self.filedata = str
            self.fileModificationDate = Date().javaDate
            self.estimatedMemoryConsumption = d.count
            
        } else {

            // Tests
        
            guard FileManager.default.isReadableFile(atPath: path) else { return nil }
            guard let fileattributes = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        
        
            // Retrieve necessary data
        
            guard let modificationDate = fileattributes[FileAttributeKey.modificationDate] as? Date else { return nil }
            guard let filesize = (fileattributes[FileAttributeKey.size] as? NSNumber)?.intValue else { return nil }
            guard let data = try? String(contentsOfFile: path) else { return nil }
            
        
            // Assignment
        
            self.path = path
            self.filedata = data
            self.fileModificationDate = modificationDate.javaDate
            self.estimatedMemoryConsumption = filesize
        }
        
        // Parsing of the file
        
        if !parse() {
            Log.atCritical?.log("Parse error in \(path), most likely cause is that the file cannot be converted to an UTF8 encoded string", type: "SFDocument")
            return nil
        }
    }
    
    
    /// Processes the function calls and merges the original document data with the results.
    
    public func getContent(with environment: Functions.Environment) -> Data {
        
        
        // Thread safety: All data that is updated and/or returned must reside in local (stack) storage.
        
        var info = Functions.Info()
        
                
        return blocks.getData(&info, environment) ?? Data()
    }
    
    
    /// Processes the function calls and merges the original document data with the results.
    
    public func getContent(info: inout Functions.Info, environment: Functions.Environment) -> Data {
                
        return blocks.getData(&info, environment) ?? Data()
    }

    
    /// Create a new Swiftfire Document.
    ///
    /// - Note: Threadsafe
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - data: The file content, if nil the file will be read. If set, the cache will not be used.
    ///
    /// - Returns: Nil if the file cannot be read.
    
    public static func factory(path: String, data: Data? = nil) -> BRUtils.Result<SFDocument> {
        
        return queue.sync(execute: {
            
            if data == nil {
                
                // Try to retrieve the document from cache
            
                if let doc = SFDocument.cache[path] {
                    if let fileattributes = try? FileManager.default.attributesOfItem(atPath: path) {
                        if let modificationDate = fileattributes[FileAttributeKey.modificationDate] as? Date  {
                            if modificationDate.javaDate <= doc.fileModificationDate {
                                return .success(doc)
                            }
                        }
                    }
                }
            }
            
            
            // Try to create a new document
            
            guard let doc = SFDocument(path: path, data: data) else {
                
                // Try to find reason for error
                
                guard FileManager.default.isReadableFile(atPath: path) else { return .error(message: "File not readable at \(path)") }
                guard let fileattributes = try? FileManager.default.attributesOfItem(atPath: path) else { return .error(message: "Cannot read file attributes at \(path)") }
                guard let _ = fileattributes[FileAttributeKey.modificationDate] as? Date else { return .error(message: "Cannot extract modification date from file attributes at \(path)") }
                
                return .error(message: "Cannot read file content at \(path)")
            }
            
            
            // Add the new document to the cache if it was created from file
            
            if data == nil {
                SFDocument.cache[path] = doc
            }
            
            return .success(doc)
        })
    }
}


fileprivate func getForLoopSource(_ args: Array<String>, _ info: inout Functions.Info, _ environment: Functions.Environment) -> ControlBlockIndexableDataSource? {
    
    guard args.count > 0 else {
        Log.atError?.log("No source specifier found")
        return nil
    }

    let selector = args[0].lowercased()
    
    switch selector {
        
    case "comments-for-approval": return environment.domain.comments.forApproval
    
    case "server-accounts":
        
        guard environment.serverAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        return environment.domain.accounts
    
    case "server-parameters":
        
        guard environment.serverAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        return serverParameters.controlBlockIndexableDataSource
        
    case "server-telemetry":
            
        guard environment.serverAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        return serverTelemetry.controlBlockIndexableDataSource

    case "server-blacklist":
        
        guard environment.serverAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        return serverAdminDomain.blacklist.controlBlockIndexableDataSource
    
    case "blacklist":
            
        guard environment.domainAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        guard args.count > 1 else {
            Log.atError?.log("Missing domain name")
            return nil
        }

        guard let domainName = readKey(args[1], using: info, in: environment) else {
            Log.atError?.log("Cannot read key: '\(args[1])'")
            return nil
        }

        return domainManager.domain(for: domainName)?.blacklist.controlBlockIndexableDataSource

    case "server-domains":
        
        if environment.account == nil { return nil } // Prevent alert on logout
        
        guard environment.serverAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        return domainManager.controlBlockIndexableDataSource

    case "comments":
        
        guard args.count > 1 else {
            Log.atError?.log("Missing comment section identifier")
            return nil
        }
        guard let id = readKey(args[1], using: info, in: environment) else {
            Log.atError?.log("Cannot read key: '\(args[1])'")
            return nil
        }
        return environment.domain.comments.getControlBlockIndexableDataSource(forCommentSectionIdentifier: id)

    case "domain-aliases":
        
        guard args.count > 1 else {
            Log.atError?.log("Missing domain name")
            return nil
        }
        guard let name = readKey(args[1], using: info, in: environment) else {
            Log.atError?.log("Cannot read key: '\(args[1])'")
            return nil
        }
        guard let domain = domainManager.domain(for: name) else { return nil }
        return domainManager.aliasControlBlockIndexableDataSource(forDomain: domain)

    case "domain-telemetry":
        
        guard environment.serverAdminIsLoggedIn else {
            Log.atAlert?.log("Attempt to use server admin priviledge by \(environment.account?.name ?? "")")
            return nil
        }

        var domain = environment.domain
        
        if args.count > 1 {
            guard let domainName = readKey(args[1], using: info, in: environment) else {
                Log.atError?.log("Cannot read key: '\(args[1])'")
                return nil
            }
            if let specifiedDomain = domainManager.domain(for: domainName) {
                domain = specifiedDomain
            }
        }
        
        return domain.telemetry.controlBlockIndexableDataSource
        
    default:
        Log.atError?.log("Unrecognised source specifier: \(selector)")
        return nil
    }
}
    
    
fileprivate func getForLoopRange(_ args: Array<String>, _ info: inout Functions.Info, _ environment: Functions.Environment) -> (Int, Int?)? {
    
    guard args.count > 0 else {
        Log.atError?.log("No source specifier found")
        return nil
    }

    let selector = args[0].lowercased()
    
    var skip: Int
    
    switch selector {
        
    case "comments-for-approval": skip = 1
    
    case "comments": skip = 2

    case "server-accounts": skip = 1
    
    case "server-blacklist": skip = 1

    case "server-domains": skip = 1

    case "server-parameters": skip = 1
        
    case "server-telemetry": skip = 1

    case "blacklist": skip = 1
        
    case "domain-telemetry": skip = 2

    case "domain-aliases": skip = 2

    default:
        Log.atError?.log("Unrecognised source specifier: \(selector)")
        return nil
    }

    if args.count == skip {
        return (0, nil)
    }
    
    if args.count == skip + 1 {
        guard let val = readKey(args[skip], using: info, in: environment) else {
            Log.atError?.log("Cannot read value for: \(args[skip])")
            return nil
        }
        guard let ival = Int(val) else {
            Log.atError?.log("Cannot read integer from: \(val)")
            return nil
        }
        return (ival, nil)
    }
    
    if args.count == skip + 2 {
        guard let startVal = readKey(args[skip], using: info, in: environment) else {
            Log.atError?.log("Cannot read value for: \(args[skip])")
            return nil
        }
        guard let start = Int(startVal) else {
            Log.atError?.log("Cannot read integer from: \(startVal)")
            return nil
        }
        guard let countKey = readKey(args[skip + 1], using: info, in: environment) else {
            Log.atError?.log("Cannot read value for: \(args[skip + 1])")
            return nil
        }
        guard let count = Int(countKey) else {
            Log.atError?.log("Cannot read integer from: \(countKey)")
            return nil
        }
        return (start, count)
    }
    
    Log.atError?.log("Too many arguments: \(args.count)")

    return nil
}


fileprivate func evaluateIf(_ args: Array<String>, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Bool {
    
    guard args.count >= 2 else {
        Log.atError?.log("Wrong number of arguments, expected >= 2, found \(args.count)")
        return false
    }
    
    let condition = args[1]
    
    switch condition {
    
    case "nil":
        
        guard args.count == 2 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(args.count)")
            return false
        }
        
        return readKey(args[0], using: info, in: environment) == nil
        
        
    case "not-nil":
        
        guard args.count == 2 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(args.count)")
            return false
        }
        
        return readKey(args[0], using: info, in: environment) != nil

        
    case "empty":
        
        guard args.count == 2 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(args.count)")
            return false
        }
        
        return readKey(args[0], using: info, in: environment)?.isEmpty ?? false

        
    case "not-empty":
        
        guard args.count == 2 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(args.count)")
            return false
        }
        
        return !(readKey(args[0], using: info, in: environment)?.isEmpty ?? false)

    
    case "equal", "equals":
        
        guard args.count == 3 else {
            Log.atError?.log("Wrong number of arguments, expected 4, found \(args.count)")
            return false
        }
        
        let first = readKey(args[0], using: info, in: environment)?.lowercased()
        let second = readKey(args[2], using: info, in: environment)?.lowercased()

        if first == nil {
            if second == nil {
                return true
            } else {
                return false
            }
        } else {
            return first == second
        }
        
        
    case "not-equal":
            
        guard args.count == 3 else {
            Log.atError?.log("Wrong number of arguments, expected 4, found \(args.count)")
            return false
        }
            
        let first = readKey(args[0], using: info, in: environment)?.lowercased()
        let second = readKey(args[2], using: info, in: environment)?.lowercased()

        return (first != nil) ? first != second : false

        
    case "true":
        
        guard args.count == 2 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(args.count)")
            return false
        }
        
        return readKey(args[0], using: info, in: environment) == "true"
        
        
    case "false":
        
        guard args.count == 2 else {
            Log.atError?.log("Wrong number of arguments, expected 3, found \(args.count)")
            return false
        }
        
        return readKey(args[0], using: info, in: environment) == "false"

        
    default:
        Log.atError?.log("Unknown condition \(condition)")
        return false
    }
}

/*
fileprivate func setupFor(_ args: Array<String>, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Bool {

    func getSource(for id: String) -> ControlBlockIndexableDataSource? {
        
        switch id {
        
        case "comments-for-approval": return environment.domain.comments.forApproval
        case "accounts": return environment.domain.accounts
        case "blacklist": return environment.domain.blacklist
        case "domains": return DomainControlBlockIndexableDataSource(domainManager)

        case "comments":
            guard let identifier = environment.request.info["comment-section-identifier"] else { return nil }
            return environment.domain.comments.getControlBlockIndexableDataSource(forCommentSectionIdentifier: identifier)

        case "aliases":
            guard let domainName = info["domain-name"] else { return nil }
            guard let domain = domainManager.domain(for: domainName) else { return nil }
            return AliasControlBlockIndexableDataSource(domainManager: domainManager, domain: domain)
        default:
            Log.atError?.log("Missing source for id: \(id)")
            return nil
        }
    }

    guard args.count == 1 || args.count == 3 else {
        Log.atError?.log("Wrong number of arguments (expected 1 or 3, found: \(args.count)")
        return false
    }
    
    guard let offsetStr = info["for-index"], let offsetIn = Int(offsetStr) else {
        Log.atError?.log("Missing offset in info")
        return false
    }
    
    let id = args[0].lowercased()
    guard let source = getSource(for: id) else { return false }
    
    info["for-count"] = String(source.nofElements)
    
    var startOffset: Int = 0
    var endOffset: Int = source.nofElements - 1
    
    if args.count == 3 {
        guard let so = Int(args[1]) else {
            Log.atError?.log("Cannot convert start offset to integer")
            return false
        }
        startOffset = so
        guard let eo = Int(args[2]) else {
            Log.atError?.log("Cannot convert end offset to integer")
            return false
        }
        endOffset = eo
    }
    
    let offset = max(startOffset, offsetIn)
    endOffset = min(endOffset, source.nofElements - 1)
    
    if offset > endOffset { return false }
    
    source.addElement(at: offset, to: &info)
        
    return true
}*/


/// Returns the data in cache if present and created after the timestamp. If not present (or after the timestamp) then the data is created anew and entered in the cache as well as returned.
///
/// - Parameters:
///   - forIdentifier: The identifier by which to locate the item in the cache
///   - ifCachedAfter: Int64, in JavaDate (msec since 1970-01-01)
///   - elseCreateFrom: The blocks from which to create the data anew
///   - info: The Function.Info dictionary needed by the block expansion
///   - environment: The environment needed by the block expansion

fileprivate func cachedData(forIdentifier identifier: String, ifCachedAfter timestamp: Int64, elseCreateFrom blocks: Array<SFDocument.Block>, info: inout Functions.Info, environment: Functions.Environment) -> Data {
    
    Log.atDebug?.log("Attempting to retrieve identifier \(identifier) for timestamp \(timestamp) (filter: modification)")
    
    // Check the cache first
    
    if let data = environment.domain.cache[identifier, timestamp] {
        return data
    }
    
    Log.atDebug?.log("Recreating cache content (filter: modification)")
    
    // Not in the cache, create it.
        
    var data = Data()
    blocks.forEach {
        if let d = $0.getData(&info, environment) {
            data.append(d)
        }
    }
    
    
    // Add it to the cache
    
    environment.domain.cache[identifier] = data
    
    
    // And return it
    
    return data
}
