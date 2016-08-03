// =====================================================================================================================
//
//  File:       Extensions.swift
//  Project:    Swiftfire
//
//  Version:    0.9.12
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
// v0.9.12 - Added javaDate & unixDate to NSDate extension
// v0.9.11 - Added NSDate and NSDateComponents extensions
//         - Removed faulty 'descriptionWithSeparator'
//         - Updated for VJson 0.9.8
// v0.9.6  - Header update
// w0.9.1  - Added 'descriptionWithSeparator'
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation

extension Bool {
    
    init?(_ str: String) {
        if str == "0" { self = false }
        else if str == "1" { self = true }
        else if str.compare("true", options: [.diacriticInsensitive, .caseInsensitive], range: nil, locale: nil) == ComparisonResult.orderedSame { self = true }
        else if str.compare("false", options: [.diacriticInsensitive, .caseInsensitive]) == ComparisonResult.orderedSame { self = false }
        else if str.compare("yes", options: [.diacriticInsensitive, .caseInsensitive]) == ComparisonResult.orderedSame { self = true }
        else if str.compare("no", options: [.diacriticInsensitive, .caseInsensitive]) == ComparisonResult.orderedSame { self = false }
        else { return nil }
    }
}

extension Array {
    
    @discardableResult
    mutating func removeObject<T: AnyObject>(object: T) -> T? {
        for (i, obj) in self.enumerated() {
            if obj as? T === object {
                return self.remove(at: i) as? T
            }
        }
        return nil
    }
}

extension Data {
    
    mutating func remove(range: Range<Int>) {
        var dummy: UInt8 = 0
        let empty = UnsafeBufferPointer<UInt8>(start: &dummy, count: 0)
        self.replaceBytes(in: range, with: empty)
    }
}

extension Dictionary {
    
    func arrayValue() -> Array<Value> {
        var elements: Array<Value> = []
        for (_, e) in self {
            elements.append(e)
        }
        return elements
    }
}

extension Date {
    
    func yearMonthDay(calendar: Calendar? = nil) -> DateComponents {
        let calendar = calendar ?? Calendar.current
        let components = calendar.components(Calendar.Unit(arrayLiteral: .year, .month, .day), from: self)
        return components
    }
    
    func hourMinuteSecond(calendar: Calendar? = nil) -> DateComponents {
        let calendar = calendar ?? Calendar.current
        let components = calendar.components(Calendar.Unit(arrayLiteral: .hour, .minute, .second), from: self)
        return components
    }
    
    
    /// Milli seconds since 1 Jan 1970
    
    var javaDate: Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    
    /// Seconds since 1 Jan 1970
    
    var unixTime: Int64 {
        return Int64(self.timeIntervalSince1970)
    }
    
    
    /// The javaDate for begin-of-day of self
    
    var javaDateBeginOfDay: Int64 {
        return Calendar.current.startOfDay(for: self).javaDate
    }
    
    
    /// The javaDate for the beginning of tomorrow.
    
    var javaDateBeginOfTomorrow: Int64 {
        return Calendar.current.date(byAdding: .day, value: 1, to: self, options: .matchNextTime)!.javaDateBeginOfDay
    }

    
    /// The javaDate for the beginning of yesterday.
    
    var javaDateBeginOfYesterday: Int64 {
        return Calendar.current.date(byAdding: .day, value: -1, to: self, options: .matchNextTime)!.javaDateBeginOfDay
    }

    
    /// The javaDate for the beginning of the week self is in
    
    var javaDateBeginOfWeek: Int64 {
        return Calendar.current.date(bySettingUnit: .weekday, value: 1, of: self, options: .matchNextTime)!.javaDateBeginOfDay
    }
    
    
    /// The javaDate for the beginning of the next week
    
    var javaDateBeginOfNextWeek: Int64 {
        let aDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: self, options: .matchNextTime)!
        return Calendar.current.date(bySettingUnit: .weekday, value: 1, of: aDate, options: .matchNextTime)!.javaDateBeginOfDay
    }
    

    /// The javaDate for the beginning of the month self is in
    
    var javaDateBeginOfMonth: Int64 {
        return Calendar.current.date(bySettingUnit: .day, value: 1, of: self, options: .matchNextTime)!.javaDateBeginOfDay
    }
    
    
    /// The javaData for the beginning of next month
    
    var javaDateBeginOfNextMonth: Int64 {
        let aDate = Calendar.current.date(byAdding: .month, value: 1, to: self, options: .matchNextTime)!
        return Calendar.current.date(bySettingUnit: .day, value: 1, of: aDate, options: .matchNextTime)!.javaDateBeginOfDay
    }
    
    
    /// From milli seconds since 1 Jan 1970
    
    static func fromJavaDate(value: Int64) -> Date {
        return Date(timeIntervalSince1970: Double(value / 1000))
    }
    
    
    /// From seconds since 1 Jan 1970
    
    static func fromUnixTime(value: Int64) -> Date {
        return Date(timeIntervalSince1970: Double(value))
    }
}

extension NSDateComponents {
    
    var json: VJson {
        let j = VJson.object()
        if self.year != NSDateComponentUndefined { j["Year"] &= self.year }
        if self.month != NSDateComponentUndefined { j["Month"] &= self.month }
        if self.day != NSDateComponentUndefined { j["Day"] &= self.day }
        if self.hour != NSDateComponentUndefined { j["Hour"] &= self.hour }
        if self.minute != NSDateComponentUndefined { j["Minute"] &= self.minute }
        if self.second != NSDateComponentUndefined { j["Second"] &= self.second }
        return j
    }
    
    /// - Note: Values that are not present will be undefined. I.e. have value: NSDateComponentUndefined
    
    convenience init?(json: VJson?) {
        guard let json = json else { return nil }
        self.init()
        if let jval = (json|"Year")?.intValue { self.year = jval }
        if let jval = (json|"Month")?.intValue { self.month = jval }
        if let jval = (json|"Day")?.intValue { self.day = jval }
        if let jval = (json|"Hour")?.intValue { self.hour = jval }
        if let jval = (json|"Minute")?.intValue { self.minute = jval }
        if let jval = (json|"Second")?.intValue { self.second = jval }
    }
}
