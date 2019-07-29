// =====================================================================================================================
//
//  File:       WallclockTime.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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


/// A 24-hour wallclock implementation

public struct WallclockTime: CustomStringConvertible, Equatable {
    
    public static func == (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
        if lhs.hour != rhs.hour { return false }
        if lhs.minute != rhs.minute { return false }
        if lhs.second != rhs.second { return false }
        return true
    }
    
    public static func != (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
        return !(lhs == rhs)
    }
    
    public static func > (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
        if lhs.hour < rhs.hour { return false }
        if lhs.hour > rhs.hour { return true }
        // lhs.hour == rhs.hour
        if lhs.minute < rhs.minute { return false }
        if lhs.minute > rhs.minute { return true }
        // lhs.minute == rhs.minute
        if lhs.second < rhs.second { return false }
        if lhs.second > rhs.second { return true }
        // lhs.second == rhs.second
        return false
    }
    
    public static func < (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
        if lhs == rhs { return false }
        return !(lhs > rhs)
    }
    
    public static func >= (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
        if lhs == rhs { return true }
        return (lhs > rhs)
    }
    
    public static func <= (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
        if lhs == rhs { return true }
        return (lhs < rhs)
    }
    
    public static func + (lhs: WallclockTime, rhs: WallclockTime) -> (time: WallclockTime, tomorrow: Bool) {
        var seconds = lhs.second + rhs.second
        var minutes = lhs.minute + rhs.minute
        var hours = lhs.hour + rhs.hour
        if seconds > 59 { seconds -= 60; minutes += 1 }
        if minutes > 59 { minutes -= 60; hours += 1 }
        if hours < 24 {
            return (WallclockTime(hour: hours, minute: minutes, second: seconds), false)
        } else {
            return (WallclockTime(hour: (hours - 24), minute: minutes, second: seconds), true)
        }
    }
    
    public static func + (lhs: Date, rhs: WallclockTime) -> Date {
        return Calendar.current.date(byAdding: rhs.dateComponents as DateComponents, to: lhs as Date)!
    }
    

    /// Hour
    
    public let hour: Int
    
    
    /// Minute
    
    public let minute: Int
    
    
    /// Second
    
    public let second: Int
    
    
    /// Textual representation of this object
    
    public var description: String { return "\(hour):\(minute):\(second)" }
    
    
    /// Creates a new object with the given units.
    ///
    /// It is safe to specify over-unit values. If done, these over-unit values will be carried over into the next higher unit for as much as possible. If an over-unit results in the hour component to be bigger than 24, only the over-unit part will be used. Example: Wallclock(hour: 123, minute: 456, second: 7890) will result in a Wallclock time of 12:47:30.
    ///
    /// - Parameters:
    ///   - hour: The value for the hour component.
    ///   - minute: The value for the minute component.
    ///   - second: The value for the second component
    
    public init(hour: Int, minute: Int, second: Int) {
        self.second = second % 60
        let minutesFromSeconds = (second - second % 60) / 60
        let minute = minute + minutesFromSeconds
        self.minute = minute % 60
        let hoursFromMinutes = (minute - minute % 60) / 60
        let hours = hour + hoursFromMinutes
        self.hour = hours % 24
    }
    
    
    /// Creates a new object.
    ///
    /// Creates a new Wallclock time from the given string. The string should follow the "hour:minute:second" syntax. If a single number is present, it will be interpreted as a number of seconds past midnight. Two numbers as minute's and second's past midnight.
    ///
    /// - Parameter string: The textual representation of the wallclock time. Up to three integers seperated by a ':' character.
    
    public init?(_ string: String) {
        let parts = string.components(separatedBy: ":")
        switch parts.count {
        case 0:
            return nil
            
        case 1:
            var seconds: Int = 0
            if !parts[0].isEmpty {
                if let val = Int(parts[0]) {
                    seconds = val
                } else {
                    return nil
                }
            } else {
                return nil
            }
            self.init(hour: 0, minute: 0, second: seconds)

        case 2:
            var minutes: Int = 0
            var seconds: Int = 0
            if !parts[0].isEmpty {
                if let val = Int(parts[0]) {
                    minutes = val
                } else {
                    return nil
                }
            }
            if !parts[1].isEmpty {
                if let val = Int(parts[1]) {
                    seconds = val
                } else {
                    return nil
                }
            }
            self.init(hour: 0, minute: minutes, second: seconds)

        case 3:
            var hours: Int = 0
            var minutes: Int = 0
            var seconds: Int = 0
            if !parts[0].isEmpty {
                if let val = Int(parts[0]) {
                    hours = val
                } else {
                    return nil
                }
            }
            if !parts[1].isEmpty {
                if let val = Int(parts[1]) {
                    minutes = val
                } else {
                    return nil
                }
            }
            if !parts[2].isEmpty {
                if let val = Int(parts[2]) {
                    seconds = val
                } else {
                    return nil
                }
            }
            self.init(hour: hours, minute: minutes, second: seconds)

        default: return nil
        }
    }
    
    
    /// Self represented as a DateComponents
    
    public var dateComponents: DateComponents {
        var comp = DateComponents()
        comp.hour = self.hour
        comp.minute = self.minute
        comp.second = self.second
        return comp
    }
}


extension Date {
    
    /// The wallclock time from self in the current calendar
    
    public var wallclockTime: WallclockTime {
        let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: self as Date)
        return WallclockTime(hour: comp.hour!, minute: comp.minute!, second: comp.second!)
    }
    
    /// A new NSDate set to the first future wallclock time in the current calendar
    
    static func firstFutureDate(with wallclockTime: WallclockTime) -> Date {
        var components = DateComponents()
        components.hour = wallclockTime.hour
        components.minute = wallclockTime.minute
        components.second = wallclockTime.second
        return Calendar.current.nextDate(after: Date(), matching: components, matchingPolicy: Calendar.MatchingPolicy.nextTime)!
    }
}
