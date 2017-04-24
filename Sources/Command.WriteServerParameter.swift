// =====================================================================================================================
//
//  File:       Command.WriteServerParameter.swift
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
//  Copyright:  (c) 2016-2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.0 - Renamed file from MacCommand to Command
// 0.9.18 - Header update
//        - Replaced log by Log?
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import SwiftfireCore


extension WriteServerParameterCommand: MacCommand {
    
    
    // MARK: - MacCommand protocol
    
    public static func factory(json: VJson?) -> MacCommand? {
        return WriteServerParameterCommand(json: json)
    }
    
    public func execute() {
        
        guard let name = (payload|"Name")?.stringValue else {
            Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Could not read name from item")
            return
        }
        
        guard let value = (payload|"Value")?.asString else {
            Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Could not read value from item")
            return
        }
        
        Log.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Name: \(name), Value: \(value)")
        
        var success = false
        for p in parameters.all {
            if p.name == name {
                let old = p.stringValue
                if p.setValue(value) {
                    Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "\(p.name) updating from \(old) to \(value)")
                    success = true
                } else {
                    Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Failed to update \(p.name) to \(value), cannot convert to necessary type")
                }
                break
            }
        }

        if !success {
            Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Failed to write parameter with json code = \(payload)")
        }
        
    }
    
    
    /// Checks if the networkLogTarget contains two non-empty fields, and if so, tries to connect the logger to the target. After a connection attempt it will empty the fields.
    ///
    /// - Note: It does not report the sucess/failure of the connection attempt.
    ///
    /// - Returns: True if the connection attempt was made, false otherwise.
    
    @discardableResult
    private static func conditionallySetNetworkLogTarget() -> Bool {
        if networkLogTarget.address.isEmpty { return false }
        if networkLogTarget.port.isEmpty { return false }
        Log.theLogger.connectToNetworkTarget(networkLogTarget)
        Log.atNotice?.log(id: -1, source: #file.source(#function, #line), message: "Setting the network logtarget to: \(networkLogTarget.address):\(networkLogTarget.port)")
        networkLogTarget.address = ""
        networkLogTarget.port = ""
        return true
    }
}
