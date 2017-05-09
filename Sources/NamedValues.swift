// =====================================================================================================================
//
//  File:       NamedValues.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.6
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// 0.10.6 - Reworked & renamed from UIntTelemetry to NamesValues
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Upgraded to Xcode 8 beta 6
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.6  - Header update
// 0.9.3  - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import BRUtils




/// For the action to be performed when an update is successful

public typealias DidSetActionSignature = () -> Void


/// This contains the operations that have no default implementation.

public protocol NamedValueProtocol {
    
    /// The name of the item
    
    var name: String { get }
    
    
    /// A description of what the value is for (can be used in GUIs)
    
    var about: String { get }
    
    
    /// The value as string
    
    var stringValue: String { get }
    
    
    /// Set the value to the value contained in the given string.
    ///
    /// - Returns: True if the operation was successful
    
    func setValue(_ value: String) -> Bool
    
    
    // Reset the contained value to its initial value.
    
    func reset()
    
    
    /// Adds an action to be executed after an update
    
    func addDidSetAction(_ action: @escaping DidSetActionSignature)
}


/// All items must implement the following protocol

public class NamedValue {
    
    
    /// The queue on which all access will take place
    
    fileprivate static let queue = DispatchQueue(label: "NamedValues")
    
    
    /// The queue on which all didSetActions will take place. If a GUI has to be updated, set this to the DispatchQueue.main.
    
    public static var actionsQueue = DispatchQueue(label: "NamedValuesDidSetActions")

    
    /// The name of the item
    
    public var name: String
    
    
    /// A description of what the value is for (can be used in GUIs)
    
    public var about: String

    
    /// The action to be executed after an update
    
    public var didSetActions: [DidSetActionSignature] = []
    
    
    /// Create a new object
    
    public init(name: String, about: String) {
        self.name = name
        self.about = about
    }
}


/// A bool based item

public final class NamedBoolValue: NamedValue, NamedValueProtocol, CustomStringConvertible {
    
    
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
    
    
    /// CustomStringConvertible
    
    public var description: String {
        return NamedValue.queue.sync {
            [weak self] in
            guard let `self` = self else { return "*** error ***" }
            return "\(self.name): \(self._value)" }
    }

    
    /// Create a new object
    
    public init(name: String, about: String, value: Bool, resetValue: Bool) {
        self._value = value
        self.resetValue = resetValue
        super.init(name: name, about: about)
    }
    
    
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


/// A string based item

public final class NamedStringValue: NamedValue, NamedValueProtocol, CustomStringConvertible {
    
    
    /// The reset function will copy this to _value.

    public let resetValue: String
    
    
    /// The payload

    private var _value: String {
        didSet {
            didSetActions.forEach() {
                action in
                NamedValue.actionsQueue.async {
                    action()
                }
            }
        }
    }
    public var value: String {
        get { return NamedValue.queue.sync { [weak self] in return self?._value ?? "" } }
        set {
            NamedValue.queue.async {
                [weak self] in
                self?._value = newValue
            }
        }
    }
    
    
    /// CustomStringConvertible

    public var description: String {
        return NamedValue.queue.sync {
            [weak self] in
            guard let `self` = self else { return "*** error ***" }
            return "\(self.name): \(self._value)" }
    }
    
    
    /// Create a new object
    
    public init(name: String, about: String, value: String, resetValue: String) {
        self._value = value
        self.resetValue = resetValue
        super.init(name: name, about: about)
    }
    
    
    /// The value as a string.

    public var stringValue: String {
        get { return NamedValue.queue.sync { [weak self] in return self?._value.description ?? "error" } }
    }
    
    
    /// The string containing the new value.

    @discardableResult
    public func setValue(_ value: String) -> Bool {
        return NamedValue.queue.sync { [weak self] in self?._value = value; return true }
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


/// An integer based item. This item has a range from 0 .. 999_999. It wraps around while incrementing but does not wrap around while decrementing.

public final class NamedIntValue: NamedValue, NamedValueProtocol, CustomStringConvertible {
    
    
    /// The reset function will copy this to _value.

    private let resetValue: Int
    
    
    /// The payload

    private var _value: Int {
        didSet {
            didSetActions.forEach() {
                action in
                NamedValue.actionsQueue.async {
                    action()
                }
            }
        }
    }
    public var value: Int {
        get { return NamedValue.queue.sync { [weak self] in return self?._value ?? 0 } }
        set {
            NamedValue.queue.async {
                [weak self] in
                self?._value = gf_clippedValue(lowLimit: 0, value: newValue, highLimit: 999_999)
            }
        }
    }
    
    
    /// CustomStringConvertible

    public var description: String {
        return NamedValue.queue.sync {
            [weak self] in
            guard let `self` = self else { return "*** error ***" }
            return "\(self.name): \(self._value)" }
    }
    

    /// Create a new object
    
    public init(name: String, about: String, value: Int, resetValue: Int) {
        self._value = value
        self.resetValue = resetValue
        super.init(name: name, about: about)
    }
    
    
    /// The value as a string.

    public var stringValue: String {
        get {
            return NamedValue.queue.sync { [weak self] in return self?._value.description ?? "error" }
        }
    }
    
    
    /// The string containing the new value.
        
    public func setValue(_ value: String) -> Bool {
        return NamedValue.queue.sync {
            [weak self] in
            if let i = Int(value) {
                self?._value = i
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

    
    /// Increments the contained value by 1 and wraps to zero afer 999.999.
    
    public func increment() {
        NamedValue.queue.sync {
            [weak self] in
            if (self?._value ?? 0) < 999_999 {
                self?._value += 1
            } else {
                self?._value = 0
            }
        }
    }
    
    
    /// Decrements the contained value by 1 but never goes below zero.
    
    public func decrement() {
        NamedValue.queue.sync {
            [weak self] in
            if self?._value != 0 {
                self?._value -= 1
            }
        }
    }
}
