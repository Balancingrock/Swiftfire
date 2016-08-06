// =====================================================================================================================
//
//  File:       ReadServerTelemetryCommand.swift
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
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.11 - Updated for VJson 0.9.8
// v0.9.6  - Header update
// v0.9.4  - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation


private let COMMAND_NAME = "ReadServerTelemetryCommand"


final class ReadServerTelemetryCommand {
    
    let telemetryItem: ServerTelemetryItem
    
    var json: VJson {
        let j = VJson()
        j[COMMAND_NAME].stringValue = telemetryItem.rawValue
        return j
    }
    
    init?(telemetryItem: ServerTelemetryItem?) {
        guard let telemetryItem = telemetryItem else { return nil }
        self.telemetryItem = telemetryItem
    }
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jname = (json|COMMAND_NAME)?.stringValue else { return nil }
        guard let jtelemetryItem = ServerTelemetryItem(rawValue: jname) else { return nil }
        telemetryItem = jtelemetryItem
    }
    
    
    func execute() {
        
        switch telemetryItem {
            
            
        case .nofAcceptedHttpRequests:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptedHttpRequests = \(serverTelemetry.nofAcceptedHttpRequests.intValue)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: serverTelemetry.nofAcceptedHttpRequests.intValue)
            
            toConsole?.transferToConsole(message: reply.json.description)
            
            
        case .nofAcceptWaitsForConnectionObject:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofAcceptWaitsForConnectionObject = \(serverTelemetry.nofAcceptWaitsForConnectionObject.intValue)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: serverTelemetry.nofAcceptWaitsForConnectionObject.intValue)
            
            toConsole?.transferToConsole(message: reply.json.description)
            
            
        case .nofHttp400Replies:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp400Replies = \(serverTelemetry.nofHttp400Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: serverTelemetry.nofHttp400Replies.intValue)
            
            toConsole?.transferToConsole(message: reply.json.description)
            
            
        case .nofHttp500Replies:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp500Replies = \(serverTelemetry.nofHttp500Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: serverTelemetry.nofHttp500Replies.intValue)
            
            toConsole?.transferToConsole(message: reply.json.description)
            
            
        case .nofHttp502Replies:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, telemetry.nofHttp502Replies = \(serverTelemetry.nofHttp502Replies.intValue)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: serverTelemetry.nofHttp502Replies.intValue)
            
            toConsole?.transferToConsole(message: reply.json.description)
            
            
        case .serverStatus:
            
            let rs = httpServerIsRunning()
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, at_RunningStatus = \(rs)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: (rs ? "Running" : "Not Running"))
            
            toConsole?.transferToConsole(message: reply.json.description)
            
            
        case .serverVersion:
            
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, ap_Version = \(Parameters.version)")
            
            let reply = ReadServerTelemetryReply(item: telemetryItem, value: Parameters.version)
            
            toConsole?.transferToConsole(message: reply.json.description)
        }
    }
}
