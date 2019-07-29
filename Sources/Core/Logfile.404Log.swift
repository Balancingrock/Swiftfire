// =====================================================================================================================
//
//  File:       Logfile.404Log.swift
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


/// This class is intended to collect all HTTP 404 replies. It will count each occurence only once.

final class Four04Log: Logfile {

    
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
    
    override func record(message: String) {
        for str in reported {
            if str == message { return }
        }
        reported.append(message)
        super.record(message: message + "\n")
        super.flush()
    }
}
