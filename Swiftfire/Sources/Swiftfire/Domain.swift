// =====================================================================================================================
//
//  File:       Domain.swift
//  Project:    Swiftfire
//
//  Version:    0.10.11
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.12 - Upgraded to SwifterLog 1.1.0
// 0.10.11 - Replaced SwifterJSON with VJson
// 0.10.9 - Streamlined and folded http API into its own project
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Added sessionTimeout
//        - Added sessionLogEnable
//        - Added sessions
//        - Changed updating of items
// 0.10.3 - Bugfix: Added unwrap before using loggingDir
// 0.9.18 - Bugfix: name of folder updated when domain name changes
//        - Added certificateDir
//        - Added ctx
// 0.9.17 - Header update
//        - Made the supportDirectory optional
// 0.9.15 - General update and switch to frameworks, SwiftfireCore split.
// 0.9.14 - Added client blacklist
//        - Added swiftfire-resource directory setting
//        - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Removed domain statistis.
//        - Updated for VJson 0.9.8
// 0.9.10 - Added domain statistics.
// 0.9.8  - Fixed bug that would prevent the creation of accessLog and four04Log
// 0.9.7  - Added logging options for Access and 404
// 0.9.6  - Header update
//        - Changed init(json) to accept initializations without telemetry
// 0.9.4  - Accomodated new VJson testing
//        - Made _name private
// 0.9.3  - Added domain telemetry
//        - Corrected description of forwardUrlItemTitle
// 0.9.2  - Removed 'final' from the class definition
//        - Added enableHttpPreprocessor, enableHttpPostprocessor, httpWorkerPreprocessor and httpWorkerPostprocessor
// 0.9.0  - Initial release
//
// =====================================================================================================================

import Foundation
import VJson
import SwifterLog
import SecureSockets
import BRUtils
import Http


/// An extension to allow easier creation of an array of VJson objects.

extension String: VJsonSerializable {
    public var json: VJson { return VJson(self) }
}


/// Represents an internet domain.

public final class Domain: CustomStringConvertible, VJsonConvertible {
    
/*    public static func == (lhs: Domain, rhs: Domain) -> Bool {
        if lhs.name as String != rhs.name as String { return false }
        if lhs.wwwIncluded != rhs.wwwIncluded { return false }
        if lhs.root as String != rhs.root as String { return false }
        if lhs.sfresources as String != rhs.sfresources as String { return false }
        if lhs.forwardUrl as String != rhs.forwardUrl as String { return false }
        if lhs.enabled != rhs.enabled { return false }
        if lhs.accessLogEnabled != rhs.accessLogEnabled { return false }
        if lhs.four04LogEnabled != rhs.four04LogEnabled { return false }
        if lhs.sessionLogEnabled != rhs.sessionLogEnabled { return false }
        if lhs.sessionTimeout != rhs.sessionTimeout { return false }
        return true
    }*/

    
    /// A notification with this name is fired when the name of this domain is changed.
    
    public static let nameChangedNotificationName = Notification.Name("NameChanged")
    
    
    /// The domain name plus extension. Use the 'www' prefix if it is necessary to differentiate between two domains: one with and one without the 'www'.
    ///
    /// - Note: The name will always be all-lowercase, even when set using uppercase letters.
    
    public var name: String {
        set {
            if _name != newValue.lowercased() {
    
                // Update the _name
                let oldValue = _name
                self._name = newValue.lowercased()
                
                // Change the name of the support directory
                let olddir = supportDirectory
                let newdir = olddir.deletingLastPathComponent().appendingPathComponent(newValue.lowercased())
                try? FileManager.default.moveItem(at: olddir, to: newdir)
                supportDirectory = newdir
                
                
                // Post the name change notification
                NotificationCenter.default.post(name: Domain.nameChangedNotificationName, object: self, userInfo: ["Old" : oldValue, "New" : newValue])
            }
        }
        get {
            return self._name
        }
    }
    private var _name: String
    
    
    /// If the domain should map both the name with 'www' and without it to the same root, set this value to 'true'
    
    public var wwwIncluded: Bool = true
    
    
    /// The root folder for this domain.
    
    public var root: String = "/Library/WebServer/Documents"
    
    
    /// The Swiftfire resource directory
    
    public var sfresources: String = ""
    
    
    /// If this is non-empty, the domain will be rerouted to this host. The HTTP header host field will remain unchanged. Even when re-routed to another port. The host must be identified as an <address>:<port> combination where either address or port is optional.
    /// Example: domain = "mysite.com", forewardUrl = "yoursite.org" results in rerouting all "mysite.com" requests to "yoursite.org"
    /// Example: domain = "mysite.com", forewardUrl = ":6777" results in rerouting all "mysite.com" requests to "mysite.com:6777"
    /// Example: domain = "mysite.com", forewardUrl = "yoursite.org:6777" results in rerouting all "mysite.com" requests to "yoursite.org:6777"

    public var forwardUrl: String  {
        
        get {
            guard let newHost = forwardHost else { return "" }
            return newHost.description
        }
        
        set {
            
            if newValue.isEmpty { forwardHost = nil ; return }
            
            let value = newValue.trimmingCharacters(in: NSCharacterSet.whitespaces)
            
            if value.isEmpty { forwardHost = nil ; return }
                
            
            // Split at ':' character
                
            var strs = value.components(separatedBy: ":")
                
                
            // If there is one item, then there is no ':' in the string, the new value is then the address
                
            if strs.count == 1 { forwardHost = Http.Host(address: value, port: nil) ; return }
                
            
            // The first item is the address, the second is the port.
            // Note: both may still be empty at this point

            if strs.count == 2 {
                
                let rawAddress = strs[0].trimmingCharacters(in: NSCharacterSet.whitespaces)
                let address = rawAddress.isEmpty ? "localhost" : rawAddress
                
                let rawPort = strs[1].trimmingCharacters(in: NSCharacterSet.whitespaces)
                let port: String? = rawPort.isEmpty ? nil : rawPort
                
                forwardHost = Http.Host(address: address, port: port)
                
            } else {
                
                // This is an error
                
                forwardHost = nil
            }
        }
    }
    
    
    /// The host to which to forward requests
    ///
    /// This value is set by assigning a new value to forwardUrl.
    
    public private(set) var forwardHost: Http.Host?
    
    
    /// Can be used to (temporary) disable a domain without destroying all associated settings, logfiles, data etc.
    
    public var enabled: Bool = false
    
    
    /// Enables the access log when set to true
    
    public var accessLogEnabled: Bool = false {
        didSet {
            // Exit if nothing changed
            guard accessLogEnabled != oldValue else { return }
            
            if accessLogEnabled {
                if accessLog == nil {
                    if let loggingDir = loggingDir {
                        accessLog = AccessLog(logDir: loggingDir)
                    }
                }
            } else {
                accessLog?.close()
                accessLog = nil
            }
        }
    }
    
    
    /// Enables the 404 log when set to true
    
    public var four04LogEnabled: Bool = false {
        didSet {
            // Exit if nothing changed
            guard four04LogEnabled != oldValue else { return }
            
            if four04LogEnabled {
                if four04Log == nil {
                    if let loggingDir = loggingDir {
                        four04Log = Four04Log(logDir: loggingDir)
                    }
                }
            } else {
                four04Log?.close()
                four04Log = nil
            }
        }
    }
    
    
    /// Enables the session log when set to true
    
    public var sessionLogEnabled: Bool = false {
        didSet {
            // Exit if nothing changed
            guard sessionLogEnabled != oldValue else { return }
            
            if sessionLogEnabled {
                sessions.logDirUrl = sessionLogDir
            } else {
                sessions.logDirUrl = nil
            }
        }
    }
    
    
    /// The session timeout in seconds. A value of <= 0 means that no sessions will be created.
    
    public var sessionTimeout: Int = 0
    
    
    /// The domain specific blacklist
    
    public var blacklist = Blacklist()
    
    
    /// The names of the services used by this domain.
    
    public var serviceNames: Array<String> = [] {
        didSet {
            rebuildServices()
        }
    }
    
    
    /// The services used by this domain.
    ///
    /// The sequence of the services is given by their place in the array, services start at index'first.
    ///
    /// - Note: The user has to ensure that the values are current and synchronised with serviceNames.

    public var services: Array<Service.Entry> = []
    
    
    /// The domain telemetry
    
    public var telemetry: DomainTelemetry = DomainTelemetry()
    
    
    /// The visitor statistics database
    
    private var statistics: VisitorStatistics?
    
    
    /// The number of visits per statistics file
    
    private var visitsPerStatisticsFile: Int = 1000
    
    
    /// Daily wrap of staticstics file
    ///
    /// Note: The actual rollover time is determined by the time of the first access after this time.
    
    private var statisticsRolloverTime: WallclockTime = WallclockTime(hour: 0, minute: 0, second: 0)
    
    
    /// The number of recent request logs to be kept
    
    private var nofRecentRequestLogs: Int = 0
    
    
    /// The number of recent response logs to be kept
    
    private var nofRecentResponseLogs: Int = 0
    

    // The access log & 404 log
    
    private var accessLog: AccessLog?
    private var four04Log: Four04Log?
    
    
    /// Adding to the access log
    
    public func recordInAccessLog(time: Int64, ipAddress: String, url: String, operation: String, version: String) {
        if accessLogEnabled {
            accessLog?.record(time: time, ipAddress: ipAddress, url: url, operation: operation, version: version)
        }
    }
    
    
    /// Adding to the 404 log
    
    public func recordIn404Log(_ resourcePath: String) {
        if four04LogEnabled {
            four04Log?.record(message: resourcePath)
        }
    }
    
    
    /// The sessions for this domain
    
    public var sessions: Sessions!

    
    /// The accounts associated withthis domain
    
    public var accounts: Accounts!
    
    
    // The support directories for this domain
    
    public var supportDirectory: URL {
        didSet {
            // Cycle the logfiles off/on to make sure they are created in the right directory
            if accessLogEnabled {
                accessLogEnabled = false
                accessLogEnabled = true
            }
            if four04LogEnabled {
                four04LogEnabled = false
                four04LogEnabled = true
            }
        }
    }
    
    
    /// The directory for the access & 404 log files
    
    private lazy var loggingDir: URL? = {
        let dir = self.supportDirectory
        do {
            let url = dir.appendingPathComponent("logging", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            return nil
        }
    }()
    
    
    /// The directory for the statistics files
    
    private lazy var statisticsDir: URL? = {
        let dir = self.supportDirectory
        do {
            let url = dir.appendingPathComponent("statistics", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            return nil
        }
    }()

    
    /// The directory for the settings files.
    
    private lazy var settingsDir: URL? = {
        let dir = self.supportDirectory
        do {
            let url = dir.appendingPathComponent("settings", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            return nil
        }
    }()
    
    
    /// The directory for the certificate files.
    
    private lazy var sslDir: URL? = {
        let dir = self.supportDirectory
        do {
            let url = dir.appendingPathComponent("ssl", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            return nil
        }
    }()

    
    /// The directory for the session log files.
    
    private lazy var sessionLogDir: URL? = {
        guard let dir = self.loggingDir else { return nil }
        do {
            let url = dir.appendingPathComponent("sessions", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            return nil
        }
    }()
    
    
    /// The directory for the account files.
    
    private lazy var accountsDir: URL? = {
        let dir = self.supportDirectory
        do {
            let url = dir.appendingPathComponent("accounts", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            return nil
        }
    }()
    
    
    /// The file for the blacklisted clients
    
    private lazy var blacklistedClientsUrl: URL? = {
        guard let settingsDir = self.settingsDir else { return nil }
        return settingsDir.appendingPathComponent("blacklistedClients.json", isDirectory: false)
    }()

    
    /// The JSON representation for this object
    
    public var json: VJson {
        let domain = VJson.object()
        domain["Name"] &= name
        domain["IncludeWww"] &= wwwIncluded
        domain["Root"] &= root
        domain["ForewardUrl"] &= forwardUrl
        domain["Enabled"] &= enabled
        domain["AccessLogEnabled"] &= accessLogEnabled
        domain["404LogEnabled"] &= four04LogEnabled
        domain["SessionLogEnabled"] &= sessionLogEnabled
        domain["SfResources"] &= sfresources
        domain["Telemetry"] &= telemetry.json
        domain["SupportDirectory"] &= supportDirectory.path
        domain["SessionTimeout"] &= sessionTimeout
        domain["ServiceNames"] &= VJson(serviceNames)
        domain["StatisticsRolloverTime"] &= statisticsRolloverTime.description
        domain["VisitsPerStatisticsFile"] &= visitsPerStatisticsFile
        domain["NofRecentRequestLogs"] &= nofRecentRequestLogs
        domain["NofRecentResponseLogs"] &= nofRecentResponseLogs
        return domain
    }
    
    
    /// Create a new domain object.
    ///
    /// - Parameters
    ///   - name: The name for the domain
    ///   - root: The root directory for this domain.
    
    public init?(name: String, root: URL) {
        self._name = name
        self.supportDirectory = root
        if sessionLogDir == nil { return nil }
        self.sessions = Sessions(logDirUrl: sessionLogDir!)
        if accountsDir == nil { return nil }
        self.accounts = Accounts(root: accountsDir!)
        self.statistics = VisitorStatistics(directory: statisticsDir, timeForDailyLogRestart: WallclockTime.init(hour: 0, minute: 0, second: 0), maxRowCount: 10)
    }
    
    
    /// Recreate a domain object from a VJson hierarchy
    ///
    /// - Parameter json: The VJson hierarchy from which to recreate this object.
    
    public convenience init?(json: VJson?) {
        
        guard let json = json else { return nil }

        
        // Create a default object
        
        let jsupDir = (json|"SupportDirectory")?.stringValue
        guard let jname = (json|"Name")?.stringValue else { return nil }

        if jsupDir != nil, !jsupDir!.isEmpty {
            let jsupDirUrl = URL(fileURLWithPath: jsupDir!, isDirectory: true)
            self.init(name: jname, root: jsupDirUrl)
        } else {
            return nil
        }

        
        // Initialize the properties that must be present
        
        guard let jroot   = (json|"Root")?.stringValue else { return nil }
        guard let jfurl   = (json|"ForewardUrl")?.stringValue else { return nil }
        guard let jwww    = (json|"IncludeWww")?.boolValue else { return nil }
        guard let jenab   = (json|"Enabled")?.boolValue else { return nil }
        guard let jacc    = (json|"AccessLogEnabled")?.boolValue else { return nil }
        guard let jfour   = (json|"404LogEnabled")?.boolValue else { return nil }
        guard let jservicesNames = json|"ServiceNames" else { return nil }
        
        
        // Upgrade
        
        if (json|"SfResources")?.stringValue == nil { json["SfResources"] &= sfresources }
        let jsfresources = (json|"SfResources")!.stringValue!

        if (json|"SessionTimeout")?.intValue == nil { json["SessionTimeout"] &= sessionTimeout }
        let jsessiontimeout = (json|"SessionTimeout")!.intValue!
        
        if (json|"SessionLogEnabled")?.boolValue == nil { json["SessionLogEnabled"] &= sessionLogEnabled }
        let jsessionlogenabled = (json|"SessionLogEnabled")!.boolValue!
        
        if (json|"StatisticsRolloverTime")?.string == nil { json["StatisticsRolloverTime"] &= statisticsRolloverTime.description }
        let jstatisticsRolloverTime = (json|"StatisticsRolloverTime")!.string!
        
        if (json|"VisitsPerStatisticsFile")?.intValue == nil { json["VisitsPerStatisticsFile"] &= visitsPerStatisticsFile }
        let jvisitsPerStatisticsFile = (json|"VisitsPerStatisticsFile")!.intValue!
        
        if (json|"NofRecentRequestLogs")?.intValue == nil { json["NofRecentRequestLogs"] &= nofRecentRequestLogs }
        let jnofRecentRequestLogs = (json|"NofRecentRequestLogs")!.intValue!

        if (json|"NofRecentResponseLogs")?.intValue == nil { json["NofRecentResponseLogs"] &= nofRecentResponseLogs }
        let jnofRecentResponseLogs = (json|"NofRecentResponseLogs")!.intValue!

        
        // Setup
        
        self.name = jname
        self.root = jroot
        self.forwardUrl = jfurl
        self.wwwIncluded = jwww
        self.enabled = jenab
        self.accessLogEnabled = jacc
        self.four04LogEnabled = jfour
        self.sessionLogEnabled = jsessionlogenabled
        self.sfresources = jsfresources
        self.sessionTimeout = jsessiontimeout
        self.statisticsRolloverTime = WallclockTime(jstatisticsRolloverTime) ?? WallclockTime(hour: 0, minute: 0, second: 0)
        self.visitsPerStatisticsFile = jvisitsPerStatisticsFile
        self.nofRecentResponseLogs = jnofRecentResponseLogs
        self.nofRecentRequestLogs = jnofRecentRequestLogs

        
        // Initialize the properties that may be present

        if let jtelemetry = DomainTelemetry(json: (json|"Telemetry")) { self.telemetry = jtelemetry }
        if let url = blacklistedClientsUrl {
            switch blacklist.restore(fromFile: url) {
            case .error: return nil
            case .success: break
            }
        }
        
        
        // Add the service names
        
        for jserviceName in jservicesNames {
            guard let name = jserviceName.stringValue else { return nil }
            serviceNames.append(name)
        }

        
        // Setup the loggers if they are enabled
        
        if let loggingDir = loggingDir {
            if accessLogEnabled { accessLog = AccessLog(logDir: loggingDir) }
            if four04LogEnabled { four04Log = Four04Log(logDir: loggingDir) }
            if sessionLogEnabled { sessions.logDirUrl = sessionLogDir }
        }

        
        // Add the staistics logger
        
        self.statistics = VisitorStatistics(directory: statisticsDir, timeForDailyLogRestart: WallclockTime.init(hour: 0, minute: 0, second: 0), maxRowCount: 10)

    }
    
    
    /// Save the contents of the blacklist to file.
    
    public func saveBlacklist() -> Result<Bool> {
        if let url = blacklistedClientsUrl {
            return blacklist.save(toFile: url)
        }
        return .error(message: "No blacklisted clients URL found")
    }
    
    
    /// Return a new SSL context with the private key/certificate combination for the domain
    
    public var ctx: Result<ServerCtx> {
        
        guard let sslDir = sslDir else { return .error(message: "No sll directory found for domain: \(name)") }
        
        
        // Get all files in the ssl directory
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: sslDir, includingPropertiesForKeys: [.isReadableKey], options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants, .skipsHiddenFiles]) else { return .error(message: "Directory \(sslDir.path) is empty (no cert or key file found)") }
        
        
        // Filter for PEM files
        
        let pemFiles = files.compactMap({ $0.pathExtension.compare("pem", options: [.caseInsensitive], range: nil, locale: nil) == ComparisonResult.orderedSame ? $0 : nil })
        
        if pemFiles.count == 0 { return .error(message: "No pem files found in \(sslDir.path)") }
        
        
        // Filter for files containing 'cert'
        
        let certFiles = pemFiles.compactMap({ $0.lastPathComponent.contains("cert") ? $0 : nil })
        
        if certFiles.count != 1 { return .error(message: "No certificate file found in \(sslDir.path) (filename should contain the lowercase characters 'cert'") }
        
        
        // Filter for files containing 'key'
        
        let keyFiles = pemFiles.compactMap({ $0.lastPathComponent.contains("key") ? $0 : nil })
        
        if keyFiles.count != 1 { return .error(message: "No (private) key file found in \(sslDir.path) (filename should contain the lowercase characters 'key'") }
        
        
        // Create a context
        
        guard let ctx = ServerCtx() else { return .error(message: "Context creation failed for domain: \(name)") }
        
        
        // Add the certificate and (private) key
        
        switch ctx.useCertificate(file: EncodedFile(path: certFiles[0].path, encoding: .pem)) {
        case .error(let message): return .error(message: "\(message) for domain: \(name)")
        case .success: break
        }
        
        switch ctx.usePrivateKey(file: EncodedFile(path: keyFiles[0].path, encoding: .pem)) {
        case .error(let message): return .error(message: "\(message) for domain: \(name)")
        case .success: break
        }
        
        switch ctx.checkPrivateKey() {
        case .error: return .error(message: "Certificate and private key are incompatible for domain: \(name)")
        case .success: break
        }
        
        return .success(ctx)
    }
    
    
    /// Restore the contents of the blacklist from file.
    
    public func restoreBlacklist() -> Result<Bool> {
        if let url = blacklistedClientsUrl {
            return blacklist.restore(fromFile: url)
        }
        return .error(message: "No blacklisted clients URL found")
    }
    
    
    /// Prepares for application (server) shutdown

    public func serverShutdown() -> Result<Bool> {
        let result = saveBlacklist()
        accessLog?.close()
        four04Log?.close()
        statistics?.close()
        return result
    }
    
    
    /// Part of the domain content in a readable form
    
    public var description: String {
        var str = "Domain: \(name)\n"
        str += "--------------------------------------------\n"
        str += " Include 'www'              = \(wwwIncluded)\n"
        str += " Root directory             = \(root)\n"
        str += " Enabled                    = \(enabled)\n"
        str += " Forward to                 = \(forwardUrl)\n"
        str += " Enable Access Log          = \(accessLogEnabled)\n"
        str += " Enable 404 Log             = \(four04LogEnabled)\n"
        str += " Enable Session Log         = \(sessionLogEnabled)\n"
        str += " Session Timeout            = \(sessionTimeout)\n"
        str += " Swiftfire resources        = \(sfresources)\n"
        str += " VisitsPerStatisticsFile    = \(visitsPerStatisticsFile)\n"
        str += " StatisticsFileRolloverTime = \(statisticsRolloverTime)\n"
        str += " nofRecentRequestLogged     = \(nofRecentRequestLogs)\n"
        str += " nofRecentResponseLogged    = \(nofRecentResponseLogs)\n"
        if serviceNames.count == 0 {
            str += "\nDomain Service Names:\n None\n"
        } else {
            str += "\nDomain Service Names:\n"
            serviceNames.forEach() { str += " service name = \($0)\n" }
        }
        str += "\nDomain Telemetry:\n"
        str += telemetry.description
        str += "\n\nDomain Blacklist:\n"
        str += blacklist.description
        return str
    }
    
    
    /// Update the item with the given name from the given string.
    
    public func update(item: String, to value: String) {
        
        switch item {
            
        case "Name":
            name = value
            
        case "IncludeWww":
            if let b = Bool.init(lettersOrDigits: value) {
                wwwIncluded = b
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to bool",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }
            
        case "Root":
            root = value
            
        case "ForewardUrl":
            forwardUrl = value
            
        case "Enabled":
            if let b = Bool.init(lettersOrDigits: value) {
                enabled = b
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to bool",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }
            
        case "AccessLogEnabled":
            if let b = Bool.init(lettersOrDigits: value) {
                accessLogEnabled = b
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to bool",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }
            
        case "404LogEnabled":
            if let b = Bool.init(lettersOrDigits: value) {
                four04LogEnabled = b
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to bool",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }

        case "SessionLogEnabled":
            if let b = Bool.init(lettersOrDigits: value) {
                sessionLogEnabled = b
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to bool",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }
            
        case "SfResources":
            sfresources = value
            
        case "SupportDirectory":
            supportDirectory = URL(fileURLWithPath: value)
            
        case "SessionTimeout":
            if let i = Int(value) {
                sessionTimeout = i
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to Int",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }
            
        case "StatisticsRolloverTime":
            if let t = WallclockTime(value) {
                statisticsRolloverTime = t
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to WallclockTime",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }

        case "VisitsPerStatisticsFile":
            if let i = Int(value) {
                visitsPerStatisticsFile = i
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to Int",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }
            
        case "NofRecentRequestLogs":
            if let i = Int(value) {
                nofRecentRequestLogs = i
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to Int",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }

        case "NofRecentResponseLogs":
            if let i = Int(value) {
                nofRecentResponseLogs = i
            } else {
                Log.atError?.log(
                    "Cannot convert: \(value) to Int",
                    from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
                )
            }

        default: Log.atError?.log(
            "Unknown item name: \(item)",
            from: Source(id: -1, file: #file, type: "Domain", function: #function, line: #line)
            )
        }
    }
    
    
    /// Returns the custom error message for the given http response code if there is one.
    ///
    /// - Parameter for: The error code for which to return the custom error message.
    
    func customErrorResponse(for code: Response.Code) -> Data? {
        
        do {
            let url = URL(fileURLWithPath: sfresources).appendingPathComponent(code.rawValue.replacingOccurrences(of: " ", with: "_")).appendingPathExtension("html")
            let reply = try Data(contentsOf: url)
            return reply
        } catch {
            return nil
        }
    }
    
    
    /// Removes service names that are not in the available domain services
    
    func removeUnknownServices() {
        
        for (index, serviceName) in serviceNames.enumerated().reversed() {
            if Swiftfire.services.registered[serviceName] == nil {
                serviceNames.remove(at: index)
            }
        }
    }
    
    
    /// Rebuild the services member from the serviceNames and the available services (the later is a member of domainServices)
    
    func rebuildServices() {
        
        services = []
        for serviceName in serviceNames {
            if let service = Swiftfire.services.registered[serviceName] {
                services.append(service)
            }
        }
    }
    
    
    /// Update the visitor statistics
    
    func recordStatistics(_ visit: Visit) {
//        statistics?.append(visit)
    }
}


