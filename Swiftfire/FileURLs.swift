// =====================================================================================================================
//
//  File:       FileURLs.swift
//  Project:    Swiftfire
//
//  Version:    0.9.11
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// v0.9.11 - Added statistics support
// v0.9.7  - Added header logging and application log directory
//         - Removed startup file
//         - Made class final
// v0.9.6  - Header update
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation


final class FileURLs {
    
    
    /// The Application Support Directory
    
    static var appSupportDir: URL? = {
        
        let filemanager = FileManager.default
        
        do {
            
            let appSupportRootpath = try filemanager.urlForDirectory(
                FileManager.SearchPathDirectory.applicationSupportDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask,
                appropriateFor: nil,
                create: true)
            
            let appName = ProcessInfo.processInfo.processName
            let dirpath = try appSupportRootpath.appendingPathComponent(appName)
            
            try filemanager.createDirectory(atPath: dirpath.path!, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
            
        } catch {
            
            return nil
        }
    }()
    
    
    /// The directory containing the parameter and domain files with default values
    
    static private var settingsDir: URL? = {
        
        guard let appSupportDir = appSupportDir else { return nil }
        
        let filemanager = FileManager.default
        
        do {
            
            let dirpath = try appSupportDir.appendingPathComponent("settings")
            try filemanager.createDirectory(atPath: dirpath.path!, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
            
        } catch {
            
            return nil
        }
    }()
    
    
    /// The directory containing the logging files
    
    static private var loggingDir: URL? = {
        
        guard let appSupportDir = appSupportDir else { return nil }
        
        let filemanager = FileManager.default
        
        do {
            
            let dirpath = try appSupportDir.appendingPathComponent("logging")
            try filemanager.createDirectory(atPath: dirpath.path!, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
            
        } catch {
            
            return nil
        }
    }()

    
    /// The directory containing the header logging files
    
    static var headerLoggingDir: URL? = {
        
        guard let loggingDir = loggingDir else { return nil }
        
        let filemanager = FileManager.default
        
        do {
            
            let dirpath = try loggingDir.appendingPathComponent("headers")
            try filemanager.createDirectory(at: dirpath, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
            
        } catch {
            
            return nil
        }
    }()

    
    /// The directory containing the application log files
    
    static var applicationLogDir: URL? = {
        
        guard let loggingDir = loggingDir else { return nil }
        
        let filemanager = FileManager.default
        
        do {
            
            let dirpath = try loggingDir.appendingPathComponent("application")
            try filemanager.createDirectory(at: dirpath, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
            
        } catch {
            
            return nil
        }
    }()

    
    /// The directory for the statistics file
    
    static var statisticsDir: URL? = {
        
        guard let appSupportDir = appSupportDir else { return nil }

        let filemanager = FileManager.default

        do {
            
            let dirpath = try appSupportDir.appendingPathComponent("statistics")
            try filemanager.createDirectory(at: dirpath, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
        
        } catch {

            return nil
        }
    }()

    
    /// The file with parameter defaults
    
    static var parameterDefaults: URL? = {
        
        guard let dirpath = settingsDir else { return nil }
        
        do {
            
            return try dirpath.appendingPathComponent("parameter-defaults.json")

        } catch {
            
            return nil
        }
    }()
    
    
    /// The file with domain defaults
    
    static var domainDefaults: URL? = {
        
        guard let dirpath = settingsDir else { return nil }
        
        do {
            
            return try dirpath.appendingPathComponent("domain-defaults.json")
            
        } catch {
            
            return nil
        }
    }()

    
    /// Determines if a file exists and is not a directory
    
    static func exists(url: URL?) -> Bool {
        
        if url == nil { return false }
        
        var isDir: ObjCBool = false
        
        let exists = FileManager.default.fileExists(atPath: url!.path!, isDirectory: &isDir)
        
        return exists && !isDir
    }
}
