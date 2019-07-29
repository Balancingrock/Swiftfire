// =====================================================================================================================
//
//  File:       Logfile.AccessLog.swift
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


final class AccessLog: Logfile {
    
    public init?(logDir: URL) {
        super.init(name: "AccessLog", ext: "csv", dir: logDir, options: .maxFileSize(1024), .newFileDailyAt(WallclockTime(hour: 0, minute: 0, second: 0)))
    }
    
    public func record(time: Int64, ipAddress: String, url: String, operation: String, version: String) {
        let message = "\(time): \(ipAddress), \(operation), \(url), \(version)\n"
        super.record(message: message)
    }
    
    public override func record(message: String) {
        fatalError("Do not use this method")
    }
}
