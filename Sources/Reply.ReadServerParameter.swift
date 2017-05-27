// =====================================================================================================================
//
//  File:       Reply.ReadServerParameter.swift
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
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.10.6 - Changed ServerParameterName to ServerParameters.Name
// 0.9.17 - Header update
// 0.9.15 - General update and switch to frameworks
// 0.9.14 - Updated Command & Reply structure
// 0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// 0.9.11 - Updated for VJson 0.9.8
// 0.9.6  - Header update
// 0.9.4  - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation
import Cocoa
import SwifterJSON


private let REPLY_NAME = "ReadServerParameterReply"


/// Contains the value of a requested server parameter.

public final class ReadServerParameterReply: MacMessage {
    

    /// Serialize this object.
    
    public var json: VJson {
        let j = VJson()
        j[REPLY_NAME] &= payload
        return j
    }
    
    
    /// Deserialize an object.
    ///
    /// - Parameter json: The VJson hierarchy to be deserialized.
    
    public init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jpayload = json|REPLY_NAME else { return nil }
        payload = jpayload
    }
    

    /// The name of the server parameter
    
    public var payload: VJson
    
    
    /// Create a new command
    ///
    /// - Parameters:
    ///   - parameter: The name of the server parameter
    ///   - value: The value of the server parameter
    
    public init(parameter: NamedValueProtocol) {
        payload = VJson()
        payload["Name"] &= parameter.name
        payload["Value"] &= parameter.stringValue
    }
}