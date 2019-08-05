// =====================================================================================================================
//
//  File:       Logfile.HttpHeaderLogger.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// Description
// =====================================================================================================================
//
// Logs the header from a HTTP request to file. Including the socket (logId) to be able to connect this to the general
// logfile.
//
// =====================================================================================================================

import Foundation
import Http

/// A class to create a log file containing HTTP request headers.

public final class HttpHeaderLogger: Logfile {

    
    /// Creates a new logger.
    ///
    /// - Parameter logDir: A URL pointig at the directory in which to create the logger files.
    
    public init?(logDir: URL?) {
        guard let logDir = logDir else { return nil }
        super.init(name: "HeaderLog", ext: "txt", dir: logDir, options: .newFileDailyAt(WallclockTime(hour: 0, minute: 0, second: 0)), .maxFileSize(serverParameters.maxFileSizeForHeaderLogging.value))
    }

    
    /// Append a log entry for the given header.
    ///
    /// - Parameters:
    ///   - connection: The connection through which the client is connected.
    ///   - request: The request to be added.
    
    public func record(connection: SFConnection, request: Request) {
  
        
        // Create the message
        
        var message = "--------------------------------------------------------------------------------\n"
        message += "Time      : \(dateFormatter.string(from: Date.fromJavaDate(connection.timeOfAccept)))\n"
        message += "IP Address: \(connection.remoteAddress)\n"
        message += "Log Id    : \(connection.logId)\n\n"
        message = request.lines.reduce(message) { $0 + $1 + "\n" }
        message += "\n"
        
        
        record(message: message)
        
        if serverParameters.flushHeaderLogfileAfterEachWrite.value { flush() }
    }
}
