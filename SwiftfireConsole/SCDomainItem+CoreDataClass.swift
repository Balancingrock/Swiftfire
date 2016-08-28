// =====================================================================================================================
//
//  File:       SCDomainItem+CoreDataClass.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.14
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
// v0.9.14 - Initial release
// =====================================================================================================================

import Foundation
import CoreData


public class SCDomainItem: NSManagedObject {

    public override func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKeyPath inKeyPath: String) throws {
        
        func makeDomain(from: SCDomainItem) -> Domain {
            let domain = Domain()
            domain.name = from.name!
            for component in from.child!.allObjects as! [SCDomainItem] {
                switch component.name! {
                case Domain.wwwIncludedItemTitle: domain.wwwIncluded = Bool(component.value!)!
                case Domain.rootItemTitle: domain.root = component.value!
                case Domain.forwardUrlItemTitle: domain.forwardUrl = component.value!
                case Domain.sfresourcesItemTitle: domain.sfresources = component.value!
                case Domain.enabledItemTitle: domain.enabled = Bool(component.value!)!
                case Domain.enable404LoggingItemTitle: domain.four04LogEnabled = Bool(component.value!)!
                case Domain.enableAccessLoggingItemTitle: domain.accessLogEnabled = Bool(component.value!)!
                default: break
                }
            }
            return domain
        }
        
        guard let newValue = ioValue.pointee as? String else {
            throw NSError(domain: "SwiftfireConsole", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create string value"])
        }
        
        if inKeyPath == "name" {
            let newDomain = makeDomain(from: self)
            newDomain.name = newValue
            toSwiftfire?.transfer(UpdateDomainCommand(oldDomainName: self.name!, newDomain: newDomain))
        }
        else if inKeyPath == "value" {
            
            // Validate first
            
            switch self.name {
            case nil: throw NSError(domain: "SwiftfireConsole", code: 0, userInfo: [NSLocalizedDescriptionKey : "Name is not optional"])
            case Domain.nameItemTitle?: throw NSError(domain: "SwiftfireConsole", code: 0, userInfo: [NSLocalizedDescriptionKey : "Should be impossible"])
            case Domain.wwwIncludedItemTitle?, Domain.enabledItemTitle?, Domain.enableAccessLoggingItemTitle?, Domain.enable404LoggingItemTitle?:
                guard Bool(newValue) != nil else {
                    throw NSError(domain: "SwiftfireConsole", code: 0, userInfo: [NSLocalizedDescriptionKey : "Expected bool: '0', '1', 'true', 'false', 'yes' or 'no'"])
                }
            case Domain.rootItemTitle?, Domain.forwardUrlItemTitle?, Domain.sfresourcesItemTitle?: break
            default: throw NSError(domain: "SwiftfireConsole", code: 0, userInfo: [NSLocalizedDescriptionKey : "Name for item not recognized"])
            }
            
            
            // Create old domain
            
            guard let parent = self.parent else {
                throw NSError(domain: "SwiftfireConsole", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not access domain name"])
            }
            
            let newDomain = makeDomain(from: parent)
            switch self.name! {
            case Domain.wwwIncludedItemTitle: newDomain.wwwIncluded = Bool(newValue)!
            case Domain.rootItemTitle: newDomain.root = newValue
            case Domain.forwardUrlItemTitle: newDomain.forwardUrl = newValue
            case Domain.sfresourcesItemTitle: newDomain.sfresources = newValue
            case Domain.enabledItemTitle: newDomain.enabled = Bool(newValue)!
            case Domain.enable404LoggingItemTitle: newDomain.four04LogEnabled = Bool(newValue)!
            case Domain.enableAccessLoggingItemTitle: newDomain.accessLogEnabled = Bool(newValue)!
            default: break
            }
            toSwiftfire?.transfer(UpdateDomainCommand(oldDomainName: parent.name!, newDomain: newDomain))
        }
    }
}
