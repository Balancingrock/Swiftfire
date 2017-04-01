// =====================================================================================================================
//
//  File:       SFDocument.swift
//  Project:    Swiftfire
//
//  Version:    0.10.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.10.0 - Initial release
//
// =====================================================================================================================
//
// A SFDocument (Swiftfire Document) is a document that has the 4 characters ".sf." in its filename.
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
import BRUtils
import SwiftfireCore


/// This encapsulates a swiftfire document in its parsed form.

final class SFDocument: EstimatedMemoryConsumption {

    
    static var cache = MemoryCache<String, SFDocument>(limitStrategy: .bySize(10*1024*1024), purgeStrategy: .leastUsed)
    
    
    /// A block of characters that does not contain a function.
    
    class CharacterBlock {
        
        /// The data in the block
        
        let data: Data
        
        
        /// Create a new instance
        
        init(data: Data) {
            self.data = data
        }
    }
    
    
    /// A block of characters that contains a function, with the details of the function completely parsed.
    
    class FunctionBlock {

        
        /// References the function closure
        
        let function: Function.Signature?
        
        
        /// The priority of the function
        
        let priority: Int
        
        
        /// The arguments in the function brackets.
        
        var arguments: Function.Arguments
        

        /// Data returned by the function
        
        var data: Data?
        
        
        /// Create a new instance
        
        init(function: Function.Signature?, priority: Int, arguments: Function.Arguments) {
            self.function = function
            self.priority = priority
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
    
    
    /// The buffer with all characters (UTF8) in the file
    
    let filedata: Data
    
    
    /// The time the file was last modified
    
    let fileModificationDate: Int64
    
    
    /// The results of the parser
    
    var blocks: Array<DocumentBlock> = []
    
    
    /// All function call in prioritized order (lowest index = first to execute)
    
    var prioritizedFunctions: Array<FunctionBlock> = []
    
    
    /// The side of the data contained in this document
    
    var estimatedMemoryConsumption: Int
    
    
    /// Create a new SFDocument
    ///
    /// - Parameters:
    ///   - path: The path of the file to read.
    ///   - filemanager: The filemanager to use.
    ///
    /// - Returns: nil if the file could not be read.
    
    private init?(path: String, filemanager: FileManager) {

        
        // Tests
        
        guard filemanager.isReadableFile(atPath: path) else { return nil }
        guard let fileattributes = try? filemanager.attributesOfItem(atPath: path) else { return nil }
        
        
        // Retrieve necessary data
        
        guard let modificationDate = fileattributes[FileAttributeKey.modificationDate] as? Date else { return nil }
        guard let filesize = (fileattributes[FileAttributeKey.size] as? NSNumber)?.intValue else { return nil }
        guard let data = filemanager.contents(atPath: path) else { return nil }
        
        
        // Assignment
        
        self.path = path
        self.filedata = data
        self.fileModificationDate = modificationDate.javaDate
        self.estimatedMemoryConsumption = filesize
        
        
        // Parsing of the file
        
        parse()
        
        
        // Prioritize
        
        prioritize()
    }
    
    
    /// Processes the function calls and merges the original document data with the results.
    
    func getContent(with environment: Function.Environment) -> Data {
        
        
        // First execute the functions in the prioritized order
        
        var info = Function.Info()
        
        prioritizedFunctions.forEach({
            $0.data = $0.function?($0.arguments, &info, environment)
        })
        
        
        // Merge the data
        
        var data = Data()
        
        blocks.forEach({
            
            switch $0 {
            case .characterBlock(let cb): data.append(cb.data)
            case .functionBlock(let fb): if let fbData = fb.data { data.append(fbData) }
            }
        })
        
        
        // Return the document
        
        return data
    }

    
    /// Create a new Swiftfire Document
    ///
    /// - Parameters:
    ///   - path: The path of the file.
    ///   - filemanager: The filemanager to use.
    ///
    /// - Returns: Nil if the file cannot be read.
    
    static func factory(path: String, filemanager: FileManager) -> Result<SFDocument> {
        
        
        // Try to retrieve the document from cache
        
        if let doc = SFDocument.cache[path] {
            if let fileattributes = try? filemanager.attributesOfItem(atPath: path) {
                if let modificationDate = fileattributes[FileAttributeKey.modificationDate] as? Date  {
                    if modificationDate.javaDate <= doc.fileModificationDate {
                         return .success(doc)
                    }
                }
            }
        }
        
        
        // Try to create a new document
        
        guard let doc = SFDocument(path: path, filemanager: filemanager) else {
            
            // Try to find reason for error
            
            guard filemanager.isReadableFile(atPath: path) else { return .error(message: "File not readable at \(path)") }
            guard let fileattributes = try? filemanager.attributesOfItem(atPath: path) else { return .error(message: "Cannot read file attributes at \(path)") }
            guard let _ = fileattributes[FileAttributeKey.modificationDate] as? Date else { return .error(message: "Cannot extract modification date from file attributes at \(path)") }
            
            return .error(message: "Cannot read file content at \(path)")
        }
        
        
        // Add the new document to the cache
        
        SFDocument.cache[path] = doc
        
        return .success(doc)
    }
    
    
    // Sorts the function blocks contained in the 'blocks' into the 'prioritizedFunctions' list. From high to low priority.
    // Called from 'init'.
    
    fileprivate func prioritize() {
        
        let functions = blocks.flatMap({
            block -> FunctionBlock? in
            if case let .functionBlock(fb) = block {
                return fb
            } else {
                return nil
            }
        })
        
        prioritizedFunctions = functions.sorted(by: { $0.priority > $1.priority })
    }
}
