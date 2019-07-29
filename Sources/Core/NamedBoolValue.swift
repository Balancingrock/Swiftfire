// =====================================================================================================================
//
//  File:       NamedBoolValue.swift
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import VJson
import SwifterLog
import BRUtils


/// A bool based item

public final class NamedBoolValue: NamedValue {
    
    
    /// The reset function will copy this to _value.
    
    public let resetValue: Bool
    
    
    /// The payload
    
    private var _value: Bool {
        didSet {
            didSetActions.forEach() {
                action in
                NamedValue.actionsQueue.async {
                    action()
                }
            }
        }
    }
    
    public var value: Bool {
        get { return NamedValue.queue.sync { [weak self] in return self?._value ?? false } }
        set {
            NamedValue.queue.async {
                [weak self] in
                self?._value = newValue
            }
        }
    }
    
    
    /// Create a new object
    
    public init(name: String, about: String, value: Bool, resetValue: Bool) {
        self._value = value
        self.resetValue = resetValue
        super.init(name: name, about: about)
    }
}


extension NamedBoolValue: NamedValueProtocol {
    
    
    /// The value as a string.
    
    public var stringValue: String {
        get {
            return NamedValue.queue.sync {
                [weak self] in
                guard let `self` = self else { return "*** error ***" }
                return self._value.description
            }
        }
    }

    
    /// The string containing the new value.
    ///
    /// Accepts 0, 1, Yes, No, True, False (case insensitive)
    
    public func setValue(_ value: String) -> Bool {
        return NamedValue.queue.sync {
            [weak self] in
            if let b = Bool(lettersOrDigits: value) {
                self?._value = b
                return true
            } else {
                return false
            }
        }
    }
    
    
    /// Copies the 'resetValue' to _value.
    
    public func reset() {
        NamedValue.queue.async {
            [weak self] in
            guard let `self` = self else { return }
            self._value = self.resetValue
        }
    }
    
    
    /// Adds an action to be executed after an update
    
    public func addDidSetAction(_ action: @escaping DidSetActionSignature) {
        didSetActions.append(action)
    }
}


extension NamedBoolValue: CustomStringConvertible {
    
    public var description: String {
        return NamedValue.queue.sync {
            [weak self] in
            guard let `self` = self else { return "*** error ***" }
            return "\(self.name): \(self._value)" }
    }
}
