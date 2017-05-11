// =====================================================================================================================
//
//  File:       Command.UpdateClient.swift
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

private let CLIENT = "Client"
private let NEW_VALUE = "NewValue"
private let COMMAND_NAME = "UpdateClientCommand"


/// Updates the DoNotTrace parameter for a client in the statistics object.

public final class UpdateClientCommand: MacMessage {
    
    
    /// Serialize this object.
    
    public var json: VJson {
        let j = VJson()
        j[COMMAND_NAME][CLIENT] &= client
        j[COMMAND_NAME][NEW_VALUE] &= newValue
        return j
    }
    
    
    /// Deserialize an object.
    ///
    /// - Parameter json: The VJson hierarchy to be deserialized.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jclient = (json|COMMAND_NAME|CLIENT)?.stringValue else { return nil }
        guard let jnewvalue = (json|COMMAND_NAME|NEW_VALUE)?.boolValue else { return nil }
        client = jclient
        newValue = jnewvalue
    }
    
    
    /// The IP Address of the client to be updated.
    
    public var client: String
    
    
    /// The new value for the "DoNotTrace" parameter.
    
    public var newValue: Bool
    
    
    /// Creates a new command.
    ///
    /// - Parameters:
    ///   - client: The IP Address of the client to be updated.
    ///   - newValue: The new value for the "DoNotTrace" parameter.
    
    public init(client: String, newValue: Bool) {
        self.client = client
        self.newValue = newValue
    }
}

extension UpdateClientCommand: MacCommand {
    
    public static func factory(json: VJson?) -> MacCommand? {
        return UpdateClientCommand(json: json)
    }
    
    public func execute() {
        Log.atDebug?.log(id: -1, source: #file.source(#function, #line))
        let mutation = Mutation.createUpdateClient()
        mutation.ipAddress = client
        mutation.doNotTrace = newValue
        statistics.submit(
            
            mutation: mutation,
            
            onSuccess: {
                // Try to signal the console (if any) that the path part is updated
                let message = ReadStatisticsReply(statistics: statistics.json)
                mac?.transfer(message)},
            
            onError: {
                (message: String) in
                Log.atError?.log(id: -1, source: #file.source(#function, #line), message: "Error updating the statistics, message = \(message)")
            }
        )
    }
}
