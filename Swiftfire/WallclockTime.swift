// =====================================================================================================================
//
//  File:       WallclockTime.swift
//  Project:    Swiftfire
//
//  Version:    0.9.9
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
// v0.9.9 - Replaced NSCalendarOptions.MatchFirst with NSCalendarOptions.MatchNextTime because the former caused an exception in playground
// v0.9.7 - Initial release
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
public struct WallclockTime {
    public let hour: Int
    public let minute: Int
    public let second: Int
    
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
