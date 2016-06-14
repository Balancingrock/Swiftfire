// =====================================================================================================================
//
//  File:       WallclockTime.swift
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
// v0.9.10 - Improved init of WallclockTime, added init from string, added compliance to Equatable and CustomStringConvertible
// v0.9.9  - Replaced NSCalendarOptions.MatchFirst with NSCalendarOptions.MatchNextTime because the former caused an exception in playground
// v0.9.7  - Initial release
// =====================================================================================================================

import Foundation

public func == (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
    if lhs.hour != rhs.hour { return false }
    if lhs.minute != rhs.minute { return false }
    if lhs.second != rhs.second { return false }
    return true
}

public func != (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
    return !(lhs == rhs)
}

public func > (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
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

public func < (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
    if lhs == rhs { return false }
    return !(lhs > rhs)
}

public func >= (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
    if lhs == rhs { return true }
    return (lhs > rhs)
}

public func <= (lhs: WallclockTime, rhs: WallclockTime) -> Bool {
    if lhs == rhs { return true }
    return (lhs < rhs)
}

public func + (lhs: WallclockTime, rhs: WallclockTime) -> (time: WallclockTime, tomorrow: Bool) {
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

public func + (lhs: NSDate, rhs: WallclockTime) -> NSDate {
    return NSCalendar.currentCalendar().dateByAddingComponents(rhs.dateComponents, toDate: lhs, options: NSCalendarOptions.MatchNextTime)!
}

/// A 24-hour wallclock implementation

public struct WallclockTime: CustomStringConvertible, Equatable {
    
    public let hour: Int
    public let minute: Int
    public let second: Int
    
    public var description: String { return "\(hour):\(minute):\(second)" }
    
    /**
     Creates a new Wallclock time from the given units. It is safe to specify over-unit values. If done, these over-unit values will be carried over into the next higher unit for as much as possible. If an over-unit results in the hour component to be bigger than 24, only the over-unit part will be used. Example: Wallclock(hour: 123, minute: 456, second: 7890) will result in a Wallclock time of 12:47:30.
     */
    
    public init(hour: Int, minute: Int, second: Int) {
        self.second = second % 60
        let minutesFromSeconds = (second - second % 60) / 60
        let minutes = minute + minutesFromSeconds
        self.minute = minutes % 60
        let hoursFromMinutes = (minutes - minutes % 60) / 60
        let hours = hour + hoursFromMinutes
        self.hour = hours % 24
    }
    
    
    /**
     Creates a new Wallclock time from the given string. The string should follow the "hour:minute:second" syntax. If a single number is present, it will be interpreted as a number of seconds. Two numbers as minute's and second's.
     */
    
    public init?(string: String) {
        let parts = string.componentsSeparatedByString(":")
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
    
    public var dateComponents: NSDateComponents {
        let comp = NSDateComponents()
        comp.hour = self.hour
        comp.minute = self.minute
        comp.second = self.second
        return comp
    }
}


public extension NSDate {
    
    /// The wallclock time from self in the current calendar
    public var wallclockTime: WallclockTime {
        let comp = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: self)
        return WallclockTime(hour: comp.hour, minute: comp.minute, second: comp.second)
    }
    
    /// A new NSDate set to the first future wallclock time in the current calendar
    public static func firstFutureDate(with wallclockTime: WallclockTime) -> NSDate {
        return NSCalendar.currentCalendar().nextDateAfterDate(NSDate(), matchingHour: wallclockTime.hour, minute: wallclockTime.minute, second: wallclockTime.second, options: NSCalendarOptions.MatchNextTime)!
    }
}
