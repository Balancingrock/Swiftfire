// =====================================================================================================================
//
//  File:       CDPathPart+CoreDataClass.swift
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
// v0.9.14 - Split Console and Swiftfire targets
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Added manipulation of doNotTrace
//         - Changed CDCounter startDate to Int64 (javaDate)
//         - Added "fullUrl" and "showChart"
// v0.9.11 - Initial release
// =====================================================================================================================

import Foundation
import CoreData

private let DO_NOT_TRACE = "T"
private let PATH_PART = "P"
private let FOREVER_COUNT = "F"
private let COUNTER = "C"
private let NEXT = "N"

class CDPathPart: NSManagedObject {
    
    var json: VJson {
        let json = VJson()
        json[DO_NOT_TRACE] &= doNotTrace
        json[PATH_PART] &= pathPart
        json[FOREVER_COUNT] &= Int(foreverCount)
        if let arr = json.add(VJson.array(NEXT)) {
            for pp in next?.allObjects as! [CDPathPart] {
                arr.append(pp.json)
            }
        } else {
            log.atLevelError(id: -1, source:#file.source(#function, #line), message: "Could not create ARRAY for JSON item")
        }
        json.add(counterList?.json, forName: COUNTER)
        return json
    }
    
    static func createFrom(json: VJson, inContext context: NSManagedObjectContext) -> CDPathPart? {
        
        guard let jdonottrace = (json|DO_NOT_TRACE)?.boolValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'do not trace' item in json code")
            return nil
        }
        guard let jforevercount = (json|FOREVER_COUNT)?.int64Value else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'forever count' item in json code")
            return nil
        }
        guard let jcounter = json|COUNTER else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'counter' item in json code")
            return nil
        }
        guard json|PATH_PART != nil else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'path part' item in json code")
            return nil
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: "CDPathPart", into: context) as! CDPathPart
        
        new.doNotTrace = jdonottrace
        new.foreverCount = jforevercount
        new.pathPart = (json|PATH_PART)?.stringValue
        
        if let jparts = json|NEXT {
            for jpart in jparts {
                if let pp = CDPathPart.createFrom(json: jpart, inContext: context) {
                    pp.previous = new
                } else {
                    context.delete(new)
                    return nil
                }
            }
        }
        
        if let counter = CDCounter.createFrom(json: jcounter, inContext: context) {
            counter.pathPart = new
        } else {
            context.delete(new)
            return nil
        }
        
        return new
    }
    
    var count: NSNumber?
    
    func recalculateCount(from startDate: Int64, to endDate: Int64) {
        
        var privateCount: Int64 = 0
        
        if let counter = counterList {
            
            if counter.forDay >= startDate && counter.forDay <= endDate  {
                privateCount = counter.count
            }
            
            var whileCounter = counter.next
            while whileCounter != nil {
                if whileCounter!.forDay >= startDate && whileCounter!.forDay <= endDate  {
                    privateCount += whileCounter!.count
                }
                whileCounter = whileCounter!.next
            }
        }
        
        self.setValue(NSNumber(value: privateCount), forKey: "count")
        
        
        // Propagate to sub-parts
        for pp in self.next?.allObjects as! [CDPathPart] {
            pp.recalculateCount(from: startDate, to: endDate)
        }
    }
    
    var _doNotTrace: NSNumber {
        get {
            return NSNumber(value: doNotTrace)
        }
        set {
            updateDoNotTrace(to: newValue.boolValue)
        }
    }
        
    var fullUrl: String {
        var urlstr = self.pathPart!
        var current = self.previous
        while current != nil {
            urlstr = (current!.pathPart! as NSString).appendingPathComponent(urlstr)
            current = current!.previous
        }
        return urlstr
    }
}
