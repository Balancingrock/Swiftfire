//
//  ST_Domains.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON


/// The top level entry for the URL statistics. The first part of the URL is equal to the domain, hence the name.

final class ST_Domains: VJsonConvertible {
    
    
    /// The list of domains that have been accessed.
    
    var domains: [ST_PathPart] = []
    
    
    /// The VJson hierarchy that represents this object.
    
    var json: VJson {
        return VJson(domains)
    }
    
    
    /// Recreates the content of this object from the contents of the VJson hierarchy.
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        for jDomain in json {
            guard let domain = ST_PathPart(json: jDomain) else { return nil }
            self.domains.append(domain)
        }
    }
    
    
    /// Create a new object.
    
    init() {}
    
    
    /// Returns the domain for the given path part. Creates a new domain if it does noet exist yet.
    
    func getDomain(for name: String?) -> ST_PathPart? {
        guard let name = name else { return nil }
        for domain in domains {
            if domain.pathPart == name { return domain }
        }
        let domain = ST_PathPart(name)
        domains.append(domain)
        return domain
    }
    
    
    /// Returns the path part for the last part of the given full path. Will return nil if any path part along the way has the option doNotTrace set. Will create path parts as necessary.
    
    func getPathPart(for fullPath: String?) -> ST_PathPart? {
        
        guard let fullPath = fullPath else { return nil }
        
        // Create an array of path components
        guard let url = URL(string: fullPath) else { return nil }
        var pathParts = url.pathComponents
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the domain for the first path part
        guard let domain = getDomain(for: pathParts[0]) else { return nil }
        
        // The domain is the start of the search
        var pathPart: ST_PathPart? = domain
        
        // Repeat until all parts have been matched
        while pathParts.count > 0 {
            
            // Matched this part, remove it
            pathParts.remove(at: 0)
            
            // Exit if no more matches must be made
            if pathParts.count == 0 { return pathPart }
            
            // Do next match
            pathPart = pathPart!.getPathPart(for: pathParts[0])
            
            // Exit if there was a do not trace
            if pathPart == nil { return nil }
        }
        
        // This exit should not happen
        fatalError("Unexpected exit for getPathPart(for fullPath)")
        
        // return pathPart
    }
}
