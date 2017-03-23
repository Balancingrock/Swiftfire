// =====================================================================================================================
//
//  File:       MacCommand.ReadServerTelemetry.swift
//  Project:    Swiftfire
//
//  Version:    0.9.18
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
// 0.9.18 - Header update
//        - Renamed serverStatus to httpServerStatus and added httpsServerStatus
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog
import SwiftfireCore


extension ReadServerTelemetryCommand: MacCommand {
    
    public static func factory(json: VJson?) -> MacCommand? {
        return ReadServerTelemetryCommand(json: json)
    }
    
    public func execute() {
        
        switch telemetryName {
            
        case .nofAcceptedHttpRequests:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptedHttpRequests = \(telemetry.nofAcceptedHttpRequests.intValue)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: telemetry.nofAcceptedHttpRequests.intValue)
            mac?.transfer(reply)
            
            
        case .nofAcceptWaitsForConnectionObject:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptWaitsForConnectionObject = \(telemetry.nofAcceptWaitsForConnectionObject.intValue)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: telemetry.nofAcceptWaitsForConnectionObject.intValue)
            mac?.transfer(reply)
            
            
        case .nofHttp400Replies:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp400Replies = \(telemetry.nofHttp400Replies.intValue)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: telemetry.nofHttp400Replies.intValue)
            mac?.transfer(reply)
            
            
        case .nofHttp500Replies:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp500Replies = \(telemetry.nofHttp500Replies.intValue)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: telemetry.nofHttp500Replies.intValue)
            mac?.transfer(reply)
            
            
        case .httpServerStatus:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, httpServerStatus = \(telemetry.httpServerStatus)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: telemetry.httpServerStatus)
            mac?.transfer(reply)
            
            
        case .httpsServerStatus:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, httpsServerStatus = \(telemetry.httpsServerStatus)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: telemetry.httpsServerStatus)
            mac?.transfer(reply)
            
            
        case .serverVersion:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, Version = \(SWIFTFIRE_VERSION)")
            let reply = ReadServerTelemetryReply(item: telemetryName, value: SWIFTFIRE_VERSION)
            mac?.transfer(reply)
        }
    }
}
