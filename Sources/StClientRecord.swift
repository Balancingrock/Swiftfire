// =====================================================================================================================
//
//  File:       StClientRecord.swift
//  Project:    SwiftfireCore
//
//  Version:    0.10.5
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2017 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// 0.10.5 - Bugfix, host, url. response code, response details can be nil
//        - Added debug output.
// 0.9.17 - Header update
// 0.9.15 - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog


/// Collects all data from a single client access.

public final class StClientRecord: VJsonConvertible {

    
    /// The connection allocation count, this is for debug purposes
    
    public var connectionAllocationCount: Int32
    
    
    /// The connection object id, this is for debug purposes
    
    public var connectionObjectId: Int16
    
    
    /// The name of the host (i.e. domain name)
    
    public var host: String?
    
    
    /// The result of the request
    
    public var httpResponseCode: String?
    
    
    /// The time the request was completed (msec resolution)
    
    public var requestCompleted: Int64
    
    
    /// The time the request was received (msec resolution)
    
    public var requestReceived: Int64
    
    
    /// Any additional info
    
    public var responseDetails: String?
    
    
    /// The socket on which he request was served, for debug purposes
    
    public var socket: Int32
    
    
    /// The complete URL that was served
    
    public var url: String?
    
    
    /// The VJson hierarchy representing this object.
    
    public var json: VJson {
        let json = VJson()
        json["a"] &= connectionAllocationCount
        json["c"] &= connectionObjectId
        json["o"] &= host
        json["h"] &= httpResponseCode
        json["d"] &= requestCompleted
        json["r"] &= requestReceived
        json["t"] &= responseDetails
        json["s"] &= socket
        json["u"] &= url
        return json
    }
    
    
    /// Recreates an object from the given VJson hierarchy
    
    public init?(json: VJson?) {
        
        guard let json = json else { return nil }
        
        guard let jConnectionAllocationCount = (json|"a")?.int32Value else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read allocation count 'a'")
            return nil
        }
        
        guard let jConnectionObjectId = (json|"c")?.int16Value else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read object id 'c'")
            return nil }
        
        guard let jHost = json|"o" else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read host 'o'")
            return nil }
        
        guard let jHttpResponseCode = json|"h" else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read response code 'h'")
            return nil }
        
        guard let jRequestCompleted = (json|"d")?.int64Value else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read request completed 'd'")
            return nil }
        
        guard let jRequestReceived = (json|"r")?.int64Value else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read request received 'r'")
            return nil }
        
        guard let jResponseDetails = json|"t" else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read response details 't'")
            return nil }
        
        guard let jSocket = (json|"s")?.int32Value else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read socket 's'")
            return nil }
        
        guard let jUrl = json|"u" else {
            SwifterLog.atDebug?.log(id: -1, source: #file.source(#function, #line), message: "Could not read url 'u'")
            return nil }
        
        self.connectionAllocationCount = jConnectionAllocationCount
        self.connectionObjectId = jConnectionObjectId
        self.host = jHost.stringValue
        self.httpResponseCode = jHttpResponseCode.stringValue
        self.requestCompleted = jRequestCompleted
        self.requestReceived = jRequestReceived
        self.responseDetails = jResponseDetails.stringValue
        self.socket = jSocket
        self.url = jUrl.stringValue
    }

    
    /// Creates a new object
    
    public init(connectionObjectId: Int16, connectionAllocationCount: Int32, host: String?, requestReceived: Int64, requestCompleted: Int64, httpResponseCode: String?, responseDetails: String?, socket: Int32, url: String?) {
        
        self.connectionAllocationCount = connectionAllocationCount
        self.connectionObjectId = connectionObjectId
        self.host = host
        self.httpResponseCode = httpResponseCode
        self.requestCompleted = requestCompleted
        self.requestReceived = requestReceived
        self.responseDetails = responseDetails
        self.socket = socket
        self.url = url
    }
}
