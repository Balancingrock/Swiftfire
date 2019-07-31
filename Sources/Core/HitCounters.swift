// =====================================================================================================================
//
//  File:       HitCounters.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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
//  Like you, I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (again: rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.0.0 - Initial version
//
// =====================================================================================================================

import Foundation

import VJson


public struct HitCounters {
    
    var counters: Dictionary<String, Int64> = [:]

    
    /// - Returns: The string with the number of hits for the string but does no change the count value.
    
    public func stringValue(_ str: String) -> String? {
        return counters[str]?.description
    }
    
    
    /// - Returns: A string with the number of hits for the string, creates a new element if necessary and increases the count by 1 before returning the value
    
    @discardableResult
    public mutating func increment(_ str: String) -> String {
        if counters[str] == nil {
            counters[str] = 0
        }
        let hits = counters[str]!
        counters[str] = hits + 1
        return stringValue(str)!
    }
    
    
    /// Removes all keys from the hit counters
    
    mutating func removeAll() {
        counters = [:]
    }
    
    
    /// Resets all hitcounters to zero.
    
    mutating func resetToZero() {
        counters.forEach { (key: String, _: Int64) in
            counters[key] = 0
        }
    }
    
    
    /// Save the content of the counter values to file.
    
    func save(to file: URL) {
        let json = VJson.object()
        counters.forEach { (key: String, value: Int64) in
            json[key] &= value
        }
        json.save(to: file)
    }
    
    
    /// Loads the contents from the file, overwriting existing values (if any).
    
    mutating func restore(from file: URL) {
        counters = [:]
        guard let json = VJson.parse(file: file, onError: { (_, _, _, message) in
            Log.atError?.log("Error reading hitCounter values from \(file.path), message = \(message)")
            }) else { return }
        for item in json {
            if let name = item.nameValue, let value = item.int64Value {
                counters[name] = value
                Log.atDebug?.log("Hitcounter for \(name) set to \(value)")
            } else {
                Log.atError?.log("Error reading a value from the hitcounter file \(file.path)")
            }
        }
    }
}
