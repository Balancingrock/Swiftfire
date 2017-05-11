// =====================================================================================================================
//
//  File:       Logfile.404Log.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks, SwiftfireCore split.
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.9  - Renamed FileLog to Logfile.
//        - Lowered maxsize of file to 1MB
//        - Fixed bug where a 404 URL would occur more than once and missing line breaks in the logfile
// 0.9.7  - Initial release
// =====================================================================================================================

import Foundation


/// This class is intended to collect all HTTP 404 replies. It will count each occurence only once.

public final class Four04Log: Logfile {

    
    /// This list conatins all 404 error's so far.
    
    public private(set) var reported: Array<String> = Array()
    
    
    /// Create a new logfile for 404 occurances.
    ///
    /// - Parameter logDir: A URL of the directory in which to create the logfile.
    
    public init?(logDir: URL) {
        super.init(name: "404Log", dir: logDir, options: .maxFileSize(1024))
    }
    
    
    /// Records the given string in the log unless it has already been recorded.
    ///
    /// - Parameter message: The URL of the request that caused the 404 reply.
    
    override public func record(message: String) {
        for str in reported {
            if str == message { return }
        }
        reported.append(message)
        super.record(message: message + "\n")
        super.flush()
    }
}
