// =====================================================================================================================
//
//  File:       FileManager.Extensions.swift
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
// 1.3.0 - Added testFor
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation


public extension FileManager {
    
    
    /// For the result of the corresponding function.
    
    enum ReadableResourceFileExistsResult { case doesNotExist, cannotBeRead, isDirectoryWithoutIndex, exists(path: String) }
    
    
    /// This function implements the Swiftfire search algorithm to identify a resource based on requested path.
    ///
    /// The search algorithm is as follows:
    ///
    /// - If the resource denotes a readable file which matches the path exactly, it will be returned.
    ///
    /// - If the resource denotes a directory, it will accept -in this directory, if domain settings allow- the first file matching: index.sf.html, index.sf.htm, index.html, index.htm, index.sf.php, index.php.
    ///
    /// - If the resource denotes a non-existent resource at `path.extenstion`, it will return `path.sf.extension` if that exists. If the extension is `html` it will also test for `htm`, if it is `htm` it will also test for `thml`. If these does not exists and the domain allows php coded html, then it will also look for `path.sf.php` and `path.php` in that sequence.
    ///
    /// - Parameters:
    ///   - at: The absolute path for the resource. Even though a domain must also be specified, the webroot parameter from the domain will not be used!
    ///   - for: The domain for which the test is made. This is used only for the evaluation of files with the 'php' extension.
    
    func readableResourceFileExists(at path: String, for domain: Domain) -> ReadableResourceFileExistsResult {

        
        // Check if something exists, either a readable file or a directory
        
        var isDir: ObjCBool = false
        if self.fileExists(atPath: path, isDirectory: &isDir) {
            
            if !isDir.boolValue {
            
                // It must be readable for success
                
                if self.isReadableFile(atPath: path) {
                    return .exists(path: path)
                } else {
                    return .cannotBeRead
                }
            }
            
            // If it is a directory continue below
        }
        
        
        // At this point there is no resource file, but there can be a directory
        
        // Create a list of possible resources to check for
        
        var resourcePathsToTestFor: Array<String> = []
        
        if isDir.boolValue {
            
            // The path is a directory
            
            resourcePathsToTestFor.append((path as NSString).appendingPathComponent("index.sf.html"))
            resourcePathsToTestFor.append((path as NSString).appendingPathComponent("index.sf.htm"))
            resourcePathsToTestFor.append((path as NSString).appendingPathComponent("index.html"))
            resourcePathsToTestFor.append((path as NSString).appendingPathComponent("index.htm"))
            
            if (domain.phpPath != nil) && domain.phpMapIndex {
                
                resourcePathsToTestFor.append((path as NSString).appendingPathComponent("index.sf.php"))
                resourcePathsToTestFor.append((path as NSString).appendingPathComponent("index.php"))
            }
            
        } else {
            
            // The path is not a directory
            
            let pathWithoutExtension = (path as NSString).deletingPathExtension
            let pathExtension = (path as NSString).pathExtension

            if (pathExtension.lowercased() == "htm") || (pathExtension.lowercased() == "html") {
            
                resourcePathsToTestFor.append(pathWithoutExtension + ".sf.html")
                resourcePathsToTestFor.append(pathWithoutExtension + ".sf.htm")
                resourcePathsToTestFor.append(pathWithoutExtension + ".html")
                resourcePathsToTestFor.append(pathWithoutExtension + ".htm")
            
                if (domain.phpPath != nil) && domain.phpMapAll {
                    
                    resourcePathsToTestFor.append(pathWithoutExtension + ".sf.php")
                    resourcePathsToTestFor.append(pathWithoutExtension + ".php")
                }

            } else {
                
                resourcePathsToTestFor.append(pathWithoutExtension + ".sf." + pathExtension)
            }

        }
        
        
        // Get the first match
        
        for pathToTest in resourcePathsToTestFor {
            if self.isReadableFile(atPath: pathToTest) {
                return .exists(path: pathToTest)
            }
        }
        
        
        // No resource can be found
        
        if isDir.boolValue {
            return .isDirectoryWithoutIndex
        } else {
            return .doesNotExist
        }
    }
    
    
    /// The result of the testFor operation
    ///
    ///
    
    enum TestForResult {
        
        
        /// In case the file does not exist or is neither writable or readable, no writable directory and the directory was not created.
        
        case fail
        
        
        /// When the directory is readable but not writeable.
        
        case isReadableDir
        
        
        /// When the directory exists, and can be written to.
        
        case isWriteableDir
        
        
        /// When the file exists and is readable but not writeable.
        
        case isReadableFile
        
        
        /// When the file exists and is readable and writeable.
        
        case isWriteableFile
    }
    
    
    /// Test the directory and file for existence and readability/writeability. Optionally creates the directory for the file.
    ///
    /// This operation is intended to be used for those cases a file must be read (and possibly written) but it is not sure if the file already exists or not. When the file does not exist the necessary directory structure can be generated instead such that the file can be created afterwards.
    ///
    /// - Parameters:
    ///   - dir: The path for the directory
    ///   - file: The filename plus extension
    ///   - createDir: A flag that requests creation of the directory if it does not exist (including intermediates)
    
    func testFor(_ dir: NSString, file: String, createDir: Bool = false) -> TestForResult {
        
        let path = dir.appendingPathComponent(file)

        var isDir: ObjCBool = false
        
        
        // Quick exit for nominal cases
        
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            
            if FileManager.default.isWritableFile(atPath: path) {
                return .isWriteableFile
            }
            
            if FileManager.default.isReadableFile(atPath: path) {
                return .isReadableFile
            }
            
            return .fail
        }
        
        
        // The file does not exist, check if the directory exists
        
        if FileManager.default.fileExists(atPath: dir as String) {
            
            if FileManager.default.isWritableFile(atPath: dir as String) {
                return .isWriteableDir
            }
            
            if FileManager.default.isReadableFile(atPath: dir as String) {
                return .isReadableDir
            }
            
            return .fail

            
        } else {
            
            if createDir {
                
                // The directory does not exist, try to create it
            
                if (try? FileManager.default.createDirectory(at: URL(fileURLWithPath: dir as String, isDirectory: true), withIntermediateDirectories: true)) != nil {

                    return .isWriteableDir
                
                }
            }
                
            return .fail
        }
    }

    
    /// Returns the modification date of the file in msec since 1970.01.01 (Java date).
    ///
    /// This is a convenience wrapper for modificationDateOfFile:atPath.
    ///
    /// - Parameter of: The URL of the file.
    ///
    /// - Returns: The modification date of the file. nil if the file does not exist.
    
    func modificationDateOfFile(atUrl url: URL) -> Int64? {

        return modificationDateOfFile(atPath: url.path)
    }

    
    /// Returns the modification date of the file in msec since 1970.01.01 (Java date).
    ///
    /// There is also a convenience wrapper modificationDateOfFile:atUrl
    ///
    /// - Parameter of: The path of the file.
    ///
    /// - Returns: The modification date of the file. nil if the file does not exist.
    
    func modificationDateOfFile(atPath path: String) -> Int64? {

        return try? (FileManager.default.attributesOfFileSystem(forPath: path) as NSDictionary).fileModificationDate()?.javaDate
    }

}
