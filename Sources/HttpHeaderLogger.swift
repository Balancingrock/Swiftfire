// =====================================================================================================================
//
//  File:       HttpHeaderLogger.swift
//  Project:    Swiftfire
//
//  Version:    0.10.0
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
// 0.10.0 - Renamed HttpConnection to SFConnection
// 0.9.18 - Header update
// 0.9.15 - Initial release
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Logs the header from a HTTP request to file. Including the socket (logId) to be able to connect this to the general
// logfile.
//
// =====================================================================================================================

import Foundation
import SwiftfireCore


/// A class to create a log file containing HTTP request headers.

final class HttpHeaderLogger: Logfile {

    
    /// Creates a new logger.
    ///
    /// - Parameter inDirectory: A URL pointig at the directory in which to create the logger files.
    
    init?(inDirectory url: URL?) {
        guard let url = url else { return nil }
        super.init(name: "HeaderLog", ext: "txt", dir: url, options: .newFileDailyAt(WallclockTime(hour: 0, minute: 0, second: 0)), .maxFileSize(parameters.maxFileSizeForHeaderLogging))
    }

    
    /// Append a log entry for the given header.
    ///
    /// - Parameters:
    ///   - connection: The connection through which the client is connected.
    ///   - header: The header to be added.
    
    func record(connection: SFConnection, header: HttpHeader) {
  
        
        // Create the message
        
        var message = "--------------------------------------------------------------------------------\n"
        message += "Time      : \(Logfile.dateFormatter.string(from: Date.fromJavaDate(connection.timeOfAccept)))\n"
        message += "IP Address: \(connection.remoteAddress)\n"
        message += "Log Id    : \(connection.logId)\n\n"
        message = header.lines.reduce(message) { $0 + $1 + "\n" }
        message += "\n"
        
        
        record(message: message)
        
        if parameters.flushHeaderLogfileAfterEachWrite { flush() }
    }
}
