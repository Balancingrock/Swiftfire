//
//  PathCounter.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 06/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation

class PathCounter {
    
    // The date formatter for this class
    
    static var dateFormatter: NSDateFormatter = {
        let ltf = NSDateFormatter()
        ltf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return ltf
    }()

    
    /// The path this counter is for
    
    let path: String
    
    
    /// The counter that keeps track on how many times the path was requested
    
    var count = UIntTelemetry()
    
    
    /// The time this object was instantiated
    
    let startTime: NSDate
    
    
    /// The time this object was saved
    
    var endTime: NSDate?
    
    
    /// The JSON code for this object
    
    var json: VJson {
        let j = VJson.createObject(name: "PathCounter")
        j["Path"].stringValue = path
        j["Count"].integerValue = count.intValue
        j["StartTime"].stringValue = PathCounter.dateFormatter.stringFromDate(startTime)
        if let endTime = self.endTime {
            j["EndTime"].stringValue = PathCounter.dateFormatter.stringFromDate(endTime)
        } else {
            j["EndTime"].nullValue = true
        }
        return j
    }
    
    init(path: String) {
        self.path = path
        self.startTime = NSDate()
    }
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jpath = (json|"Path")?.stringValue else { return nil }
        guard let jcount = (json|"Count")?.integerValue else { return nil }
        guard let jstarttimestring = (json|"StartTime")?.stringValue else { return nil }
        guard let jstarttime = PathCounter.dateFormatter.dateFromString(jstarttimestring) else { return nil }
        
        self.path = jpath
        self.count = UIntTelemetry(initialValue: UInt(jcount))
        self.startTime = jstarttime
        
        if let jendtimestring = (json|"EndTime")?.stringValue {
            self.endTime = PathCounter.dateFormatter.dateFromString(jendtimestring)
        }
    }
}
