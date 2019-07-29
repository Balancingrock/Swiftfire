// =====================================================================================================================
//
//  File:       Domains.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import VJson
import SecureSockets
import BRUtils


/// The class that manages all domains.

public final class Domains {
    
    
    /// The managed domains
    
    var domains: Dictionary<String, Domain> = [:]
    
    
    /// Create a new Domains object.
    
    public init() {}
}


// MARK: - Operational

extension Domains {

    
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
    
    public func contains(domainWithName name: String) -> Bool {
        return domain(forName: name) != nil
    }

    
    /// Returns the requested domain if present.
    ///
    /// A domain is present if the name occurs as is, or if the name occurs with the 'www' prefix when the 'wwwIncluded' option is set.
    ///
    /// - Parameter forName: The name of the requested domain.
    ///
    /// - Returns: Either the requested domain or nil.
    
    public func domain(forName name: String?) -> Domain? {
        
        guard let name = name else { return nil }
        
        let lname = name.lowercased()
        
        for (_, d) in domains {
            if d.name == lname { return d }
            if d.wwwIncluded {
                if lname == "www." + d.name { return d }
            }
        }
        
        return nil
    }
    
    
    /// Adds the given domain as a new domain. Adds self as the name changed listener.
    ///
    /// - Parameter domain: The domain to be added.
    ///
    /// - Returns: True if the domain was added, false if there was already a domain with that name.
    
    @discardableResult
    public func add(domain: Domain) -> Bool {
        
        if contains(domainWithName: domain.name) { return false }
        
        domains[domain.name.lowercased()] = domain
                
        return true
    }
    
    
    /// Removes the given domain from the managed domains.
    ///
    /// - Parameter domainWithName: The name of the domain to be removed. Note that this must match the domain name exactly, the "wwwIncluded" property will not be tested.
    ///
    /// - Returns: True if the domain was found and removed, false if not.
    
    @discardableResult
    public func remove(domainWithName name: String) -> Bool {
        
        let lname = name.lowercased()

        return domains.removeValue(forKey: lname) != nil
    }
    
    
    /// Invokes serverShutdown on each domain.
    
    public func serverShutdown() -> Result<Bool> {
        return domains.reduce(Result<Bool>.success(true)) { $0 + $1.value.serverShutdown() }
    }
    
    
    /// Called from a domain when its name was changed
    
    public func domainNameChanged(from oldName: String, to newName: String) {
        if let d = domains.removeValue(forKey: oldName) {
            domains[newName] = d
        }
    }
    
    
    /// Reset the telemetry of all domains to their default values.
    
    public func resetTelemetry() {
        domains.forEach(){ $0.value.telemetry.reset() }
    }
}


// MARK: - Support for the generator and sequence protocol

extension Domains: Sequence {
    
    
    public struct DomainGenerator: IteratorProtocol {
        
        public typealias Element = Domain
        
        // The object for which the generator generates
        private let source: Domains
        
        // The objects already delivered through the generator
        private var sent: Array<Domain> = []
        
        public init(source: Domains) {
            self.source = source
        }
        
        // The GeneratorType protocol
        public mutating func next() -> Element? {
            
            // Only when the source has values to deliver
            if source.domains.values.count > 0 {
                
                let values = source.domains.values
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


// MARK: - VJsonConvertible

extension Domains: VJsonConvertible {

    public var json: VJson {
        let json = VJson()
        domains.forEach({ json[$0.key] &= $0.value.json })
        return json
    }
    
    public convenience init?(json: VJson?) {
        guard let json = json else { return nil }
        self.init()
        for jdomain in json {
            guard let domain = Domain(json: jdomain, manager: self) else { return nil }
            self.add(domain: domain)
        }
    }
}


// MARK: - Storage

extension Domains {
    
    /// Saves the settings of the domains to file.
    ///
    /// - Parameter toFile: The file to which to save the domains
    ///
    /// - Returns: Either .success(true) or .error(message: String)
    
    @discardableResult
    public func save(toFile url: URL) -> Result<Bool> {
        
        let json = VJson()
        json["Domains"] &= self.json
        if let errorMsg = json.save(to: url) {
            return .error(message: "Could not write domains-defaults to file, error: \(errorMsg)")
        } else {
            return .success(true)
        }
    }

    /// Deserialize from JSON file
    ///
    /// - Parameter file: The URL of the file to deserialize.
    
    public convenience init?(file url: URL) {
        guard let json = ((try? VJson.parse(file: url)) as VJson??) else { return nil }
        self.init(json: json|"Domains")
    }
    
    
    /// Restore a list of domains from the given file.
    ///
    /// - Parameter fromFile: The file from which to restore the domains
    ///
    /// - Returns: .success(message) if the operation was successful, .error(message) otherwise.
    
    @discardableResult
    public func restore(fromFile url: URL) -> Result<String> {
        
        
        // Only if the domain-defaults file exists
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .success("No domains-defaults file available, starting without any domains")
        }
        
        
        // Read domains from file
        
        guard let newDomains = Domains(file: url) else {
            do {
                _ = try VJson.parse(file: url)
                return .error(message: " Could not reconstruct domains from file: \(url.path)")
            } catch let error as VJson.Exception {
                return .error(message: error.description)
            } catch {
                return .error(message: "Could not read or locate file: \(url.path)")
            }
        }
        
        
        // Update all domains
        
        domains = [:]
        for domain in newDomains {
            domains[domain.name] = domain
        }
        //update(withDomains: newDomains)
        
        return .success("Domains successfully restored from \(url.path)")
    }

}


// MARK: - CustomStringConvertible

extension Domains: CustomStringConvertible {
    
    public var description: String {
        if self.count == 0 {
            return "Domains: No domains defined"
        } else {
            return self.reduce("Domains:\n\n") { $0 + $1.description }
        }
    }
}
