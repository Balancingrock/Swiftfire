//
//  ST_Counter.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON


/// A counter for a path part. It contains the counter for a previous time period, thus creating a list of counters for successive time periods. Though counters are only created when an actual increment takes place.

final class ST_Counter: VJsonConvertible {

    
    /// The count
    
    var count: Int = 0
    
    
    /// The day for which this counter was created.
    
    var forDay: Int64
    
    
    /// The counter preceding the time period of this counter.
    
    var next: ST_Counter?

    
    /// The VJson hierarchy for this object.
    
    var json: VJson {
        let json = VJson()
        json["c"] &= count
        json["f"] &= forDay
        json["n"] &= next?.json ?? VJson.null()
        return json
    }

    
    /// Recreates the object from a VJson hierarchy.
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jCount  = (json|"c")?.intValue else { return nil }
        guard let jForDay = (json|"f")?.int64Value else { return nil }
        guard let jNext   = (json|"n") else { return nil }
        
        if !jNext.isNull {
            guard let counter = ST_Counter(json: jNext) else { return nil }
            next = counter
        }
        
        count = jCount
        forDay = jForDay
    }

    
    /// Creates a new counter for the given day.
    
    init(forDay: Int64 = statistics.today) {
        self.forDay = forDay
    }
    
    
    /// Increments the counter
    
    func increment() {
        count += 1
    }
}
