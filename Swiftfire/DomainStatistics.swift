// =====================================================================================================================
//
//  File:       DomainStatistics.swift
//  Project:    Swiftfire
//
//  Version:    0.9.10
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// v0.9.10 - Initial release (was previously present as 'statistics.swift', but unused)
// =====================================================================================================================

import Foundation


/**
 This class associates two counters with a value. Both of the counters are increment by a call to "increment()". One of the counters can be reset, the other counter will keep increasing.
 */
class ValueStatistics<T: VJsonSerializable> {

    let value: T
    
    private var count: UIntTelemetry
    
    private var resetableCount: UIntTelemetry
    
    init(value: T) {
        self.value = value
        count = UIntTelemetry()
        resetableCount = UIntTelemetry()
    }
    
    var json: VJson {
        let json = VJson.createObject(name: nil)
        json.addChild(value.json, forName: "Value")
        json["Count"].integerValue = count.intValue
        json["ResetableCount"].integerValue = resetableCount.intValue
        return json
    }
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jvalue = T(json: json|"Value") else { return nil }
        guard let jtr = (json|"Count")?.integerValue else { return nil }
        guard let jtrsls = (json|"ResetableCount")?.integerValue else { return nil }
        
        self.value = jvalue
        self.count = UIntTelemetry(initialValue: UInt(jtr))
        self.resetableCount = UIntTelemetry(initialValue: UInt(jtrsls))
    }
    
    func increment() {
        count.increment()
        resetableCount.increment()
    }
    
    func reset() {
        resetableCount.reinitialize()
    }
}

class ValuesStatistics<T: VJsonSerializable where T: Hashable>: VJsonSerializable {
    
    var values: Dictionary<T, ValueStatistics<T>> = [:]
    
    var maxCount: Int?
    
    
    /// Returns an unnamed object with the contents of self serialized.
    
    var json: VJson {
        get {
            let vj = VJson.createObject(name: nil)
            vj["MaxCount"].integerValue = maxCount
            vj["Values"] = VJson.createArray(name: "Values")
            for (_, value) in values {
                vj["Values"].appendChild(value.json)
            }
            return vj
        }
    }
    
    
    /// The maxCount is the maximum number of elements that this object can contain.
    
    init(maxCount: Int) {
        self.maxCount = maxCount
    }
    
    
    /// Create this object from the JSON code (if possible)
    
    required init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jmaxcount = (json|"MaxCount")?.integerValue else { return nil }
        guard let jvalues = json|"Values" else { return nil }
        guard jvalues.isArray else { return nil }
        
        self.maxCount = jmaxcount
        for jval in jvalues {
            if let vs = ValueStatistics<T>(json: jval) {
                values[vs.value] = vs
            }
        }
    }
    
    
    /// Reinitializes all elements
    
    func reset() {
        values.forEach( { $1.reset() } )
    }
    
    
    /// Adds the given value to the internal dictionary or increases its count if it already exists.
    /// - Returns: True if the operation was successful, false if the element did not exist yet and could not be added.
    
    func addOrCount(value: T) -> Bool {
        var vs = values[value]
        if vs == nil {
            if let maxCount = maxCount {
                if values.count <= maxCount {
                    vs = ValueStatistics(value: value)
                    values[value] = vs
                }
            } else {
                vs = ValueStatistics(value: value)
                values[value] = vs
            }
        }
        vs?.increment()
        return vs != nil
    }
}

extension String: VJsonSerializable {
    var json: VJson {
        get {
            return VJson.createString(value: self, name: nil)
        }
    }
    init?(json: VJson?) {
        guard let jself = json?.stringValue else { return nil }
        self = jself
    }
}

final class DomainStatistics {
    
    
    // Updating of statistics is done on this queue
    
    private static let queue = dispatch_queue_create("DomainStatistics", DISPATCH_QUEUE_SERIAL)

    
    // The requested resource path statistics
    
    private var resourceStatistics = ValuesStatistics<String>(maxCount: 10000)
    
    
    // Will be set to 'true' if the resourceStatistics cannot accept new resource paths anymore.
    
    private var resourceOverflow = false
    
    
    // The file containing the resource path statistics
    
    private var resourceFile: Logfile

    
    // The ip address statistics dictionary
    
    private var ipStatistics = ValuesStatistics<String>(maxCount: 10000)
    
    
    // Will be set to 'true' if the ipStatistics cannot accept new ip addresses anymore.
    
    private var ipOverflow = false

    
    // The file containing the ip address statistics
    
    private var ipFile: Logfile

    
    // These timed closures ensure the creation of the files at the requested intervals.
    
    private var periodicResourceFileSaving: TimedClosure?
    private var dailyResourceFileSaving: TimedClosure?
    private var periodicIpAddressFileSaving: TimedClosure?
    private var dailyIpAddressFileSaving: TimedClosure?

    /**
     Constructor.
     
     - Note: For the files, the InitOption.MaxFileSize and InitOption.MaxNofFiles will be ignored.
     
     - Parameter resourceFile: The Logfile that will contain the statistics for the resource path accesses.
     - Parameter ipFile: The Logfile that will contain the IP addresses that have accesses the resources.
     */
    init(resourceFile: Logfile, ipFile: Logfile) {
        
        self.resourceFile = resourceFile
        self.ipFile = ipFile
        
        if let delay = resourceFile.newFileAfterDelay {
            periodicResourceFileSaving = TimedClosure(queue: DomainStatistics.queue, delay: delay, closure: { [weak self] in self?._saveResourceStatistics() })
        }
        
        if let daily = resourceFile.newFileDailyAt {
            dailyResourceFileSaving = TimedClosure(queue: DomainStatistics.queue, wallclockTime: daily, closure: { [weak self] in self?._saveResourceStatistics() })
        }
        
        if let delay = ipFile.newFileAfterDelay {
            periodicIpAddressFileSaving = TimedClosure(queue: DomainStatistics.queue, delay: delay, closure: { [weak self] in self?._saveIpAddressStatistics() })
        }
        
        if let daily = ipFile.newFileDailyAt {
            dailyIpAddressFileSaving = TimedClosure(queue: DomainStatistics.queue, wallclockTime: daily, closure: { [weak self] in self?._saveIpAddressStatistics() })
        }
        
        // Set the options on the files to nil.
        
        self.resourceFile.maxFileSize = nil
        self.resourceFile.maxNofFiles = nil
        self.resourceFile.newFileAfterDelay = nil
        self.resourceFile.newFileDailyAt = nil

        self.ipFile.maxFileSize = nil
        self.ipFile.maxNofFiles = nil
        self.ipFile.newFileAfterDelay = nil
        self.ipFile.newFileDailyAt = nil
    }
    
    
    /**
     Create the statistics information. The statistics are not immediately updated, but a request to do so is placed in a queue.
     
     - Parameter header: The header of the http request.
     - Parameter connection: The connection that handles the request
     */
    func record(header: HttpHeader, connection: HttpConnection) {
        dispatch_async(DomainStatistics.queue, { [unowned self] in self._record(header, connection: connection)})
    }
    
    
    // The private implementation of 'record()'
    
    private func _record(header: HttpHeader, connection: HttpConnection) {
        
        if let resourcePath = header.url {
            if !resourceStatistics.addOrCount(resourcePath) {
                if !resourceOverflow {
                    log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "Resource path statistics overflow, no new statistics will be created for \(resourcePath).")
                    resourceOverflow = true
                }
            }
        }
        
        if !ipStatistics.addOrCount(connection.clientIp) {
            if !ipOverflow {
                log.atLevelWarning(id: -1, source: #file.source(#function, #line), message: "IP Address statistics overflow, no new statistics will be created for \(connection.clientIp).")
                ipOverflow = true
            }
        }
    }
    
    
    /**
     Saves the resource path and ip address statistics to the files specified when this opbject was created. Note that the files will probably auto-save as well so this operation should only be called if the server terminates or when the user requests it.
     */
    func save() {
        dispatch_async(DomainStatistics.queue, { [weak self] in
            self?._saveResourceStatistics()
            self?._saveIpAddressStatistics()
            })
    }

    private func _saveResourceStatistics() {
        resourceFile.record(resourceStatistics.json.description)
        resourceFile.close()
    }

    private func _saveIpAddressStatistics() {
        ipFile.record(ipStatistics.json.description)
        ipFile.close()
    }
}