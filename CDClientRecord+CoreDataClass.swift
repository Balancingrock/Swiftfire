// =====================================================================================================================
//
//  File:       CDClientRecord+CoreDataClass.swift
//  Project:    Swiftfire
//
//  Version:    0.9.13
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.12 - Switched requestReceived andrequetsCompleted to javaDate (Int64)
// v0.9.11 - Initial release
// =====================================================================================================================

import Foundation
import CoreData


// To keep the JSON code compact and fast to parse, use single letter identifiers.

private let CONNECTION_ALLOCATION_COUNT = "A"
private let CONNECTION_OBJECT_ID = "I"
private let HOST = "H"
private let HTTP_RESPONSE_CODE = "C"
private let REQUEST_RECEIVED = "R"
private let RESPONSE_DETAILS = "D"
private let SOCKET = "S"
private let URLSTR = "U"
private let REQUEST_COMPLETED = "O"
private let URL_COUNTER = "N"


class CDClientRecord: NSManagedObject {
    
    var json: VJson {
        let json = VJson()
        json[CONNECTION_ALLOCATION_COUNT] &= connectionAllocationCount
        json[CONNECTION_OBJECT_ID] &= connectionObjectId
        json[HOST] &= host ?? ""
        json[HTTP_RESPONSE_CODE] &= httpResponseCode ?? ""
        json[RESPONSE_DETAILS] &= responseDetails ?? ""
        json[REQUEST_RECEIVED] &= requestReceived
        json[REQUEST_COMPLETED] &= requestCompleted
        json[SOCKET] &= socket
        json[URLSTR] &= url ?? ""
        json[URL_COUNTER] &= urlCounter?.instanceId ?? 0
        return json
    }
    
    static func createFrom(json: VJson, inContext context: NSManagedObjectContext) -> CDClientRecord? {
        
        guard let jconnectionallocationcount = (json|CONNECTION_ALLOCATION_COUNT)?.int32Value else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'connection allocation count' item in json code")
            return nil
        }
        
        guard let jconnectionid = (json|CONNECTION_OBJECT_ID)?.int16Value else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'connection id' item in json code")
            return nil
        }
        
        guard let jrequestreceived = (json|REQUEST_RECEIVED)?.int64Value else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'request received' item in json code")
            return nil
        }
        
        guard let jrequestcompleted = (json|REQUEST_COMPLETED)?.int64Value else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'request completed' item in json code")
            return nil
        }
        
        guard let jsocket = (json|SOCKET)?.int32Value else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'socket' item in json code")
            return nil
        }
        
        guard json|HOST != nil else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'host' item in json code")
            return nil
        }
        
        guard json|HTTP_RESPONSE_CODE != nil else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'http response code' item in json code")
            return nil
        }
        
        guard json|RESPONSE_DETAILS != nil else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'response details' item in json code")
            return nil
        }
        
        guard json|URLSTR != nil else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Could not find 'url' item in json code")
            return nil
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: "CDClientRecord", into: context) as! CDClientRecord
        
        new.connectionAllocationCount = jconnectionallocationcount
        new.connectionObjectId = jconnectionid
        new.host = (json|HOST)?.stringValue
        new.httpResponseCode = (json|HTTP_RESPONSE_CODE)?.stringValue
        new.responseDetails = (json|RESPONSE_DETAILS)?.stringValue
        new.requestReceived = jrequestreceived
        new.requestCompleted = jrequestcompleted
        new.socket = jsocket
        new.url = (json|URLSTR)?.stringValue
        
        if let jurlcounter = (json|URL_COUNTER)?.int64Value {
            
            if jurlcounter != 0 {
                
                do {
                    let fetchRequest: NSFetchRequest<CDCounter> = CDCounter.fetchRequest()
                    let counters = try context.fetch(fetchRequest).filter(){ $0.instanceId == jurlcounter }
                    for c in counters {
                        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Counter id = \(c.instanceId)")
                    }
                    if counters.count != 1 { throw SFError(message: "Found \(counters.count) counter objects for identifier \(jurlcounter), expected 1)") }
                    new.urlCounter = counters[0]
                } catch {
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "\(error)")
                    context.delete(new)
                    return nil
                }
            }
        }
        return new
    }
}
