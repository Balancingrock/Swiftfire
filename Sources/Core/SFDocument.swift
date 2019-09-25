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


/// This encapsulates a swiftfire document in its parsed form.

public  class SFDocument: EstimatedMemoryConsumption {

    
    /// This cache contains SFDocuments that have already been processed.
    
    private static var cache: MemoryCache<String, SFDocument> = {
        let cacheSize = serverParameters.sfDocumentCacheSize.value * 1024 * 1024
        return MemoryCache<String, SFDocument>(limitStrategy: .bySize(cacheSize), purgeStrategy: .leastUsed)
    }()
    
    
    /// Protect the cache processing functions
    
    private static let queue = DispatchQueue(label: "SFDocument cache", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes(), autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    
    
    /// A block of characters that does not contain a function.
    
    final class CharacterBlock: CustomStringConvertible {
        
        
        /// The data in the block
        
        let data: Data
        
        
        /// CustomStringConvertible
        
        var description: String {
            return "Characterblock contains \(data.count) bytes"
        }
        
        
        /// Create a new instance
        
        init(data: Data) {
            self.data = data
        }
    }
    
    
    /// A block of characters that contains a function, with the details of the function completely parsed.
    
    final class FunctionBlock: CustomStringConvertible {
        
        
        /// The name of this function
        
        let name: String
        
        
        /// References the function closure
        
        let function: Functions.Signature?
        
        
        /// The arguments in the function brackets.
        
        var arguments: Functions.Arguments
        

        /// CustomStringConvertible
        
        var description: String {
            return "FunctionBlock for function: \(name), with arguments: \(arguments)"
        }
        
        
        /// Create a new instance
        
        init(name: String, function: Functions.Signature?, arguments: Functions.Arguments) {
            self.name = name
            self.function = function
            self.arguments = arguments
        }
    }
    
    
    /// The blocks that are contained in a document
    
    enum DocumentBlock {
        case characterBlock(CharacterBlock)
        case functionBlock(FunctionBlock)
    }
    
    
    /// The path on disk of the file
    
    let path: String
    
    
    /// The buffer with all characters in the file
    
    let filedata: String
    
    
    /// The time the file was last modified
    
    let fileModificationDate: Int64
    
    
    /// The results of the parser
    
    var blocks: Array<DocumentBlock> = []
    
    
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
    
    public func getContent(with environment: inout Functions.Environment) -> Data {
        
        // Thread safety: All data that is updated and/or returned must reside in local (stack) storage.
        
        var info = Functions.Info()
        
        var data = Data()
        
        blocks.forEach({
            
            switch $0 {
            case .characterBlock(let cb): data.append(cb.data)
            case .functionBlock(let fb):
                if let fbData = fb.function?(fb.arguments, &info, &environment) {
                    data.append(fbData)
                }
            }
        })
        
        
        // Return the document

        return data
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
    
    public static func factory(path: String, data: Data? = nil) -> Result<SFDocument> {
        
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
