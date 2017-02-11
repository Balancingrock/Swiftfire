//
//  ST_PathPart.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON


/// Records the number of accesses this part of the URL has had.

final class ST_PathPart: VJsonConvertible {
    
    
    /// If set to 'true' then don't increment the counter for this url path and ignorde the rest of the url.
    
    var doNotTrace: Bool = false
    
    
    /// The total count for this part of the url, this counter is always incremented regardless of the doNotTrace settings.
    
    var foreverCount: Int64 = 0
    
    
    /// The string that represents this url part.
    
    var pathPart: String
    
    
    /// The counter currently in use. Note that counters are recursive until the very first counter that was used.
    
    var counterList: ST_Counter?
    
    
    /// A list of path parts that come after this part in the url.
    
    var nextParts: [ST_PathPart] = []
    
    
    /// The VJson hierarchy that represents the content of this path part.
    
    var json: VJson {
        let json = VJson()
        json["d"] &= doNotTrace
        json["f"] &= foreverCount
        json["p"] &= pathPart
        json["c"] &= counterList?.json ?? VJson.null()
        json["n"] &= VJson(nextParts)
        return json
    }

    
    /// Recreates a path part from the given VJson hierarchy.
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jDoNotTrace   = (json|"d")?.boolValue else { return nil }
        guard let jForeverCount = (json|"f")?.int64Value else { return nil }
        guard let jPathPart     = (json|"p")?.stringValue else { return nil }
        guard let jCounterList  = (json|"c") else { return nil }
        guard let jNext         = (json|"n") else { return nil }
        
        if !jCounterList.isNull {
            guard let counterList = ST_Counter(json: jCounterList) else { return nil }
            self.counterList = counterList
        }
        
        self.doNotTrace = jDoNotTrace
        self.foreverCount = jForeverCount
        self.pathPart = jPathPart
        
        for jpp in jNext {
            guard let pp = ST_PathPart(json: jpp) else { return nil }
            self.nextParts.append(pp)
        }
    }
    
    
    /// Creates a new path part.
    
    init(_ part: String) {
        self.pathPart = part
    }
    
    
    /// Return the pathPart for the requested part. If doNotTrace is set to true, return nil. If the part does not exist yet, create it.
    
    func getPathPart(for part: String) -> ST_PathPart? {
        if doNotTrace { return nil }
        if let pp = nextParts.first(where: { $0.pathPart == part }) {
            return pp
        }
        let pp = ST_PathPart(part)
        nextParts.append(pp)
        return pp
    }
    
    
    /// Update the counter and the forevercount
    
    func updateCounter() {
        
        // Create an initial counter if necessary
        if counterList == nil { counterList = ST_Counter(forDay: statistics.today) }
        
        // Create a new counter if necessary
        if counterList!.forDay < statistics.today {
            
            // Create new counter
            let newCounter = ST_Counter(forDay: statistics.today)
            newCounter.next = counterList!
        }
        
        counterList!.increment()

        foreverCount += 1
    }
}
