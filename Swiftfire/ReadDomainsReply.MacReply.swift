// =====================================================================================================================
//
//  File:       ReadDomainsReply.MacReply.swift
//  Project:    Swiftfire
//
//  Version:    0.9.14
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
import Cocoa

extension ReadDomainsReply: MacReply {
        
    static func factory(json: VJson?) -> MacReply? {
        return ReadDomainsReply(json: json)
    }
        
    func process() {

        // Implementation note: Simply replacing the context content will lead to a degraded user experience.
        
        // Get all domain level items
        
        let request = NSFetchRequest<SCDomainItem>(entityName: "SCDomainItem")
        request.predicate = NSPredicate(format: "(parent == nil) and (isServer == false)")
        var oldDomains = try! consoleData.context.fetch(request)

        
        // Domain items that are not in the local domains must be removed
        
        oldDomains.forEach({
            if !localDomains.contains(domainWithName: $0.name!) {
                consoleData.context.delete($0)
                oldDomains.removeObject(object: $0)
            }
        })
        
        
        // New domains that are in the old domains must be updated
        
        localDomains.forEach({
            (test: Domain) in
            
            if let item = oldDomains.first(where: { $0.name == test.name }) {

                for comp in item.child!.allObjects as! [SCDomainItem] {
                    switch comp.name! {
                    case Domain.wwwIncludedItemTitle: comp.value = test.wwwIncluded.description
                    case Domain.rootItemTitle: comp.value = test.root
                    case Domain.sfresourcesItemTitle: comp.value = test.sfresources
                    case Domain.forwardUrlItemTitle: comp.value = test.forwardUrl
                    case Domain.enabledItemTitle: comp.value = test.enabled.description
                    case Domain.enable404LoggingItemTitle: comp.value = test.four04LogEnabled.description
                    case Domain.enableAccessLoggingItemTitle: comp.value = test.accessLogEnabled.description
                    default: break
                    }
                }
                
                localDomains.remove(domainWithName: test.name)
            }
        })
        
        
        // Any local domain left must be created
        
        localDomains.sorted(by: { $0.name < $1.name }).forEach() {
            
            (domain: Domain) in
            
            let domainItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            domainItem.name = domain.name
            domainItem.value = ""
            domainItem.sequence = 0
            domainItem.nameIsEditable = true
            
            let wwwIncludedItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            wwwIncludedItem.name = Domain.wwwIncludedItemTitle as String
            wwwIncludedItem.value = domain.wwwIncluded.description
            wwwIncludedItem.sequence = 1
            wwwIncludedItem.parent = domainItem
            wwwIncludedItem.valueIsEditable = true
            
            let rootItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            rootItem.name = Domain.rootItemTitle as String
            rootItem.value = domain.root
            rootItem.sequence = 2
            rootItem.parent = domainItem
            rootItem.valueIsEditable = true

            let sfResourcesItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            sfResourcesItem.name = Domain.sfresourcesItemTitle as String
            sfResourcesItem.value = domain.sfresources
            sfResourcesItem.sequence = 3
            sfResourcesItem.parent = domainItem
            sfResourcesItem.valueIsEditable = true

            let forwardUrlItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            forwardUrlItem.name = Domain.forwardUrlItemTitle as String
            forwardUrlItem.value = domain.forwardUrl
            forwardUrlItem.sequence = 4
            forwardUrlItem.parent = domainItem
            forwardUrlItem.valueIsEditable = true

            let enabledItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            enabledItem.name = Domain.enabledItemTitle as String
            enabledItem.value = domain.enabled.description
            enabledItem.sequence = 5
            enabledItem.parent = domainItem
            enabledItem.valueIsEditable = true

            let enableAccessLoggingItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            enableAccessLoggingItem.name = Domain.enableAccessLoggingItemTitle as String
            enableAccessLoggingItem.value = domain.accessLogEnabled.description
            enableAccessLoggingItem.sequence = 6
            enableAccessLoggingItem.parent = domainItem
            enableAccessLoggingItem.valueIsEditable = true

            let enableFour04LoggingItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            enableFour04LoggingItem.name = Domain.enable404LoggingItemTitle as String
            enableFour04LoggingItem.value = domain.four04LogEnabled.description
            enableFour04LoggingItem.sequence = 7
            enableFour04LoggingItem.parent = domainItem
            enableFour04LoggingItem.valueIsEditable = true
            
            let telemetryItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            telemetryItem.name = "Telemetry"
            telemetryItem.value = ""
            telemetryItem.sequence = 8
            telemetryItem.parent = domainItem

            let nofRequestsItem = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nofRequestsItem.name = domain.telemetry.nofRequests.name
            nofRequestsItem.value = domain.telemetry.nofRequests.value.description
            nofRequestsItem.sequence = 9
            nofRequestsItem.parent = telemetryItem

            let nof200Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof200Item.name = domain.telemetry.nof200.name
            nof200Item.value = domain.telemetry.nof200.value.description
            nof200Item.sequence = 10
            nof200Item.parent = telemetryItem

            let nof400Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof400Item.name = domain.telemetry.nof400.name
            nof400Item.value = domain.telemetry.nof400.value.description
            nof400Item.sequence = 11
            nof400Item.parent = telemetryItem

            let nof403Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof403Item.name = domain.telemetry.nof403.name
            nof403Item.value = domain.telemetry.nof403.value.description
            nof403Item.sequence = 12
            nof403Item.parent = telemetryItem

            let nof404Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof404Item.name = domain.telemetry.nof404.name
            nof404Item.value = domain.telemetry.nof404.value.description
            nof404Item.sequence = 13
            nof404Item.parent = telemetryItem

            let nof500Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof500Item.name = domain.telemetry.nof500.name
            nof500Item.value = domain.telemetry.nof500.value.description
            nof500Item.sequence = 14
            nof500Item.parent = telemetryItem

            let nof501Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof501Item.name = domain.telemetry.nof501.name
            nof501Item.value = domain.telemetry.nof501.value.description
            nof501Item.sequence = 15
            nof501Item.parent = telemetryItem

            let nof505Item = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: consoleData.context) as! SCDomainItem
            nof505Item.name = domain.telemetry.nof505.name
            nof505Item.value = domain.telemetry.nof505.value.description
            nof505Item.sequence = 16
            nof505Item.parent = telemetryItem
        }
    }
}
