// =====================================================================================================================
//
//  File:       ControlBlockIndexableDataSource.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Initial version
//
// =====================================================================================================================

import Foundation

import BRBON


/// The data source protocol for a control block that has indexed access to the elements in a collection.

public protocol ControlBlockIndexableDataSource {
    
    
    /// The number of elements in this source
    
    var count: Int { get }
    
    
    /// Adds the contents of self to a Functions.Info dictionary
    ///
    /// - Parameter to: The directory to update.
    
    func addElement(at index: Int, to info: inout Functions.Info)
}


/// A protocol that allows self to express itself into one or more entries in a Functions.Info dictionary

public protocol FunctionsInfoDataSource {

    
    /// Express self (or items within self) into a Functions.Info dictionary
    
    func addSelf(to info: inout Functions.Info)
}


extension Array: ControlBlockIndexableDataSource where Element: FunctionsInfoDataSource {
    
    public func addElement(at index: Int, to info: inout Functions.Info) {
        guard index < self.count else { return }
        guard index >= 0 else { return }
        self[index].addSelf(to: &info)
    }
}


extension Dictionary: FunctionsInfoDataSource {
    
    public func addSelf(to info: inout Functions.Info) {
        self.forEach { (key, value) in
            if (key is CustomStringConvertible) && (value is CustomStringConvertible) {
                info[(key as! CustomStringConvertible).description] = (value as! CustomStringConvertible).description
            }
        }
    }
}


extension Portal: FunctionsInfoDataSource {
    
    public func addSelf(to info: inout Functions.Info) {
        switch self.itemType! {
        case .bool: if let name = itemName { info[name] = String(bool!) }
        case .uint8: if let name = itemName { info[name] = String(uint8!) }
        case .uint16: if let name = itemName { info[name] = String(uint16!) }
        case .uint32: if let name = itemName { info[name] = String(uint32!) }
        case .uint64: if let name = itemName { info[name] = String(uint64!) }
        case .int8: if let name = itemName { info[name] = String(int8!) }
        case .int16: if let name = itemName { info[name] = String(int16!) }
        case .int32: if let name = itemName { info[name] = String(int32!) }
        case .int64: if let name = itemName { info[name] = String(int64!) }
        case .uuid: if let name = itemName { info[name] = uuid!.uuidString }
        case .string: if let name = itemName { info[name] = string! }
        case .crcString: if let name = itemName { info[name] = string! }
        case .float32: if let name = itemName { info[name] = String(float32!) }
        case .float64: if let name = itemName { info[name] = String(float64!) }
        case .array, .binary, .crcBinary, .dictionary, .sequence, .table, .color, .font, .null: break
        }
    }
}

extension Portal: ControlBlockIndexableDataSource {

    public func addElement(at index: Int, to info: inout Functions.Info) {
        switch self.itemType! {
        case .array, .sequence: if index < count { self[index].addSelf(to: &info) }
        case .table:
            if index < count {
                self[index].portal?.itterateFields(ofRow: index, closure: { (portal, _) -> Bool in
                    portal.addSelf(to: &info)
                    return true
                })
            }
        default: break
        }
    }
}
