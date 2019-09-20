// =====================================================================================================================
//
//  File:       Urls.swift
//  Project:    Swiftfire
//
//  Version:    1.2.1
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
// 1.2.1 - Removed incorrect info
//       - Removed serveradmin directory (was unused)
// 1.1.0 - Replaced server blacklist with serverAdminDomain blacklist
// 1.0.0 - Raised to v1.0.0, Removed old change log,
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
// - statistics
//   - statistics.json
//
// =====================================================================================================================

import Foundation


public final class Urls {
    
    
    /// Determines if a file exists and is not a directory
    
    public static func exists(url: URL?) -> Bool {
        if url == nil { return false }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url!.path, isDirectory: &isDir)
        if isDir.boolValue { return false }
        return exists
    }


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
    
    
    // =================================================================================================================
    /// The directory for the server telemetry
    
    public static var serverTelemetryDir: URL? = { dirUrl(rootDir, "telemetry") }()

    
    // =================================================================================================================
    /// The directory containing the logging files
    
    public static var logsDir: URL? = { dirUrl(rootDir, "logs") }()

    
    // =================================================================================================================
    /// The directory containing the header logging files
    
    public static var headersLogDir: URL? = { dirUrl(logsDir, "headers") }()

    
    // =================================================================================================================
    /// The directory containing the application log files (These are files that are written by SwifterLog)
    
    public static var applicationLogDir: URL? = { dirUrl(logsDir, "application") }()


    // =================================================================================================================
    /// The directory for the domains (and aliasses)
    
    public static var domainsDir: URL? = { dirUrl(rootDir, "domains") }()
    
    
    /// The file with domain defaults
    
    public static var domainsAndAliasesFile: URL? = { fileUrl(domainsDir, "domainsAndAliases.json") }()
    
    
    // =================================================================================================================
    /// The root directory for a domain
    
    public static func domainDir(for name: String) -> URL? { return dirUrl(domainsDir, name) }

    
    /// The domain accounts directory
    
    public static func domainAccountsDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "accounts") }

    
    /// The directory for domain logfiles
    
    public static func domainLoggingDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "logging") }

    
    /// The directory for 404 logfiles
    
    public static func domainFour04LogDir(for name: String) -> URL? { return fileUrl(domainLoggingDir(for: name), "four04Logs")}

    
    /// The directory for access logfiles
    
    public static func domainAccessLogDir(for name: String) -> URL? { return fileUrl(domainLoggingDir(for: name), "accessLogs")}


    /// The sessions logging directory
    
    public static func domainSessionLogDir(for name: String) -> URL? { return dirUrl(domainLoggingDir(for: name), "sessions") }
    

    /// The directory for the domain statistics
    
    public static func domainStatisticsDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "statistics") }

    
    /// The directory for the domain settings
    
    public static func domainSettingsDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "settings") }

    
    /// The file with the setup information for a domain
    
    public static func domainSetupFile(for name: String) -> URL? {
        return fileUrl(domainSettingsDir(for: name), "setup.json")
    }

    
    /// The file with the services names for a domain
    
    public static func domainServiceNamesFile(for name: String) -> URL? {
        return fileUrl(domainSettingsDir(for: name), "service-names.json")
    }

    
    /// The file for clients blacklisted by the domain
    
    public static func domainBlacklistFile(for name: String) -> URL? {
        return fileUrl(domainSettingsDir(for: name), "blacklist.json")
    }


    /// The directory for the domain SSL certificates and keys
    
    public static func domainSslDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "ssl") }

    
    /// The directory for the domain PHP messages
    
    public static func domainPhpDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "php") }

    
    /// The directory for the domain comments section
    
    public static func domainCommentsRootDir(for name: String) -> URL? { return dirUrl(domainDir(for: name), "comments") }
    
    
    /// The file for the domain hit counters
    
    public static func domainHitCountersDir(for name: String) -> URL? { return fileUrl(domainDir(for: name), "hit-counters") }

    
    /// The file for the domain telemetry
    
    public static func domainTelemetryDir(for name: String) -> URL? { return fileUrl(domainDir(for: name), "telemetry") }
    
    
    /// The file with account names waiting for verification
    
    public static func domainAccountNamesWaitingForVerificationFile(for name: String) -> URL? { return fileUrl(domainDir(for: name), "accountNamesWaitingForVerification") }
}
