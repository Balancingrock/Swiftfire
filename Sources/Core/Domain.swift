// =====================================================================================================================
//
//  File:       Domain.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Replaced var with let due to Xcode 11
//       #8 Fixed storing of all changes to the service names
//       - Added default "Anon" account
//       - Added general purpose cache
// 1.2.0 - Added admin keyword
//       - Set session timeout to 600 (seconds)
// 1.1.0 #3 Fixed loading & storing of domain service names
//       #6 Fixed setting, load & store of phpPath
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import VJson
import SwifterLog
import SecureSockets
import BRUtils
import Http
import BRBON
import KeyedCache


/// Represents an internet domain.

public final class Domain {
    

    /// The domain name plus extension.
    ///
    /// - Note: The name will always be all-lowercase, even when set using uppercase letters.
    
    public let name: String
    
    
    /// The root folder for website for this domain.
    
    public var webroot: String = "/Library/WebServer/Documents"
    
    
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
                
            let strs = value.components(separatedBy: ":")
                
                
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
    
    private(set) var forwardHost: Http.Host?
    
    
    /// Can be used to (temporary) disable a domain without destroying all associated settings, logfiles, data etc.
    
    public var enabled: Bool = false
    
    
    /// Enables the access log when set to true
    
    public var accessLogEnabled: Bool {
        set {
            guard accessLog.enabled != newValue else { return }
            if !newValue { accessLog.close() }
            accessLog.enabled = newValue
        }
        get {
            return accessLog.enabled
        }
    }
    
    
    /// Enables the 404 log when set to true
    
    public var four04LogEnabled: Bool {
        set {
            guard four04Log.enabled != newValue else { return }
            if !newValue { four04Log.close() }
            four04Log.enabled = newValue
        }
        get {
            return four04Log?.enabled ?? false
        }
    }
    
    
    /// Enables the session log when set to true
    
    public var sessionLogEnabled: Bool {
        set { sessions.loggingEnabled = newValue }
        get { return sessions.loggingEnabled }
    }
    
    
    /// Enable PHP by setting the path to a PHP interpreter
    
    public var phpPath: URL?
    
    
    /// Set the options to be passed to the PHP interpreter
    
    public var phpOptions: String?
    
    
    /// When true, a request for index.htm(l) will be mapped to index.php if there is no index.htm(l)
    
    public var phpMapIndex: Bool = true
    
    
    /// When true, any request for a *.htm(l) file will be mapped to *.php if there is no *.htm(l)
    
    public var phpMapAll: Bool = false
    
    
    /// The timeout for a PHP interpreter run in milli seconds
    
    public var phpTimeout: Int = 10000 // 10 seconds, php can be quite slow!
    
    
    /// The session timeout in seconds. A value of <= 0 means that no sessions will be created.
    ///
    /// - Note: Sessions are necessary for domain setup by the domain admin. When the domain admin sets the session to 0 it is no longer possible to use the domain admin account. (But it can still be done by a server adminstrator)
    
    public var sessionTimeout: Int = 600
    
    
    /// Access to the comments
    
    public private(set) var comments: CommentManager!
    
    
    /// The minimum threshold for an account to have its comments published with review by a moderator
    ///
    /// I.e: Once an account has this many approaved comment, further comments do not need approval
    
    public var autoCommentApprovalThreshold: Int32 = 5
    

    /// The domain specific blacklist
    
    public var blacklist = Blacklist()
    
    
    /// The names of the services used by this domain.
    
    public var serviceNames: Array<String> = [] {
        didSet {
            serviceNames.store(to: Urls.domainServiceNamesFile(for: name))
            rebuildServices()
        }
    }
    
    
    /// The services used by this domain.
    ///
    /// The sequence of the services is given by their place in the array, services start at index'first.
    ///
    /// - Note: The user has to ensure that the values are current and synchronised with serviceNames.

    public var services: Array<Services.Entry> = []
    
    
    /// The domain telemetry
    
    public var telemetry: DomainTelemetry = DomainTelemetry()
    
    
    /// The visitor statistics database
    
    private var statistics: VisitorStatistics!
    
    
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
    

    // The access log
    
    public var accessLog: AccessLog!


    // The 404 log

    public var four04Log: Four04Log!
    
    
    /// The sessions for this domain
    
    public var sessions: SessionManager!

    
    /// The accounts associated withthis domain
    
    public var accounts: AccountManager!
    
    
    /// A list of account names to be verified
    
    public var accountNamesWaitingForVerification: ItemManager!
    
    
    /// A list of account names waiting for a new password
    
    public var accountsWaitingForNewPassword: Array<Account> = [] {
        
        didSet {
            
            // Take the opportunity to remove expired entries
            let now = Date().unixTime
            while let account = accountsWaitingForNewPassword.first {
                if account.newPasswordRequestTimestamp + 24 * 60 * 60 < now {
                    accountsWaitingForNewPassword.removeFirst()
                    account.newPasswordRequestTimestamp = 0
                    //account.newPasswordVerificationCode = "" // Do not do this as it would reduce flexibility of the domain admin on the account details page
                } else {
                    break
                }
            }
            
            // Prevent out-of-memory attacks
            while accountsWaitingForNewPassword.count > 100 {
                _ = accountsWaitingForNewPassword.removeFirst()
            }
        }
    }
    
    
    // Counter for hits on pages (note that not all pages will be counted, only for those pages for which a hitcounter is requested)
    // This set of counters is maintained by the function_NofPageHits
    
    public var hitCounters: HitCounters = HitCounters()
    
    
    /// A general purpose cache
    
    public var cache: MemoryCache<String, Data> = MemoryCache(limitStrategy: LimitStrategy.bySize(1_000_000), purgeStrategy: PurgeStrategy.leastUsed)
    
    
    /// The directory for the certificate files.
    
    private lazy var sslDir: URL? = { Urls.domainSslDir(for: name) }()

    
    /// The directory used when processing PHP files.
    
    lazy var phpDir: URL? = { Urls.domainPhpDir(for: name) }()
    
    
    /// This keyword is used to access the setup default webpage
    ///
    /// Access the setup page like: http://domain-name.domain-extension/<setupKeyword>
    ///
    /// The setupKeyword is used by Service.domainSetup. To permanently disable this, remove this service form the service stack for this domain. Alternatively change the default value to something more cryptic to increase the site's security through obfuscation.
    
    public var setupKeyword: String? = "setup"
    
    
    /// Create a new domain object.
    ///
    /// - Parameters
    ///   - name: The name for the domain.
    
    public init?(_ name: String) {
        
        
        // Internally only lowercased names are used.
        
        self.name = name.lowercased()
        
        
        // Make sure the domain directory exists
        
        guard Urls.domainDir(for: self.name) != nil else { return nil }
        

        // Reload the service names
        
        if !self.serviceNames.load(from: Urls.domainServiceNamesFile(for: self.name)) {
            Log.atNotice?.log("Service names not found or failed to load for domain \(name), using default")
            self.serviceNames = defaultServices
            self.serviceNames.store(to: Urls.domainServiceNamesFile(for: self.name))
        }

        
        // Create the sessions object
        
        self.sessions = SessionManager(loggingDirectory: Urls.domainSessionLogDir(for: self.name))
        guard sessions != nil else {
            Log.atEmergency?.log("Could not create sessions object for domain \(self.name)")
            return nil
        }
        self.sessions.loggingEnabled = sessionLogEnabled
        
        
        // Create the accounts object
        
        self.accounts = AccountManager(directory: Urls.domainAccountsDir(for: self.name))
        guard accounts != nil else {
            Log.atEmergency?.log("Could not create account manager for domain \(self.name)")
            return nil
        }
        if accounts.getAccountWithoutPassword(for: "Anon") == nil {
            let anon = accounts.newAccount(name: "Anon", password: "Anon")
            anon?.isEnabled = false
        }

        
        // Create the 404 log
        
        self.four04Log = Four04Log(logDir: Urls.domainFour04LogDir(for: self.name))
        guard four04Log != nil else {
            Log.atEmergency?.log("Could not create 404 log for domain \(self.name)")
            return nil
        }
        self.four04Log.enabled = four04LogEnabled

        
        // Create the access log
        
        self.accessLog = AccessLog(logDir: Urls.domainAccessLogDir(for: self.name))
        guard accessLog != nil else {
            Log.atEmergency?.log("Could not create access log for domain \(self.name)")
            return nil
        }
        self.accessLog.enabled = accessLogEnabled

        
        // Restore the blacklist
        
        self.blacklist.load(from: Urls.domainBlacklistFile(for: self.name))

        
        // Create the statistics object
        
        self.statistics = VisitorStatistics(directory: Urls.domainStatisticsDir(for: self.name), timeForDailyLogRestart: WallclockTime.init(hour: 0, minute: 0, second: 0), maxRowCount: 10)
        guard statistics != nil else {
            Log.atEmergency?.log("Could not create statistics object for domain \(self.name)")
            return nil
        }
        
        
        // Access to the comments of this domain
        
        self.comments = CommentManager(self)
        
        
        // Load the setup information
        
        loadSetup()
    }
    
    
    /// Read the setup information from file
    
    public func loadSetup() {
    
        guard let setupFile = Urls.domainSetupFile(for: name) else {
            Log.atError?.log("Failed to create directory for domain setup file, domain = \(name)")
            return
        }
    
        guard let json = try? VJson.parse(file: setupFile) else { return }
        
        if let j = (json|"Root")?.stringValue { webroot = j }
        if let j = (json|"ForewardUrl")?.stringValue { forwardUrl = j }
        if let j = (json|"Enabled")?.boolValue { enabled = j }
        if let j = (json|"AccessLogEnabled")?.boolValue { accessLogEnabled = j }
        if let j = (json|"SessionLogEnabled")?.boolValue { sessionLogEnabled = j }
        
        if let j = (json|"PhpPath")?.stringValue {
            if !j.isEmpty {
                phpPath = URL(fileURLWithPath: j)
            } else {
                phpPath = nil
            }
        }
        
        if let j = (json|"PhpOptions")?.stringValue { phpOptions = j }
        if let j = (json|"PhpMapIndex")?.boolValue { phpMapIndex = j }
        if let j = (json|"PhpMapAll")?.boolValue { phpMapAll = j }
        if let j = (json|"PhpTimeout")?.intValue { phpTimeout = j }
        if let j = (json|"SfResources")?.stringValue { sfresources = j }
        if let j = (json|"SessionTimeout")?.intValue { sessionTimeout = j }
        if let j = (json|"VisitsPerStatisticsFile")?.intValue { visitsPerStatisticsFile = j }
        if let j = (json|"NofRecentRequestLogs")?.intValue { nofRecentRequestLogs = j }
        if let j = (json|"NofRecentResponseLogs")?.intValue { nofRecentResponseLogs = j }
        if let j = (json|"StatisticsRolloverTime")?.stringValue {
            statisticsRolloverTime = WallclockTime(j) ?? WallclockTime(hour: 0, minute: 0, second: 0)
        }
        
        if let url = Urls.domainAccountNamesWaitingForVerificationFile(for: name) {
            accountNamesWaitingForVerification = ItemManager(from: url)
            if accountNamesWaitingForVerification == nil {
                accountNamesWaitingForVerification = ItemManager.createArrayManager(values: Array<String>())
            }
        } else {
            Log.atCritical?.log("Failed to retrieve name for accountNamesWaitingForVerification")
            accountNamesWaitingForVerification = ItemManager.createArrayManager(values: Array<String>())
        }
    }
    
    
    /// Prepares for application (server) shutdown
    
    public func shutdown() {
        
        
        // Save collected data
        
        blacklist.store(to: Urls.domainBlacklistFile(for: name))
        hitCounters.store(to: timestampedFileUrl(dir: Urls.domainHitCountersDir(for: name), name: "hitcounters", ext: "json"))
        telemetry.store(to: timestampedFileUrl(dir: Urls.domainTelemetryDir(for: name), name: "telemetry", ext: "json"))
        accessLog?.close()
        four04Log?.close()
        statistics?.close()
        
        
        // Store the setup information
        
        storeSetup()
    }
    
    
    /// Store the setup information in the setup file
    
    public func storeSetup() {
        
        guard let setupFile = Urls.domainSetupFile(for: name) else {
            Log.atError?.log("Failed to create directory for domain setup file, domain = \(name)")
            return
        }

        
        // Save domain setup
        
        let json = VJson.object()
        json["Root"] &= webroot
        json["SfResources"] &= sfresources
        json["ForewardUrl"] &= forwardUrl
        json["Enabled"] &= enabled
        json["AccessLogEnabled"] &= accessLogEnabled
        json["404LogEnabled"] &= four04LogEnabled
        json["SessionLogEnabled"] &= sessionLogEnabled
        json["PhpPath"] &= phpPath?.path ?? ""
        json["PhpOptions"] &= phpOptions ?? ""
        json["PhpMapIndex"] &= phpMapIndex
        json["PhpMapAll"] &= phpMapAll
        json["PhpTimeout"] &= phpTimeout
        json["SessionTimeout"] &= sessionTimeout
        json["StatisticsRolloverTime"] &= statisticsRolloverTime.description
        json["VisitsPerStatisticsFile"] &= visitsPerStatisticsFile
        json["NofRecentRequestLogs"] &= nofRecentRequestLogs
        json["NofRecentResponseLogs"] &= nofRecentResponseLogs

        json.save(to: setupFile)
        
        if let url = Urls.domainAccountNamesWaitingForVerificationFile(for: name) {
            if accountNamesWaitingForVerification != nil {
                try? accountNamesWaitingForVerification.data.write(to: url)
            }
        }
    }
}


// MARK: - Operational

extension Domain {
    
    
    /// Return a new SSL context with the private key/certificate combination for the domain
    
    var ctx: BRUtils.Result<ServerCtx> {
        
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
    
    
    /// Update the domain parameter with the given name from the given string.
    
    public func update(item: String, to value: String) {
        
        switch item {
            
        case "Root":
            webroot = value
            
        case "ForewardUrl":
            forwardUrl = value
            
        case "Enabled":
            if let b = Bool.init(lettersOrDigits: value) {
                enabled = b
            } else {
                Log.atError?.log("Cannot convert: \(value) to bool")
            }
            
        case "AccessLogEnabled":
            if let b = Bool.init(lettersOrDigits: value) {
                accessLogEnabled = b
            } else {
                Log.atError?.log("Cannot convert: \(value) to bool")
            }
            
        case "404LogEnabled":
            if let b = Bool.init(lettersOrDigits: value) {
                four04LogEnabled = b
            } else {
                Log.atError?.log("Cannot convert: \(value) to bool")
            }

        case "SessionLogEnabled":
            if let b = Bool.init(lettersOrDigits: value) {
                sessionLogEnabled = b
            } else {
                Log.atError?.log("Cannot convert: \(value) to bool")
            }
            
        case "PhpPath":
            if FileManager.default.isExecutableFile(atPath: value) {
                if !value.isEmpty {
                    phpPath = URL(fileURLWithPath: value)
                } else {
                    phpPath = nil
                }
            }
            
        case "PhpOptions":
            phpOptions = value
            
        case "PhpMapIndex":
            if let b = Bool.init(lettersOrDigits: value) {
                phpMapIndex = b
            } else {
                Log.atError?.log("Cannot convert: \(value) to bool")
            }
            
        case "PhpMapAll":
            if let b = Bool.init(lettersOrDigits: value) {
                phpMapAll = b
            } else {
                Log.atError?.log("Cannot convert: \(value) to bool")
            }
            
        case "PhpTimeout":
            if let i = Int(value) {
                phpTimeout = i
            } else {
                Log.atError?.log("Cannot convert: \(value) to int")
            }
            
        case "SfResources":
            sfresources = value
                        
        case "SessionTimeout":
            if let i = Int(value) {
                sessionTimeout = i
            } else {
                Log.atError?.log("Cannot convert: \(value) to Int")
            }
            
        case "StatisticsRolloverTime":
            if let t = WallclockTime(value) {
                statisticsRolloverTime = t
            } else {
                Log.atError?.log("Cannot convert: \(value) to WallclockTime")
            }

        case "VisitsPerStatisticsFile":
            if let i = Int(value) {
                visitsPerStatisticsFile = i
            } else {
                Log.atError?.log("Cannot convert: \(value) to Int")
            }
            
        case "NofRecentRequestLogs":
            if let i = Int(value) {
                nofRecentRequestLogs = i
            } else {
                Log.atError?.log("Cannot convert: \(value) to Int")
            }

        case "NofRecentResponseLogs":
            if let i = Int(value) {
                nofRecentResponseLogs = i
            } else {
                Log.atError?.log("Cannot convert: \(value) to Int")
            }

        default: Log.atError?.log("Unknown item name: \(item)")
        }
    }
    
    
    /// Returns the custom error message for the given http response code if there is one.
    ///
    /// - Parameter for: The error code for which to return the custom error message.
    
    public func customErrorResponse(for code: Response.Code) -> Data? {
        
        do {
            let url = URL(fileURLWithPath: sfresources).appendingPathComponent(code.rawValue.replacingOccurrences(of: " ", with: "_")).appendingPathExtension("html")
            let reply = try Data(contentsOf: url)
            return reply
        } catch {
            return nil
        }
    }
    
    
    /// Removes service names that are not in the available domain services
    
    public func removeUnknownServices() {
        
        for (index, serviceName) in serviceNames.enumerated().reversed() {
            if Core.services.registered[serviceName] == nil {
                serviceNames.remove(at: index)
            }
        }
    }
    
    
    /// Rebuild the services member from the serviceNames and the available services (the later is a member of domainServices)
    
    public func rebuildServices() {
        
        services = []
        for serviceName in serviceNames {
            if let service = Core.services.registered[serviceName] {
                services.append(service)
            }
        }
    }
    
    
    /// Update the visitor statistics
    
    public func recordStatistics(_ visit: Visit) {
        statistics?.append(visit)
    }
}


// MARK: - CustomStringConvertible

extension Domain: CustomStringConvertible {
    
    
    public var description: String {
        var str = "Domain: \(name)\n"
        str += "--------------------------------------------\n"
        str += " Root directory             = \(webroot)\n"
        str += " Enabled                    = \(enabled)\n"
        str += " Forward to                 = \(forwardUrl)\n"
        str += " Enable Access Log          = \(accessLogEnabled)\n"
        str += " Enable 404 Log             = \(four04LogEnabled)\n"
        str += " Enable Session Log         = \(sessionLogEnabled)\n"
        str += " Session Timeout            = \(sessionTimeout)\n"
        str += " PHP Path                   = \(phpPath?.path ?? "Not Set")\n"
        str += " PHP Options                = \(phpOptions ?? "")\n"
        str += " PHP Map Index              = \(phpMapIndex)\n"
        str += " PHP Map All                = \(phpMapAll)\n"
        str += " PHP Timeout                = \(phpTimeout)\n"
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
}
