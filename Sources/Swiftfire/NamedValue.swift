// =====================================================================================================================
//
//  File:       NamedValue.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2019 Marinus van der Lugt, All rights reserved.
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation


class NamedValue {
    
    
    /// The queue on which all access will take place
    
    static let queue = DispatchQueue(label: "NamedValues")
    
    
    /// The queue on which all didSetActions will take place. If a GUI has to be updated, set this to the DispatchQueue.main.
    
    static var actionsQueue = DispatchQueue(label: "NamedValuesDidSetActions")

    
    /// The name of the item (implements part of NamedValueProtocol)
    
    var name: String
    
    
    /// A description of what the value is for (can be used in GUIs) (implements part of NamedValueProtocol)
    
    var about: String

    
    /// The action to be executed after an update
    
    var didSetActions: [DidSetActionSignature] = []
    
    
    /// Create a new object
    
    init(name: String, about: String) {
        self.name = name
        self.about = about
    }
}



