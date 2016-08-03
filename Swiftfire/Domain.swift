// =====================================================================================================================
//
//  File:       Domain.swift
//  Project:    Swiftfire
//
//  Version:    0.9.13
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.11 - Removed domain statistis.
//         - Updated for VJson 0.9.8
// v0.9.10 - Added domain statistics.
// v0.9.8  - Fixed bug that would prevent the creation of accessLog and four04Log
// v0.9.7  - Added logging options for Access and 404
// v0.9.6  - Header update
//         - Changed init(json) to accept initializations without telemetry
// v0.9.4  - Accomodated new VJson testing
//         - Made _name private
// v0.9.3  - Added domain telemetry
//         - Corrected description of forwardUrlItemTitle
// v0.9.2  - Removed 'final' from the class definition
//         - Added enableHttpPreprocessor, enableHttpPostprocessor, httpWorkerPreprocessor and httpWorkerPostprocessor
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation


func == (lhs: Domain, rhs: Domain) -> Bool {
    if lhs.name as String != rhs.name as String { return false }
    if lhs.wwwIncluded.boolValue != rhs.wwwIncluded.boolValue { return false }
    if lhs.root as String != rhs.root as String { return false }
    if lhs.forwardUrl as String != rhs.forwardUrl as String { return false }
    if lhs.enabled.boolValue != rhs.enabled.boolValue { return false }
    return true
}


protocol DomainNameChangeListener {
    func domainNameChanged(from: String, to: String)
}


class Domain: Equatable, ReflectedStringConvertible {
    
    // These are used for the item identifiers and the titles of the items in the outline view, therefore they cannot be static. (Each item displayed must have a unique id = "AnyObject"))
    
    let nameItemTitle: NSString = "Domain"
    let wwwIncludedItemTitle: NSString = "Also map 'www' prefix:"
    let rootItemTitle: NSString = "Root folder:"
    let forwardUrlItemTitle: NSString = "Foreward to (Domain:Port):"
    let enabledItemTitle: NSString = "Enable Domain:"
    let enableAccessLoggingItemTitle: NSString = "Enable Access Logging:"
    let enable404LoggingItemTitle: NSString = "Enable 404 Logging:"

    static let nofContainedItems: Int = 6 // Minus 1 for the domain name


    /// The domain name plus extension. Only use the 'www' prefix if you want to differentiate between two domains, one with and one without the 'www'.
    /// - Note: The name will always be all-lowercase, even when set using uppercase letters.
    
    var name: String {
        set {
            if _name != newValue.lowercased() {
    
                // Update the _name
                let oldValue = _name
                self._name = newValue.lowercased()
                
                // Set the new support dir url for this domain
                if let appSupportDir = FileURLs.appSupportDir {
                    do {
                        self.supportDir = try appSupportDir.appendingPathComponent(name, isDirectory: true)
                    } catch {
                        self.supportDir = nil
                    }
                } else {
                    self.supportDir = nil
                }

                // If the access log is in use, close it and create a new one if necessary
                if accessLogEnabled {
                    accessLogEnabled = false
                    accessLogEnabled = true // false -> true change creates a new logfile
                }
                
                // If the 404 log is in use, close it and create a new one
                if four04LogEnabled {
                    four04LogEnabled = false
                    four04LogEnabled = true // false -> true change creates a new logfile
                }
                
                //
                if let changeListener = nameChangeListener {
                    changeListener.domainNameChanged(from: oldValue, to: newValue)
                }
            }
        }
        get {
            return self._name
        }
    }
    private var _name: String = "domain.toplevel"
    
    
    /// If the domain should map both the name with 'www' and without it to the same root, set this value to 'true'
    
    var wwwIncluded: Bool = true
    
    
    /// The root folder for this domain.
    
    var root: String = "/Library/Server/Web/Data/Sites/MyGreatSite"
    
    
    /// If this is non-empty, the domain will be rerouted to this host. The HTTP header host field will remain unchanged. Even when re-routed to another port. The host must be identified as an <address>:<port> combination where either address or port is optional.
    /// Example: domain = "mysite.com", forewardUrl = "yoursite.org" results in rerouting all "mysite.com" requests to "yoursite.org"
    /// Example: domain = "mysite.com", forewardUrl = ":6777" results in rerouting all "mysite.com" requests to "mysite.com:6777"
    /// Example: domain = "mysite.com", forewardUrl = "yoursite.org:6777" results in rerouting all "mysite.com" requests to "yoursite.org:6777"

    var forwardUrl: String  {
        
        get {
            guard let newHost = forwardHost else { return "" }
            return newHost.description
        }
        
        set {
            
            if newValue.isEmpty { _forwardHost = nil ; return }
            
            let value = newValue.trimmingCharacters(in: NSCharacterSet.whitespaces)
            
            if value.isEmpty { _forwardHost = nil ; return }
                
            
            // Split at ':' character
                
            var strs = value.components(separatedBy: ":")
                
                
            // If there is one item, then there is no ':' in the string, the new value is then the address
                
            if strs.count == 1 { _forwardHost = Host(address: value, port: nil) ; return }
                
            
            // The first item is the address, the second is the port.
            // Note: both may still be empty at this point

            if strs.count == 2 {
                
                let rawAddress = strs[0].trimmingCharacters(in: NSCharacterSet.whitespaces)
                let address = rawAddress.isEmpty ? "localhost" : rawAddress
                
                let rawPort = strs[1].trimmingCharacters(in: NSCharacterSet.whitespaces)
                let port: String? = rawPort.isEmpty ? nil : rawPort
                
                _forwardHost = Host(address: address, port: port)
                
            } else {
                
                // This is an error
                
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "ForewardURL (\(newValue)) should contain 1 ':' character")
                
                _forwardHost = nil
            }
        }
    }
    
    var forwardHost: Host? { return _forwardHost }
    private var _forwardHost: Host?
    
    
    /// Can be used to (temporary) disable a domain without destroying all associated settings, logfiles, data etc.
    
    var enabled: Bool = false
    
    
    /// Enables the access log when set to true
    
    var accessLogEnabled: Bool = false {
        didSet {
            // Exit if nothing changed
            guard accessLogEnabled != oldValue else { return }
            
            if accessLogEnabled {
                if accessLog == nil {
                    guard let appSupportDir = FileURLs.appSupportDir else { return }
                    do {
                        let domainDir = try appSupportDir.appendingPathComponent(name, isDirectory: true)
                        let logDir = try domainDir.appendingPathComponent("logging", isDirectory: true)
                        accessLog = AccessLog(logDir: logDir)
                    } catch {
                        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not create directory URL")
                    }
                } else {
                    log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "\(name) accessLog unexpected nil")
                }
            } else {
                if accessLog != nil { accessLog!.close(); accessLog = nil }
            }
        }
    }
    
    
    /// Enables the 404 log when set to true
    
    var four04LogEnabled: Bool = false {
        didSet {
            // Exit if nothing changed
            guard four04LogEnabled != oldValue else { return }
            
            if four04LogEnabled {
                if four04Log == nil {
                    guard let appSupportDir = FileURLs.appSupportDir else { return }
                    do {
                        let domainDir = try appSupportDir.appendingPathComponent(name, isDirectory: true)
                        let logDir = try domainDir.appendingPathComponent("logging", isDirectory: true)
                        four04Log = Four04Log(logDir: logDir)
                    } catch {
                        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not create directory URL")
                    }
                } else {
                    log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "\(name) four04Log unexpected nil")
                }
            } else {
                if four04Log != nil { four04Log!.close(); four04Log = nil }
            }
        }
    }
    
    

    /// Callback in case of name changed
    
    var nameChangeListener: DomainNameChangeListener?
    
    
    /// Enables a http pre-processor
    
    var enableHttpPreprocessor = false
    
    
    /// Enables the http post-processor
    
    var enableHttpPostprocessor = false
    
    
    /// The domain telemetry
    
    var telemetry = DomainTelemetry()
    
    
    // The access log & 404 log
    
    var accessLog: AccessLog?
    var four04Log: Four04Log?
    
    
    // The application support directory for this domain
    
    lazy var supportDir: URL? = {
        guard let appSupportDir = FileURLs.appSupportDir else { return nil }
        do {
            let url = try appSupportDir.appendingPathComponent(self.name, isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Could not create domain directory for \(self.name)")
            return nil
        }
    }()
    
    lazy var loggingDir: URL? = {
        guard let domainSupportDir = self.supportDir else { return nil }
        do {
            let url = try domainSupportDir.appendingPathComponent("logging", isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Could not create domain logging directory for \(self.name)")
            return nil
        }
    }()
    
    
    /// The JSON representation for this object
    
    var json: VJson {
        let domain = VJson.object("Domain")
        domain["Name"] &= name
        domain["IncludeWww"] &= wwwIncluded
        domain["Root"] &= root
        domain["ForewardUrl"] &= forwardUrl
        domain["Enabled"] &= enabled
        domain["AccessLogEnabled"] &= accessLogEnabled
        domain["404LogEnabled"] &= four04LogEnabled
        domain.add(telemetry.json(id: "Telemetry"))
        return domain
    }
    
    
    // Used in the resource availability test
    
    enum ResourceAvailability {
        case Available
        case NotAvailable
        case AccessNotAllowed
    }

    
    // Allow the no-parameter init
    
    init() {}
    
    
    // Provide the JSON reconstruction init
    
    init?(json: VJson?) {
        
        // Initialize the properties that must be present
        
        guard let json = json else { return nil }
                
        guard let jname = (json|"Name")?.stringValue else { return nil }
        guard let jroot = (json|"Root")?.stringValue else { return nil }
        guard let jfurl = (json|"ForewardUrl")?.stringValue else { return nil }
        guard let jwww  = (json|"IncludeWww")?.boolValue else { return nil }
        guard let jenab = (json|"Enabled")?.boolValue else { return nil }
        guard let jacc  = (json|"AccessLogEnabled")?.boolValue else { return nil }
        guard let jfour = (json|"404LogEnabled")?.boolValue else { return nil }
        
        self.name = jname
        self.root = jroot
        self.forwardUrl = jfurl
        self.wwwIncluded = jwww
        self.enabled = jenab
        self.accessLogEnabled = jacc
        self.four04LogEnabled = jfour

        
        // Initialize the properties that may be present

        if let jtelemetry = DomainTelemetry(json: (json|"Telemetry")) { self.telemetry = jtelemetry }
        
        
        // Setup the loggers if they are enabled
        
        if let loggingDir = loggingDir {
            if accessLogEnabled { accessLog = AccessLog(logDir: loggingDir) }
            if four04LogEnabled { four04Log = Four04Log(logDir: loggingDir) }
        }
    }
    
    
    /// Creates a copy of the object and returns that.
    
    var copy: Domain {
        let new = Domain()
        new.name = self.name
        new.wwwIncluded = self.wwwIncluded
        new.root = self.root
        new.forwardUrl = self.forwardUrl
        new.enabled = self.enabled
        new.telemetry = self.telemetry.duplicate
        new.accessLogEnabled = self.accessLogEnabled
        new.four04LogEnabled = self.four04LogEnabled
        return new
    }
    
    
    /// Update the content of this domain with the contents of the new domain.
    
    @discardableResult
    func update(withDomain new: Domain) -> Bool {
        
        let newName = new.name.lowercased()
        
        var changed = false
        
        if name != newName {
            name = newName
            changed = true
        }
        
        if root != new.root {
            root = new.root
            changed = true
        }
        
        if enabled != new.enabled {
            enabled = new.enabled
            changed = true
        }
        
        if wwwIncluded != new.wwwIncluded {
            wwwIncluded = new.wwwIncluded
            changed = true
        }
        
        if forwardUrl != new.forwardUrl  {
            forwardUrl = new.forwardUrl
            changed = true
        }
        
        if telemetry != new.telemetry {
            telemetry = new.telemetry.duplicate
            changed = true
        }
        
        if accessLogEnabled != new.accessLogEnabled {
            accessLogEnabled = new.accessLogEnabled
            changed = true
        }
        
        if four04LogEnabled != new.four04LogEnabled {
            four04LogEnabled = new.four04LogEnabled
            changed = true
        }
        
        return changed
    }
    
    
    /**
     If the property "enableHttpPreprocessor" is set to true, then this function will be called. The return value must be a valid HTTP Response or nil. If a non-nil is returned the content of the returned buffer will be provided as the response for the request. If a non-nil is returned the default httpWorker will NOT be called. Also the postprocessor will NOT be called if a non-nil is returned. Hence the preprocessor must implement updating of telemetry and the maintenance of logs.
     
     - Note: The preprocessor is responsible for error detection and creation, including updating of log's if appropriate.
    
     - Parameter header: The HTTP header as reqeived from the client.
     - Parameter body: The HTTP body as received from the client, may have length zero.
     - Parameter connection: The active connection for this request.
     - Parameter mutation: The mutation that will be recorded in the statistics database. The operation should only update the httpResponseCode and responseDetails.
    
     - Returns: Either nil, or a valid HTTP response.
     */
    
    func httpWorkerPreprocessor(header: HttpHeader, body: Data, connection: HttpConnection, mutation: Mutation) -> Data? {
        return nil
    }
    
    
    /**
     If the property "enableHttpPostprocessor" is set to true and the httpWorkerPreprocessor (if called) returned a nil, then this operation will be called after the default implementation prepared the response. The return value must be a valid HTTP Response or nil. If a non-nil is returned the content of the returned buffer will be provided as the response for the request instead of the result from the default httpWorker.

     - Parameter header: The HTTP header as reqeived from the client.
     - Parameter body: The HTTP body as received from the client, may have length zero.
     - Parameter response: The response as prepared by the (default) httpWorker, note that this might be an error reply.
     - Parameter connection: The active connection for this request.
     - Parameter mutation: The mutation that will be recorded in the statistics database. The operation should only update the httpResponseCode and responseDetails.

     - Returns: Either nil, or a valid HTTP response.
     */
    
    func httpWorkerPostprocessor(header: HttpHeader, body: Data, response: Data, connection: HttpConnection, mutation: Mutation) -> Data? {
        return nil
    }
}


// MARK: - NSOutlineView support

extension Domain {
    
    func itemForIndex(index: Int) -> AnyObject? {
        switch index {
        case 0: return wwwIncludedItemTitle
        case 1: return enabledItemTitle
        case 2: return rootItemTitle
        case 3: return forwardUrlItemTitle
        case 4: return enableAccessLoggingItemTitle
        case 5: return enable404LoggingItemTitle
        default: return nil
        }
    }
    
    func titleForItem(item: AnyObject?) -> NSString? {
        if item === self { return name as NSString }
        if item === wwwIncludedItemTitle { return wwwIncludedItemTitle }
        if item === enabledItemTitle { return enabledItemTitle }
        if item === rootItemTitle { return rootItemTitle }
        if item === forwardUrlItemTitle { return forwardUrlItemTitle }
        if item === enableAccessLoggingItemTitle { return enableAccessLoggingItemTitle }
        if item === enable404LoggingItemTitle { return enable404LoggingItemTitle }
        return nil
    }
    
    func valueForItem(item: AnyObject?) -> NSString? {
        if item === self { return name as NSString }
        if item === wwwIncludedItemTitle { return wwwIncluded.description as NSString }
        if item === enabledItemTitle { return enabled.description as NSString }
        if item === rootItemTitle { return root as NSString }
        if item === forwardUrlItemTitle { return (forwardUrl.isEmpty ? "-" : forwardUrl) as NSString }
        if item === enableAccessLoggingItemTitle { return accessLogEnabled.description as NSString }
        if item === enable404LoggingItemTitle { return four04LogEnabled.description as NSString }
        return nil
    }
    
    func itemIsEditable(item: AnyObject?, inNameColumn: Bool) -> Bool? {
        if inNameColumn {
            if item === self { return true }
            if item === wwwIncludedItemTitle { return false }
            if item === enabledItemTitle { return false }
            if item === rootItemTitle { return false }
            if item === forwardUrlItemTitle { return false }
            if item === enableAccessLoggingItemTitle { return false }
            if item === enable404LoggingItemTitle { return false }
        } else {
            // Must be value column
            if item === self { return false }
            if item === wwwIncludedItemTitle { return true }
            if item === enabledItemTitle { return true }
            if item === rootItemTitle { return true }
            if item === forwardUrlItemTitle { return true }
            if item === enableAccessLoggingItemTitle { return true }
            if item === enable404LoggingItemTitle { return true }
        }
        return nil
    }
    
    func updateItem(item: AnyObject?, withValue value: AnyObject?) -> (itemMatch: Bool, errorMessage: String?) {
        
        guard let strValue = value as? String else {
            return (true, "Could not convert \(value) to a valid String")
        }
        
        if item === self {
            name = strValue
            return (true, nil)
        }
        
        if item === wwwIncludedItemTitle {
            if let bValue = Bool(strValue) {
                wwwIncluded = bValue
                return (true, nil)
            } else {
                return (true, "Could not convert \(strValue) to a valid Bool")
            }
        }
        
        if item === enabledItemTitle {
            if let bValue = Bool(strValue) {
                enabled = bValue
                return (true, nil)
            } else {
                return (true, "Could not convert \(strValue) to a valid Bool")
            }
        }
        
        if item === rootItemTitle {
            root = strValue
            return (true, nil)
        }
        
        if item === forwardUrlItemTitle {
            forwardUrl = strValue
            return (true, nil)
        }
        
        if item === enableAccessLoggingItemTitle {
            if let bValue = Bool(strValue) {
                accessLogEnabled = bValue
                return (true, nil)
            } else {
                return (true, "Could not convert \(strValue) to a valid Bool")
            }
        }
        
        if item === enable404LoggingItemTitle {
            if let bValue = Bool(strValue) {
                four04LogEnabled = bValue
                return (true, nil)
            } else {
                return (true, "Could not convert \(strValue) to a valid Bool")
            }
        }
        
        return (false, nil)
    }
}
