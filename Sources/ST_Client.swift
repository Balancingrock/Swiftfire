//
//  ST_Client.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON


/// Client information.

final class ST_Client: VJsonConvertible {

    
    /// The address of the client
    
    var address: String
    
    
    /// If this is set to 'true' then the client info will not be updated for this client.
    
    var doNotTrace: Bool = false
    
    
    /// A list of all accesses for this client
    
    var records: [ST_ClientRecord] = []
    
    
    /// Stores all information in a VJson hierarchy

    var json: VJson {
        let json = VJson()
        json["a"] &= address
        json["d"] &= doNotTrace
        json["r"] &= VJson(records)
        return json
    }

    
    /// Recreates the content from the given VJson hierarchy.
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jAddress    = (json|"a")?.stringValue else { return nil }
        guard let jDoNotTrace = (json|"d")?.boolValue else { return nil }
        guard let jRecords    = (json|"r") else { return nil }
        
        for jRecord in jRecords {
            guard let record = ST_ClientRecord(json: jRecord) else { return nil }
            records.append(record)
        }
        
        self.address = jAddress
        self.doNotTrace = jDoNotTrace
    }

    
    /// Create a new object
    
    init(address: String) {
        self.address = address
    }
}
