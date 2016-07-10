// =====================================================================================================================
//
//  File:       CDCounter.swift
//  Project:    Swiftfire
//
//  Version:    0.9.11
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
// v0.9.11 - Initial release
// =====================================================================================================================

import Foundation
import CoreData


private let COUNT = "C"
private let END_DATE = "E"
private let INSTANCE_ID = "I"
private let START_DATE = "S"
private let NEXT = "N"


class CDCounter: NSManagedObject {

    // MARK: - Create unique int identifier
    
    private static var queue = dispatch_queue_create("nl.balancingrock.swiftfire.cdcounter", DISPATCH_QUEUE_SERIAL)

    private static var instanceCounter: Int64 = {
        let c = NSCalendar.currentCalendar().components(NSCalendarUnit(arrayLiteral: .Year, .Month, .Day, .Hour, .Minute, .Second), fromDate: NSDate())
        let now = 1_000_000 + (c.second + 60 * (c.minute + 60 * (c.hour + 24 * (c.day + 31 * (c.month + 12 * c.year)))))
        return Int64(now)
    }()
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        dispatch_sync(CDCounter.queue, { [unowned self] in
            self.instanceId = CDCounter.instanceCounter
            CDCounter.instanceCounter += 1
        })
    }
    
    
    // MARK: - Convert to/from JSON
    
    var json: VJson {
        let json = VJson()
        json[COUNT] &= count
        json[START_DATE] &= startDate
        json[END_DATE] &= endDate
        json[INSTANCE_ID] &= instanceId
        if let jnext = next?.json {
            json.add(jnext, forName: NEXT)
        } else {
            json[NEXT].nullValue = true
        }
        return json
    }
    
    static func createFrom(json: VJson, inContext context: NSManagedObjectContext) -> CDCounter? {
        
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Json code = \(json)")
        
        guard let jcount = (json|COUNT)?.integerValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'count' item in json code")
            return nil
        }
        
        guard let jstartdate = (json|START_DATE)?.doubleValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'start date' item in json code")
            return nil
        }

        guard let jenddate = (json|END_DATE)?.doubleValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'end date' item in json code")
            return nil
        }

        guard let jinstanceid = (json|INSTANCE_ID)?.integerValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'instance id' item in json code")
            return nil
        }

        let new = NSEntityDescription.insertNewObjectForEntityForName("CDCounter", inManagedObjectContext: context) as! CDCounter
        
        // The creation in the line above has also given a value to count, this must be overwritten with the value fom the json code
        new.count = Int64(jcount)
        
        new.startDate = jstartdate
        new.endDate = jenddate
        new.instanceId = Int64(jinstanceid)
        
        if let jnext = json|NEXT where !jnext.isNull {
            if let ncounter = CDCounter.createFrom(jnext, inContext: context) {
                ncounter.previous = new
            } else {
                context.deleteObject(new)
                return nil
            }
        }
        return new
    }
}
