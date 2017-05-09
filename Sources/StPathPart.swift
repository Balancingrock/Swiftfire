// =====================================================================================================================
//
//  File:       StPathPart.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.1
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
// 0.10.1 - Fixed warnings from Xcode 8.3
// 0.10.0 - Added parameter nilOnDoNotTrace to getPathPart
// 0.9.17 - Header update
// 0.9.15 - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON


/// Records the number of accesses this part of the URL has had.

public final class StPathPart: VJsonConvertible {
    
    
    /// If set to 'true' then don't increment the counter for this url path and ignorde the rest of the url.
    
    public var doNotTrace: Bool = false
    
    
    /// The total count for this part of the url, this counter is always incremented regardless of the doNotTrace settings.
    
    public var foreverCount: Int64 = 0
    
    
    /// The string that represents this url part.
    
    public var pathPart: String
    
    
    /// The counter currently in use. Note that counters are recursive until the very first counter that was used.
    
    public var counterList: StCounter?
    
    
    /// A list of path parts that come after this part in the url.
    
    public var nextParts: [StPathPart] = []
    
    
    /// The preceding path part
    
    public var previous: StPathPart?
    
    
    /// The VJson hierarchy that represents the content of this path part.
    
    public var json: VJson {
        let json = VJson()
        json["d"] &= doNotTrace
        json["f"] &= foreverCount
        json["p"] &= pathPart
        json["c"] &= counterList?.json ?? VJson.null()
        json["n"] &= VJson(nextParts)
        return json
    }

    
    /// Recreates a path part from the given VJson hierarchy.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jDoNotTrace   = (json|"d")?.boolValue else { return nil }
        guard let jForeverCount = (json|"f")?.int64Value else { return nil }
        guard let jPathPart     = (json|"p")?.stringValue else { return nil }
        guard let jCounterList  = (json|"c") else { return nil }
        guard let jNext         = (json|"n") else { return nil }
        
        if !jCounterList.isNull {
            guard let counterList = StCounter(json: jCounterList) else { return nil }
            self.counterList = counterList
        }
        
        self.doNotTrace = jDoNotTrace
        self.foreverCount = jForeverCount
        self.pathPart = jPathPart
        
        for jpp in jNext {
            guard let pp = StPathPart(json: jpp) else { return nil }
            pp.previous = self
            self.nextParts.append(pp)
        }
    }
    
    
    /// Creates a new path part.
    
    public init(_ part: String, previous: StPathPart?) {
        self.pathPart = part
        self.previous = previous
    }
    
    
    /// Return the pathPart for the requested part. If doNotTrace is set to true, return nil. If the part does not exist yet, create it.
    
    public func getPathPart(for part: String, nilOnDoNotTrace: Bool = true) -> StPathPart? {
        if nilOnDoNotTrace && doNotTrace { return nil }
        if let pp = nextParts.first(where: { $0.pathPart == part }) {
            return pp
        }
        let pp = StPathPart(part, previous: self)
        nextParts.append(pp)
        return pp
    }
    
    
    /// Update the counter and the forevercount
    
    public func updateCounter(today: Int64) {
        
        // Create an initial counter if necessary
        if counterList == nil { counterList = StCounter(forDay: today, previous: nil) }
        
        // Create a new counter if necessary
        if counterList!.forDay < today {
            
            // Create new counter
            let newCounter = StCounter(forDay: today, previous: counterList)
            newCounter.next = counterList
            counterList = newCounter
        }
        
        counterList!.increment()

        foreverCount += 1
    }
    
    
    /// A temporary count used for display purposes
    
    public var count: Int64 = 0
    
    
    /// Recalculates the temporary count
    
    public func recalculateCount(from startDate: Int64, to endDate: Int64) {
        
        var privateCount: Int64 = 0
        
        if let counter = counterList {
            
            if counter.forDay >= startDate && counter.forDay <= endDate  {
                privateCount = Int64(counter.count)
            }
            
            var whileCounter = counter.next
            while whileCounter != nil {
                if whileCounter!.forDay >= startDate && whileCounter!.forDay <= endDate  {
                    privateCount += Int64(whileCounter!.count)
                }
                whileCounter = whileCounter!.next
            }
        }
        
        count = privateCount
        
        
        // Propagate to sub-parts
        for pp in nextParts {
            pp.recalculateCount(from: startDate, to: endDate)
        }
    }
    
    
    /// The full URL ending in this path part
    
    public var fullUrl: String {
        var urlstr = pathPart
        var current = previous
        while current != nil {
            urlstr = (current!.pathPart as NSString).appendingPathComponent(urlstr)
            current = current!.previous
        }
        return urlstr
    }

}
