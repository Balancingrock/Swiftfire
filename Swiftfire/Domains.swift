// =====================================================================================================================
//
//  File:       Domains.swift
//  Project:    Swiftfire
//
//  Version:    0.9.6
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// v0.9.6 - Header update
//        - Changed 'save' to exclude telemetry
// v0.9.3 - Changed input parameters of domainForName to optional
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation

final class Domains: DomainNameChangeListener, SequenceType {
    
    
    // The managed domains
    
    private var domains: Dictionary<String, Domain> = [:]
    
    
    /// The number of domains
    
    var count: Int { return domains.count }
    
    
    /**
     - Returns: True if the given domain name is contained explicitly (domain.name) or implicitly ("www." and domain.name if wwwIncluded is true) in the managed domains.
     - Note: If a domain is disabled, it will not be examined for a match.
     */
     
    func contains(domainName: String) -> Bool {
        return domainForName(domainName) != nil
    }

    
    /**
     - Returns: The domain for the given name. Nil if none can be found.
     - Note: The "wwwIncluded" property is also evaluated.
     */
    
    func domainForName(name: String?) -> Domain? {
        
        guard let name = name else { return nil }
        
        let lname = name.lowercaseString
        
        for (_, d) in domains {
            if d.name == lname { return d }
            if d.wwwIncluded.boolValue {
                if lname == "www." + d.name { return d }
            }
        }
        
        return nil
    }
    
    
    /**
     - Returns: The enabled domain for the given name. Nil if none can be found.
     - Note: The "wwwIncluded" property is also evaluated.
     */
    
    func enabledDomainForName(name: String) -> Domain? {
        
        let d = domainForName(name)
        
        if let f = d?.enabled where f == true { return d }
        
        return nil
    }

    
    /**
     Adds the given domain as a new domain. Adds self as the name change listener, overwriting a previous value if there was one.
     
     - Parameter domain: The domain to be added.
     
     - Returns: True if the domain was added, false if there was already a domain with that name.
     */
    
    func add(domain: Domain) -> Bool {
        
        if contains(domain.name) { return false }
        
        domains[domain.name.lowercaseString] = domain
        domain.nameChangeListener = self
        
        return true
    }
    
    
    /**
     Removes the given domain from the managed domains.
    
     - Parameter name: The name of the domain to be removed. Note that this must match the domain name exactly, the "wwwIncluded" property will not be tested.
    
     - Return True if the domain was found and removed, false if not.
     */
    
    func remove(name: String) -> Bool {
        
        let lname = name.lowercaseString

        if domains[lname] != nil {
            domains.removeValueForKey(lname)
            return true
        } else {
            return false
        }
    }
    
    
    /**
     Update the contents for the domain with the given name with the values from the given domain.
     
     - Parameter name: The name of the domain to be updated.
     
     - Returns: True if the update was successful, false if nothing was changed or the domain for the given name did not exist.
     */
    
    func update(name: String, withDomain new: Domain) -> Bool {
        
        let oldName = name.lowercaseString
        
        for (n, d) in domains {
            if n == oldName {
                return d.updateWith(new)
            }
            if d.wwwIncluded {
                if ("www." + n) == oldName {
                    return d.updateWith(new)
                }
            }
        }
        
        return false
    }
    
    
    /**
     This will merge the changes from the new set of domains into this domains set.
     When names are identical, it will update the properties of the local domains to those of the new domains. If there are more domains in the new set than in the domains of this set, then the new domains will be added. If this domain contains one or more domains that are not in the new set, they will be removed, unless there are remaining domains in the new set that have no corresponding domain in this set. Then the domains in this set will be updated to the remaining domains in the new set.
     
     - Note: The most common example is when the number of domains is equal, but the new set has one domain that is not in the old set. This means that the name of the domain has changed, and the not-covered domain in the old set will be renamed to the domain name of the new set. (Any changed properties will also be updated.
     */
     
    func updateWithDomains(updateDomains: Domains) {
        
        // These keep references to domains that have not yet been processed
        
        var oldDomains = self.domains.valuesAsArray()
        var newDomains = updateDomains.domains.valuesAsArray()
        
        
        // First match (domain)names and update the older with the newer if a match is found
        
        for nd in updateDomains {
            
            for od in self {
                
                if od.name == nd.name {
                    
                    oldDomains.removeObject(od)
                    newDomains.removeObject(nd)
                    
                    od.updateWith(nd)
                }
            }
        }
        
        
        // If there unprocessed domains, try matching based on the root directory
        
        OLD_LOOP: while oldDomains.count > 0 {
            
            let od = oldDomains.removeFirst()
            
            if newDomains.count == 0 { self.remove(od.name); continue }
            
            if newDomains.count > 0 {
                
                // Match new domain to old ones
                
                for nd in newDomains {
                    if nd.root == od.root {
                        od.updateWith(nd)
                        newDomains.removeObject(nd)
                        continue OLD_LOOP
                    }
                }
                
                let nnd = newDomains.removeFirst()
                
                // Match old domains to new ones
                
                for ood in newDomains {
                    if nnd.root == ood.root {
                        ood.updateWith(nnd)
                        oldDomains.removeObject(ood)
                        continue OLD_LOOP
                    }
                }

                // Match any old domain to any new domain
                
                od.updateWith(nnd)
            }
        }

        
        // If there are new domains left, then add them to the existing domains
        
        while newDomains.count > 0 {
            let nd = newDomains.removeFirst()
            self.domains[nd.name.lowercaseString] = nd
        }
    }
    
    
    // MARK: - Support for the generator and sequence protocol
    
    struct DomainGenerator: GeneratorType {
        
        typealias Element = Domain
        
        // The object for which the generator generates
        let source: Domains
        
        // The objects already delivered through the generator
        var sent: Array<Domain> = []
        
        init(source: Domains) {
            self.source = source
        }
        
        // The GeneratorType protocol
        mutating func next() -> Element? {
            
            // Only when the source has values to deliver
            if source.domains.values.count > 0 {
                
                let values = source.domains.values
                let sortedValues = values.sort({$0.name < $1.name})
                
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
    
    typealias Generator = DomainGenerator
    
    func generate() -> Generator {
        return DomainGenerator(source: self)
    }
    
    
    // MARK: - DomainNameChangedListener protocol
    
    func domainNameChanged(from: String, to: String) {
        if let d = domains.removeValueForKey(from) {
            domains[to] = d
        }
    }
    
    
    // MARK: - Save & Restore
    
    func restore() -> Bool {
        
        
        // Only if the domain-defaults file exists
        
        guard FileURLs.exists(FileURLs.domainDefaults) else {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "No domains-defaults file available, starting without domains")
            return true
        }
        
        
        // Read the JSON code from the file and construct a hierarchy from it.
        
        if let file = FileURLs.domainDefaults {
            
            let json: VJson
            
            do {
                
                json = try VJson.createJsonHierarchy(file)
                
                for j in json["Domains"] {
                    if let d = Domain(json: j["Domain"]) {
                        self.add(d)
                    } else {
                        log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Error reading domain from domains-default file.")
                    }
                }
                
                
                // Log all domains that were read
                
                for d in self {
                    log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: d.description)
                }

                return true

            } catch let error as VJson.Exception {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Could not retrieve JSON code from domains-defaults file. Error = \(error).")
                return false
                
            } catch {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Could not retrieve JSON code from domains-defaults file. Unspecified error.")
                return false
            }
            
            
        } else {
            
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "No domains-defaults file URL available")
            return false
        }
    }
    
    func save() {
        
        if let file = FileURLs.domainDefaults {
            
            let json = VJson.createJsonHierarchy()
            
            for (i, d) in self.enumerate() {
                
                let jd = d.json
                jd.removeChildWithName("Telemetry")
                json["Domains"][i] = jd
            }
            
            if let errorMsg = json.save(file) {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not write domains-defaults to file, error: \(errorMsg)")
            }
            
        } else {
            
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "No domains-defaults file URL available")
        }
    }
}