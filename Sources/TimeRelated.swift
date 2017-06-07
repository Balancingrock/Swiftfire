// =====================================================================================================================
//
//  File:       TimeRelated.swift
//  Project:    BRUtils
//
//  Version:    0.5.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
// 0.5.0 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// General purpose time related utilities.
//
// =====================================================================================================================

import Foundation


public extension timespec {

    /// Create a timespec (nsec resolution) from a TimeInterval.
    
    public init(_ timeInterval: TimeInterval) {
        let sec = Int(timeInterval)
        let nsec = Int((timeInterval - Double(sec)) * Double(NSEC_PER_SEC))
        self.init(tv_sec: sec, tv_nsec: nsec)
    }
}

public extension timeval {
    
    /// Create a timeval (usec resolution) from a TimeInterval.

    public init(_ timeInterval: TimeInterval) {
        let sec = Int(timeInterval)
        let usec = Int32((timeInterval - Double(sec)) * Double(USEC_PER_SEC))
        self.init(tv_sec: sec, tv_usec: usec)
    }
}

public extension TimeInterval {
    
    /// Create a TimeInterval from a timespec (nsec resolution)
    
    public init(_ spec: timespec) {
        self.init(Double(spec.tv_sec) + (Double(spec.tv_nsec) / Double(NSEC_PER_SEC)))
    }
}

public extension TimeInterval {
    
    /// Create a TimeInterval from a timespec (usec resolution)

    public init(_ val: timeval) {
        self.init(Double(val.tv_sec) + (Double(val.tv_usec) / Double(USEC_PER_SEC)))
    }
}


/// A wrapper for the POSIX call 'nanosleep'
///
/// - Parameter duration: The time to suspend the current thread.
/// - Returns: nil if the delay was successful or the remaining time that has not expired yet.

public func sleep(_ duration: TimeInterval) -> TimeInterval? {

    var requested = timespec(duration)
    var remainder: timespec = timespec()

    if nanosleep(&requested, &remainder) != 0 {
        return TimeInterval(remainder)
    } else {
        return nil
    }
}
