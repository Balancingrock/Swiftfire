// =====================================================================================================================
//
//  File:       FileURLs.swift
//  Project:    Swiftfire
//
//  Version:    0.9.17
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// 0.9.17  - Added paths for secure console connections
// 0.9.15  - General update and switch to frameworks
// 0.9.14  - Added serverBlacklist
//         - Upgraded to Xcode 8 beta 6
// 0.9.13  - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11  - Added statistics support
// 0.9.7   - Added header logging and application log directory
//         - Removed startup file
//         - Made class final
// 0.9.6   - Header update
// 0.9.0   - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// All files and directories are relative to the root directory in "~/Library/Application Support/Swiftfire".
//
// root
// - ssl
//   - trusted-console-certificates
//   - console
//     - certificate.pem
//     - private-key.pem
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


final class FileURLs {
    
    
    /// Create a directory url and ensure that the directory exists.
    ///
    /// - Parameters:
    ///   - root: The directory in/from which to create/retrieve the requested directory
    ///   - name: The name for the directory
    
    private static func dirUrl(_ root: URL?, _ name: String) -> URL? {
        
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
    
    private static func fileUrl(_ root: URL?, _ name: String) -> URL? {
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
    
    static var sslDir: URL? = { dirUrl(rootDir, "ssl") }()
    
    
    /// The directory with trusted console certificates
    
    static var sslTrustedConsoleCertificatesDir: URL? = { dirUrl(sslDir, "trusted-console-certificates") }()
    
    
    /// The directory with certificate and key for the console connection
    
    static var sslConsoleDir: URL? = { dirUrl(sslDir, "console") }()
    
    
    /// The certificate to be used for the console connection
    
    static var sslConsoleCertificateFile: URL? = { fileUrl(sslConsoleDir, "certificate.pem") }()

    
    /// The private key to be used for the console connection
    
    static var sslConsolePrivateKeyFile: URL? = { fileUrl(sslConsoleDir, "privateKey.pem") }()
    
    
    // =================================================================================================================
    /// The directory containing the parameter and domain files with default values
    
    static var settingsDir: URL? = { dirUrl(rootDir, "settings") }()
    
    
    /// The file with parameter defaults
    
    static var parameterDefaultsFile: URL? = { fileUrl(settingsDir, "parameter-defaults.json") }()
    
    
    /// The file with blacklisted addresses
    
    static var serverBlacklistFile: URL? = { fileUrl(settingsDir, "server-blacklist.json") }()

    
    // =================================================================================================================
    /// The directory containing the logging files
    
    static var logsDir: URL? = { dirUrl(rootDir, "logs") }()

    
    /// The directory containing the header logging files
    
    static var headersLogDir: URL? = { dirUrl(logsDir, "headers") } ()

    
    /// The directory containing the application log files
    
    static var applicationLogDir: URL? = { dirUrl(logsDir, "application") } ()

    
    // =================================================================================================================
    /// The directory for the statistics file
    
    static var statisticsDir: URL? = { dirUrl(rootDir, "statistics") }()

    
    /// The file with statistics information
    
    static var statisticsFile: URL? = { fileUrl(statisticsDir, "statistics.json") }()

    
    // =================================================================================================================
    /// The directory for the domains
    
    static var domainsDir: URL? = { dirUrl(rootDir, "domains") }()
    
    
    /// The file with domain defaults
    
    static var domainDefaultsFile: URL? = { fileUrl(domainsDir, "domain-defaults.json") }()
    
    
    /// Determines if a file exists and is not a directory
    
    static func exists(url: URL?) -> Bool {
        if url == nil { return false }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url!.path, isDirectory: &isDir)
        if isDir.boolValue { return false }
        return exists
    }
}
