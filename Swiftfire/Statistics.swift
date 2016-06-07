//
//  Statistics.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 06/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation


class DomainStatistics {
    
    private static let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)

    private static let MaxNofPathCounters = 10000
    
    private typealias PathCounters = Dictionary<String, PathCounter>

    private var pathCounters: PathCounters = [:]
    
    private var logdir: NSURL

    var pathCountersOverflow = false
    
    init(logdir: NSURL) {
        self.logdir = logdir
    }
    
    func record(resourcePath: String) {
        dispatch_async(DomainStatistics.queue, { [unowned self] in self._record(resourcePath)})
    }
    
    private func _record(resourcePath: String) {
        
        var pathCounter = pathCounters[resourcePath]
        
        if pathCounter == nil {
            if pathCounters.count < DomainStatistics.MaxNofPathCounters {
                pathCounter = PathCounter(path: resourcePath)
                pathCounters[resourcePath] = pathCounter
            } else {
                if !pathCountersOverflow {
                    log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "PathCounters overflow, no new pathCounters will be created.")
                    pathCountersOverflow = true
                }
            }
        }
        
        if let pathCounter = pathCounter {
            pathCounter.count.increment()
        }
    }
    
    func save() {
        dispatch_async(DomainStatistics.queue, { [unowned self] in self._save()})
    }
    
    private func _save() {
        
        let timestamp = PathCounter.dateFormatter.stringFromDate(NSDate())
        
        let json = VJson.createJsonHierarchy()
        
        json["Timestamp"].stringValue = timestamp
        
        for (_, pathCounter) in pathCounters {
            json["PathCounters"].appendChild(pathCounter.json)
        }
        
        if let file = Logfile(filename: "Statfile", fileExtension: "json", directory: logdir) {
            file.record(json.description)
            file.close()
        }
        
        // Allow a new entry of this warning after each save
        pathCountersOverflow = false
    }
}