// =====================================================================================================================
//
//  File:       DomainManager.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2015-2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 #8 Fixed: Added immediate storage of changes to the domains & aliases list
// 1.2.0 - Fixed typo in error message
//       - When loading domains&aliases, now removes domains that have no associated directory.
// 1.1.0 #3 Fixed
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import VJson
import SecureSockets
import BRUtils


/// The class that manages all domains.

public final class DomainManager {
    
    
    /// The managed domains
    
    public var domains: Dictionary<String, Domain> = [:] {
        didSet {
            storeDomainsAndAliases()
        }
    }
    
    
    /// Create a new DomainManager object.
    
    init?() {
        
        // Make sure the domains directory exists
        
        guard Urls.domainsAndAliasesFile != nil else {
            Log.atEmergency?.log("Cannot create or locate domains directory and/or domains & aliases file")
            return nil
        }
        
        _ = loadDomainsAndAliases() // Errors must be ignored during init
    }
    
    
    /// Loads the domains and aliases file.
    ///
    /// - Returns: True if the application can continue, false if not.
    
    private func loadDomainsAndAliases() -> Bool {
        
        
        // Make sure the domains directory exists
        
        guard let url = Urls.domainsAndAliasesFile else {
            Log.atEmergency?.log("Cannot create or locate domains directory and/or domains & aliases file")
            return false
        }
        

        // Check if the domains and aliases file exists
        
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            if isDir.boolValue {
                Log.atEmergency?.log("Domains and aliases file is not a file but a directory \(url.path)")
                return false
            } else {
                Log.atNotice?.log("No domains and aliases file exists at \(url.path)")
                return true
            }
        }

        
        // Check if the file is readable
        
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            Log.atEmergency?.log("Domains and aliases file exists but is not readable at \(url.path)")
            return false
        }
        
        
        // Get the list of domains and aliases
        
        guard let json = try? VJson.parse(file: url) else {
            Log.atEmergency?.log("Error parsing domains and aliases file")
            return false
        }
        
        
        // Create the domains and make entries for the aliases
        
        for item in json {
            
            
            // Get domain name
            
            guard let name = item["domain"].stringValue else {
                Log.atEmergency?.log("Missing value for domain name")
                return false
            }
            
            
            // Get the domain, create it if it does not exist
            
            var domain: Domain? = domains[name]
            if domain == nil {
                
                let domainUrl = Urls.domainsDir!.appendingPathComponent(name)
                
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: domainUrl.path, isDirectory: &isDir) {
                
                    if isDir.boolValue {

                        guard let newDomain = Domain(name) else {
                            Log.atEmergency?.log("Cannot create/load domain with name \(name)")
                            return false
                        }
                        
                        domains[name] = newDomain
                        domain = newDomain
                        
                    } else {
                        Log.atError?.log("No directory for \(name) found")
                    }

                } else {
                    Log.atError?.log("No directory for \(name) found")
                }
            }
            
            
            // Get alias and point it to the domain
            
            if let domain = domain, let alias = item["alias"].stringValue, !alias.isEmpty, alias != name {
                domains[alias] = domain
            }
        }
        
        return true
    }
    
    
    // Save the domains& aliases list as well as the domains to file
    
    public func storeDomainsAndAliases() {
        
        guard let url = Urls.domainsAndAliasesFile else {
            Log.atEmergency?.log("Cannot retrieve domains and aliases file url, domains list not saved")
            return
        }
        
        
        // Create a JSON ARRAY with the domain names and aliases in it and write that to file
        
        let json = VJson.array()
        for (key, value) in domains {
            let item = VJson.object()
            item["alias"] &= key
            item["domain"] &= value.name
            json.append(item)
        }
        
        if let message = json.save(to: url) {
            Log.atError?.log("Could not save the domains and aliases, message = '\(message)'")
        } else {
            Log.atNotice?.log("Saved the domains and aliases to file = '\(url.path)'")
        }
    }
}


// MARK: - Operational

extension DomainManager {

    
    /// The number of domains
    
    public var count: Int { return domains.count }
    
    
    /// Returns a list with server ctx's for the domains
    
    public var ctxs: Array<ServerCtx> {
        
        var arr = [ServerCtx]()
        
        for domain in self {
            switch domain.ctx {
            case .error: break
            case .success(let ctx): arr.append(ctx)
            }
        }
        
        return arr
    }

    /// Checks if the requested domain name is present.
    ///
    /// A domain is present if the name occurs as is, or if the name occurs with the 'www' prefix when the 'wwwIncluded' option is set.
    ///
    /// - Parameter domainWithName: The name of the requested domain.
    ///
    /// - Returns: True if the domain is present, false if it is not present.
    
    public func contains(_ name: String) -> Bool {
        return domains[name] != nil
    }

    
    /// Returns the requested domain if present.
    ///
    /// A domain is present if the name occurs as is, or if the name occurs with the 'www' prefix when the 'wwwIncluded' option is set.
    ///
    /// - Parameter forName: The name of the requested domain.
    ///
    /// - Returns: Either the requested domain or nil.
    
    public func domain(for name: String?) -> Domain? {
        
        guard let name = name else { return nil }
        
        return domains[name.lowercased()]
    }
    
    
    /// Create a domain for the given name and add it to the domains. No action results if the domain already existed.
    ///
    /// - Parameter name: The name for the new domain must be created.
    ///
    /// - Returns: If a domain was created, the new domain is returned. Otherwise nil is returned. I.e. if the domain already existed, a nil will be returned.
    
    public func createDomain(for name: String?) -> Domain? {
        
        guard let name = name else { return nil }
        
        if domains[name.lowercased()] == nil {
            let domain = Domain(name.lowercased())
            domains[name.lowercased()] = domain
            return domain
        } else {
            return nil
        }
    }
    
    
    /// Create an alias for the domain with the given name. If there is no such domain, nothing will be done.
    
    public func createAlias(_ alias: String?, forDomainWithName name: String?) {
    
        guard let alias = alias, let name = name else { return }
        
        if let domain = domains[name.lowercased()] {
            domains[alias.lowercased()] = domain
        }
    }
    
    
    /// Removes the given domain or alias from the managed domains. If a domain is removed, possible aliases will also be removed. If an alias is removed the corresponding domain will be unaffected.
    ///
    /// - Parameter name: The name of the domain to be removed.
    
    public func remove(_ name: String) {
        
        if let domain = domains[name] {
            
            let domainName = domain.name
            
            domains.removeValue(forKey: name)
            
            if name == domainName {
                
                // The domain itself has to be removed, remove all aliases that point to this domain
                
                for key in domains.keys {
                    
                    if domains[key]!.name == name.lowercased() {
                        domains.removeValue(forKey: key)
                    }
                }
            }
        } else {
            Log.atWarning?.log("Could not remove alias or domain with the name \(name)")
        }
    }
    
    
    /// Invokes shutdown on each domain.
    
    public func shutdown() {
        return domains.forEach { $0.value.shutdown() }
    }
}


// MARK: - Support for the generator and sequence protocol

extension DomainManager: Sequence {
    
    
    public struct DomainGenerator: IteratorProtocol {
        
        public typealias Element = Domain
        
        // The object for which the generator generates
        private var source: Dictionary<String, Domain> = [:]
        
        // The objects already delivered through the generator
        private var sent: Array<Domain> = []
        
        public init(source: DomainManager) {
            for domain in source.domains.values {
                self.source[domain.name] = domain
            }
        }
        
        // The GeneratorType protocol
        public mutating func next() -> Element? {
            
            // Only when the source has values to deliver
            if source.values.count > 0 {
                
                let values = source.values
                let sortedValues = values.sorted(by: {$0.name < $1.name})
                
                // Find a value that has not been sent already
                OUTER: for i in sortedValues {
                    
                    // Check if the value has not been sent already
                    for s in sent {
                        
                        // If it was sent, then try the next value
                        if i === s { continue OUTER }
                    }
                    // Found a value that was not sent yet
                    // Remember that it will be sent
                    sent.append(i)
                    
                    // Send it
                    return i
                }
            }
            // Nothing left to send
            return nil
        }
    }
    
    
    public func makeIterator() -> DomainGenerator {
        return DomainGenerator(source: self)
    }
}


// MARK: - CustomStringConvertible

extension DomainManager: CustomStringConvertible {
    
    public var description: String {
        if self.count == 0 {
            return "DomainManager: No domains defined"
        } else {
            return self.reduce("Domains:\n\n") { $0 + $1.description }
        }
    }
}


struct DomainControlBlockIndexableDataSource: ControlBlockIndexableDataSource {
    
    private var domains: Array<Domain> = []
    
    public init(_ domainManager: DomainManager) {
        OUTER: for domain in domainManager.domains.values {
            for d in domains {
                if d.name == domain.name { continue OUTER }
            }
            domains.append(domain)
        }
        domains.sort { $0.name > $1.name }
    }
    
    public var cbCount: Int { return domains.count }
    
    public func addElement(at index: Int, to info: inout Functions.Info) {
        guard index < domains.count else { return }
        domains[index].addSelf(to: &info)
    }
}

struct AliasControlBlockIndexableDataSource: ControlBlockIndexableDataSource {
    
    private var aliases: Array<String> = []
    
    public init(domainManager: DomainManager, domain: Domain) {
        domainManager.domains.forEach { (key, value) in
            if value === domain {
                if key != domain.name {
                    aliases.append(key)
                }
            }
        }
    }

    var cbCount: Int { return aliases.count }
    
    func addElement(at index: Int, to info: inout Functions.Info) {
        guard index < aliases.count else { return }
        info["alias"] = aliases[index]
    }
}
