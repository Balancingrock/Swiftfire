// =====================================================================================================================
//
//  File:       CDClient.swift
//  Project:    Swiftfire
//
//  Version:    0.9.12
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
// v0.9.12 - Added manipulation of doNotTrace
// v0.9.11 - Initial release
// =====================================================================================================================

import Foundation
import CoreData

private let ADDRESS = "A"
private let DO_NOT_TRACE = "D"
private let RECORDS = "S"

class CDClient: NSManagedObject {

    var count: Int { return records?.count ?? 0 }
    
    lazy var firstAccess: Double = {
        let arr = self.records?.allObjects as! [CDClientRecord]
        let sortedArr = arr.sort({ $0.requestReceived < $1.requestReceived })
        if let record = sortedArr.first {
            return record.requestReceived
        } else {
            return 0.0
        }
    }()
    
    lazy var lastAccess: Double = {
        let arr = self.records?.allObjects as! [CDClientRecord]
        let sortedArr = arr.sort({ $0.requestReceived < $1.requestReceived })
        if let record = sortedArr.last {
            return record.requestReceived
        } else {
            return 0.0
        }
    }()
    
    var firstAccessString: String {
        let fd = NSDate(timeIntervalSince1970: firstAccess)
        let dc = NSCalendar.currentCalendar().components(NSCalendarUnit(arrayLiteral: .Year, .Month, .Day, .Hour, .Minute, .Second), fromDate: fd)
        return "\(dc.year)-\(dc.month)-\(dc.day) \(dc.hour):\(dc.minute):\(dc.second)"
    }
    
    var lastAccessString: String {
        let fd = NSDate(timeIntervalSince1970: lastAccess)
        let dc = NSCalendar.currentCalendar().components(NSCalendarUnit(arrayLiteral: .Year, .Month, .Day, .Hour, .Minute, .Second), fromDate: fd)
        return "\(dc.year)-\(dc.month)-\(dc.day) \(dc.hour):\(dc.minute):\(dc.second)"
    }

    var json: VJson {
        let json = VJson()
        json[ADDRESS] &= address
        json[DO_NOT_TRACE] &= doNotTrace
        if let arr = json.add(VJson.array(RECORDS)) {
            for record in records?.allObjects as! [CDClientRecord] {
                arr.append(record.json)
            }
        } else {
            log.atLevelError(id: -1, source:#file.source(#function, #line), message: "Could not create RECORDS component in JSON code")
        }
        return json
    }
    
    static func createFrom(json: VJson, inContext context: NSManagedObjectContext) -> CDClient? {
        
        guard json|ADDRESS != nil else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'address' item in json code")
            return nil
        }

        guard let jdonottrace = (json|DO_NOT_TRACE)?.boolValue else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'do not trace' item in json code")
            return nil
        }

        let new = NSEntityDescription.insertNewObjectForEntityForName("CDClient", inManagedObjectContext: context) as! CDClient
        
        new.address = (json|ADDRESS)?.stringValue
        new.doNotTrace = jdonottrace
        
        if json|RECORDS == nil { return new }
        
        for record in (json|RECORDS)! {
            if let cdClientRecord = CDClientRecord.createFrom(record, inContext: context) {
                cdClientRecord.client = new
            } else {
                context.deleteObject(new)
                return nil
            }
        }
        return new
    }
    
    var _doNotTrace: NSNumber {
        get {
            return NSNumber(bool: doNotTrace)
        }
        set {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "New value for doNotTrace \(newValue), transmitting to Swiftfire")
            
            let command = UpdateClientCommand(client: address!, newValue: newValue.boolValue)
            
            if toSwiftfire != nil {
                toSwiftfire?.transferToSwiftfire(command.json.description)
            } else {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Attempt to set new value for doNotTrace \(newValue), but no transmitter available")
            }
        }
    }
}
