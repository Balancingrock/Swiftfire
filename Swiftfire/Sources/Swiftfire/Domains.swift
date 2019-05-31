// =====================================================================================================================
//
//  File:       Domains.swift
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
//  Copyright:  (c) 2015-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.11 - Replaced SwifterJSON with VJson
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Reworked updating of domain items
// 0.9.18 - Added ctxs
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks, SwiftfireCore split.
// 0.9.14 - Updated writeToLog
//        - Fixed bug that prevented loading of saved domains
//        - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Added local definition of "domains"
//        - Updated for VJson 0.9.8
// 0.9.7  - Fixed bug where domains were added without using the 'add' function.
// 0.9.6  - Header update
//        - Changed 'save' to exclude telemetry
// 0.9.3  - Changed input parameters of domainForName to optional
// 0.9.0  - Initial release
//
// =====================================================================================================================

import Foundation
import VJson
import SecureSockets
import BRUtils


func + (lhs: Result<Bool>, rhs: Result<Bool>) -> Result<Bool> {
    switch lhs {
    case .error(let lmessage):
        switch rhs {
        case .error(let rmessage): return Result<Bool>.error(message: "\(lmessage)\n\(rmessage)")
        case .success: return Result<Bool>.error(message: lmessage)
        }
    case .success(let lbool):
        switch rhs {
        case .error(let rmessage): return Result<Bool>.error(message: rmessage)
        case .success(let rbool): return Result<Bool>.success(lbool && rbool)
        }
    }
}


/// The class that manages all domains.

public final class Domains: Sequence, CustomStringConvertible {
    
    
    /// Create a new Domains object.
    
    public init() {}
    
    
    /// The managed domains
    
    private var domains: Dictionary<String, Domain> = [:]
    
    
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
        
        NotificationCenter.default.addObserver(forName: Domain.nameChangedNotificationName, object: domain, queue: nil, using: nameChangeListener)
        
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

        if let domain = domains.removeValue(forKey: lname) {
            NotificationCenter.default.removeObserver(self, name: Domain.nameChangedNotificationName, object: domain)
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: - Support for the generator and sequence protocol
    
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
    
    
    /// Returns an itterator for this object.
    
    public func makeIterator() -> DomainGenerator {
        return DomainGenerator(source: self)
    }
    
    
    /// Invokes serverShutdown on each domain.
    
    public func serverShutdown() -> Result<Bool> {
        return domains.reduce(Result<Bool>.success(true)) { $0 + $1.value.serverShutdown() }
    }
    
    
    /// MARK: - NameChanged notification listener
    
    private func nameChangeListener(notification: Notification) {
        guard let oldName = notification.userInfo?["Old"] as? String else {
            return
        }
        guard let newName = notification.userInfo?["New"] as? String else {
            return
        }
        if let d = domains.removeValue(forKey: oldName) {
            domains[newName] = d
        }
    }
    
    
    /// MARK: - Save & Restore
    
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
    
    
    /// Serialize this object to VJson.
    
    public var json: VJson {
        let json = VJson()
        domains.forEach({ json[$0.key] &= $0.value.json })
        return json
    }
    
    
    /// Deserialize from VJson.
    ///
    /// - Parameter json: The VJson hierarchy to deserialize.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        for jdomain in json {
            guard let domain = Domain(json: jdomain) else { return nil }
            self.add(domain: domain)
        }
    }
    
    
    /// Deserialize from JSON file
    ///
    /// - Parameter file: The URL of the file to deserialize.
    
    public convenience init?(file url: URL) {
        guard let json = ((try? VJson.parse(file: url)) as VJson??) else { return nil }
        self.init(json: json|"Domains")
    }
    
    
    /// Reset the telemetry of all domains to their default values.
    
    public func resetTelemetry() {
        domains.forEach(){ $0.value.telemetry.reset() }
    }
    
    
    /// Creates a list of all domains in a readable form
    
    public var description: String {
        if self.count == 0 {
            return "Domains: No domains defined"
        } else {
            return self.reduce("Domains:\n\n") { $0 + $1.description }
        }
    }
}
