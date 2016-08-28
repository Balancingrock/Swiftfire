// =====================================================================================================================
//
//  File:       AccessLog.swift
//  Project:    Swiftfire
//
//  Version:    0.9.13
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
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.9  - Changed maxsize to 1MB
//         - Renamed FileLog to Logfile.
// v0.9.7  - Initial release
// =====================================================================================================================

import Foundation


final class AccessLog: Logfile {
    
    init?(logDir: URL) {
        super.init(filename: "AccessLog", fileExtension: "csv", directory: logDir, options: .maxFileSize(1024), .newFileDailyAt(WallclockTime(hour: 0, minute: 0, second: 0)))
    }
    
    func record(time: Date, ipAddress: String, url: String, operation: String, version: String) {
        let message = Logfile.dateFormatter.string(from: time) + ", \(ipAddress), \(url), \(operation), \(version)\n"
        super.record(message: message)
    }
    
    override func record(message: String) {
        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Do not use this method")
    }
}
