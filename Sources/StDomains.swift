// =====================================================================================================================
//
//  File:       StDomains.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.0
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
// 0.10.0 - Added parameter nilOnDoNotTrace to getPathPart
// 0.9.17 - Header update
// 0.9.15 - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON


/// The top level entry for the URL statistics. The first part of the URL is equal to the domain, hence the name.

public final class StDomains: VJsonConvertible {
    
    
    /// The list of domains that have been accessed.
    
    public var domains: [StPathPart] = []
    
    
    /// The VJson hierarchy that represents this object.
    
    public var json: VJson {
        return VJson(domains)
    }
    
    
    /// Recreates the content of this object from the contents of the VJson hierarchy.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        for jDomain in json {
            guard let domain = StPathPart(json: jDomain) else { return nil }
            self.domains.append(domain)
        }
    }
    
    
    /// Create a new object.
    
    public init() {}
    
    
    /// Returns the domain for the given path part. Creates a new domain if it does noet exist yet.
    
    public func getDomain(for name: String?) -> StPathPart? {
        guard let name = name else { return nil }
        for domain in domains {
            if domain.pathPart == name { return domain }
        }
        let domain = StPathPart(name, previous: nil)
        domains.append(domain)
        return domain
    }
    
    
    /// Returns the path part for the last part of the given full path.
    ///
    /// - Parameters:
    ///   - for fullPath: The path relative to the root of the domain
    ///   - niOnDonNotTrace: When true, a nil will be returned if the doNotTrace flag is set.
    ///
    /// - Returns: The path part as indicated by the fullPath
    ///
    /// Will return nil if any path part along the way has the option doNotTrace set. Will create path parts as necessary.
    
    public func getPathPart(for fullPath: String?, nilOnDoNotTrace: Bool = true) -> StPathPart? {
        
        guard let fullPath = fullPath else { return nil }
        
        // Create an array of path components
        var pathParts = (fullPath as NSString).pathComponents
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the domain for the first path part
        guard let domain = getDomain(for: pathParts[0]) else { return nil }
        
        // The domain is the start of the search
        var pathPart: StPathPart? = domain
        
        // Repeat until all parts have been matched
        while pathParts.count > 0 {
            
            // Matched this part, remove it
            pathParts.remove(at: 0)
            
            // Exit if no more matches must be made
            if pathParts.count == 0 { return pathPart }
            
            // Do next match
            pathPart = pathPart!.getPathPart(for: pathParts[0], nilOnDoNotTrace: nilOnDoNotTrace)
            
            // Exit if there was a do not trace
            if pathPart == nil { return nil }
        }
        
        // This exit should not happen
        fatalError("Unexpected exit for getPathPart(for fullPath)")
    }
}
