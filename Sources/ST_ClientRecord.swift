//
//  ST_ClientRecord.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON


/// Collects all data from a single client access.

final class ST_ClientRecord: VJsonConvertible {

    
    /// The connection allocation count, this is for debug purposes
    
    var connectionAllocationCount: Int32
    
    
    /// The connection object id, this is for debug purposes
    
    var connectionObjectId: Int16
    
    
    /// The name of the host (i.e. domain name)
    
    var host: String?
    
    
    /// The result of the request
    
    var httpResponseCode: String?
    
    
    /// The time the request was completed (msec resolution)
    
    var requestCompleted: Int64
    
    
    /// The time the request was received (msec resolution)
    
    var requestReceived: Int64
    
    
    /// Any additional info
    
    var responseDetails: String?
    
    
    /// The socket on which he request was served, for debug purposes
    
    var socket: Int32
    
    
    /// The complete URL that was served
    
    var url: String?
    
    
    /// The VJson hierarchy representing this object.
    
    var json: VJson {
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
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jConnectionAllocationCount = (json|"a")?.int32Value else { return nil }
        guard let jConnectionObjectId = (json|"c")?.int16Value else { return nil }
        guard let jHost = (json|"o")?.stringValue else { return nil }
        guard let jHttpResponseCode = (json|"h")?.stringValue else { return nil }
        guard let jRequestCompleted = (json|"d")?.int64Value else { return nil }
        guard let jRequestReceived = (json|"r")?.int64Value else { return nil }
        guard let jResponseDetails = (json|"t")?.stringValue else { return nil }
        guard let jSocket = (json|"s")?.int32Value else { return nil }
        guard let jUrl = (json|"u")?.stringValue else { return nil }
        
        self.connectionAllocationCount = jConnectionAllocationCount
        self.connectionObjectId = jConnectionObjectId
        self.host = jHost
        self.httpResponseCode = jHttpResponseCode
        self.requestCompleted = jRequestCompleted
        self.requestReceived = jRequestReceived
        self.responseDetails = jResponseDetails
        self.socket = jSocket
        self.url = jUrl
        
        return nil
    }

    
    /// Creates a new object
    
    init(connectionObjectId: Int16, connectionAllocationCount: Int32, host: String?, requestReceived: Int64, requestCompleted: Int64, httpResponseCode: String?, responseDetails: String?, socket: Int32, url: String?) {
        
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
