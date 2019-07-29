// =====================================================================================================================
//
//  File:       StorageUrls.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// All files and directories are relative to the root directory in "~/Library/Application Support/Swiftfire".
//
// root
// - ssl
//   - server
// - domains
//   - domain-defaults.json
//   - ... subdirectories for each domain
// - settings
//   - parameter-defaults.json
//   - server-blacklist.json
// - logs
//   - headers
//   - application
//     - ... logfiles from SwifterLog
// - serveradmin
//   - ... as for domains
// - statistics
//   - statistics.json
//
// =====================================================================================================================

import Foundation


public final class StorageUrls {
    
    
    /// Create a directory url and ensure that the directory exists.
    ///
    /// - Parameters:
    ///   - root: The directory in/from which to create/retrieve the requested directory
    ///   - name: The name for the directory
    
    static func dirUrl(_ root: URL?, _ name: String) -> URL? {
        
        guard let root = root else { return nil }
        
        do {
            
            let url = root.appendingPathComponent(name)
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
            return url
            
        } catch { return nil }
    }
    
    
    /// Create a file url
    ///
    /// - Parameters:
    ///   - root: The directory in/from which to create/retrieve the requested file
    ///   - name: The name for the file
    
    static func fileUrl(_ root: URL?, _ name: String) -> URL? {
        guard let root = root else { return nil }
        return root.appendingPathComponent(name)
    }
    

    /// The root directory (Application Support Directory)
    
    static var rootDir: URL? = {
        
        let filemanager = FileManager.default
        
        do {
            let appSupportRootpath = try filemanager.url(
                for: FileManager.SearchPathDirectory.applicationSupportDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask,
                appropriateFor: nil,
                create: true)
            
            let appName = ProcessInfo.processInfo.processName
            let dirpath = appSupportRootpath.appendingPathComponent(appName)
            try filemanager.createDirectory(atPath: dirpath.path, withIntermediateDirectories: true, attributes: nil)
            
            return dirpath
            
        } catch { return nil }
    }()
    
    
    // =================================================================================================================
    /// Ssl support directory
    
    public static var sslDir: URL? = { dirUrl(rootDir, "ssl") }()
    
    
    /// The directory for the server certificate & private key
    
    public static var sslServerDir: URL? = { dirUrl(sslDir, "server") }()
    
    
    // =================================================================================================================
    /// The directory containing the parameter and domain files with default values
    
    public static var settingsDir: URL? = { dirUrl(rootDir, "settings") }()
    
    
    /// The file with parameter defaults
    
    public static var parameterDefaultsFile: URL? = { fileUrl(settingsDir, "parameter-defaults.json") }()
    
    
    /// The file with blacklisted addresses
    
    public static var serverBlacklistFile: URL? = { fileUrl(settingsDir, "server-blacklist.json") }()
    
    
    // =================================================================================================================
    /// The directory containing the logging files
    
    public static var logsDir: URL? = { dirUrl(rootDir, "logs") }()

    
    /// The directory containing the header logging files
    
    public static var headersLogDir: URL? = { dirUrl(logsDir, "headers") }()

    
    /// The directory containing the application log files
    
    public static var applicationLogDir: URL? = { dirUrl(logsDir, "application") }()

        
    // =================================================================================================================
    /// The directory for the statistics file
    
    public static var serverAdminDir: URL? = { dirUrl(rootDir, "serveradmin") }()

    
    // =================================================================================================================
    /// The directory for the statistics file
    
    public static var statisticsDir: URL? = { dirUrl(rootDir, "statistics") }()

    
    /// The file with statistics information
    
    public static var statisticsFile: URL? = { fileUrl(statisticsDir, "statistics.json") }()

    
    // =================================================================================================================
    /// The directory for the domains
    
    public static var domainsDir: URL? = { dirUrl(rootDir, "domains") }()
    
    
    /// The file with domain defaults
    
    public static var domainDefaultsFile: URL? = { fileUrl(domainsDir, "domain-defaults.json") }()
    
    
    /// Determines if a file exists and is not a directory
    
    public static func exists(url: URL?) -> Bool {
        if url == nil { return false }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url!.path, isDirectory: &isDir)
        if isDir.boolValue { return false }
        return exists
    }
}
