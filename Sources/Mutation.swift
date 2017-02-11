// =====================================================================================================================
//
//  File:       Mutation.swift
//  Project:    Swiftfire
//
//  Version:    0.9.15
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
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
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
// v0.9.15 - General update and switch to frameworks
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Added support for UpdatePathPart and UpdateClient
//         - Switched time intervals to javaDate (Int64)
// v0.9.11 - Initial release
// =====================================================================================================================

import Foundation
import SwifterJSON


// Definitions for JSON code

private let KIND = "Kind"
private let REQUEST_RECEIVED = "RequestReceived"
private let DOMAIN = "Domain"
private let URLSTR = "URL"
private let HTTP_RESPONSE_CODE = "HttpResponseCode"
private let RESPONSE_DETAILS = "ResponseDetails"
private let CONNECTION_ALLOCATION_COUNT = "ConnectionAllocationCount"
private let CONNECTION_OBJECT_ID = "ConnectionObjectId"
private let SOCKET = "Socket"
private let DO_NOT_TRACE = "DoNotTrace"
private let CLIENT = "Client"
private let REQUEST_COMPLETED = "RequestCompleted"


/// The kinds of mutations

enum MutationKind: Int16 {
    
    /// Adds a client record to the data store.
    /// - Note: The following fields must be filled in before submitting: requestCompleted, requestReceived, httpResponseCode, responseDetails, connectionAllocationCount, connectionObjectId, socket. Other fields are optional.
    
    case addClientRecord = 0
    case updatePathPart
    case updateClient
    
/*    case RemoveClientRecords
    case RemoveAllClientRecords
    case RemoveClient
    case RemoveAllClients
    case RemovePathPart
    case RemoveAllPathParts
    case EmptyDatabase
*/
}

class Mutation {
    
    static func createAddClientRecord() -> Mutation { return Mutation(kind: .addClientRecord) }
    static func createUpdatePathPart() -> Mutation { return Mutation(kind: .updatePathPart) }
    static func createUpdateClient() -> Mutation { return Mutation(kind: .updateClient) }
/*
    static func createRemoveClientRecords() -> Mutation { return Mutation(kind: .RemoveClientRecords) }
    static func createRemoveAllClientRecords() -> Mutation { return Mutation(kind: .RemoveAllClientRecords) }
    static func createRemoveClient() -> Mutation { return Mutation(kind: .RemoveClient) }
    static func createRemoveAllClients() -> Mutation { return Mutation(kind: .RemoveAllClients) }
    static func createRemovePathPart() -> Mutation { return Mutation(kind: .RemovePathPart) }
    static func createRemoveAllPathParts() -> Mutation { return Mutation(kind: .RemoveAllPathParts) }
    static func createEmptyDatabase() -> Mutation { return Mutation(kind: .EmptyDatabase) }
*/
    
    
    /// Create a mutation from the given JSON code if possible. Nil otherwise.
    
    static func mutation(json: VJson?) -> Mutation? {
        
        guard let json = json else { return nil }
        guard let jkindInt = (json|KIND)?.int16Value else { return nil }
        guard let jkind = MutationKind(rawValue: jkindInt) else { return nil }
        
        
        let mutation = Mutation(kind: jkind)
        
        if let tmp = (json|REQUEST_RECEIVED)?.int64Value {
            mutation.requestReceived = tmp
        }
        mutation.domain = (json|DOMAIN)?.stringValue
        mutation.url = (json|URLSTR)?.stringValue
        mutation.httpResponseCode = (json|HTTP_RESPONSE_CODE)?.stringValue
        mutation.responseDetails = (json|RESPONSE_DETAILS)?.stringValue
        
        if let val = (json|CONNECTION_ALLOCATION_COUNT)?.int32Value {
            mutation.connectionAllocationCount = val
        }
        
        if let val = (json|CONNECTION_OBJECT_ID)?.int16Value {
            mutation.connectionObjectId = val
        }
        
        if let val = (json|SOCKET)?.int32Value {
            mutation.socket = val
        }
        
        mutation.doNotTrace = (json|DO_NOT_TRACE)?.boolValue
        mutation.ipAddress = (json|CLIENT)?.stringValue
        if let tmp = (json|REQUEST_COMPLETED)?.int64Value {
            mutation.requestCompleted = tmp
        }
        
        return mutation
    }

    let kind: MutationKind
    
    
    /// The time of the receipt of the HTTP request using NSDate().javeDate
    
    var requestReceived: Int64?
    
    
    /// The domain name of the domain the request is for, may be nil if the request did not contain a domain. (This should then be reported in the HttpResponseCode)
    
    var domain: String?
    
    
    /// The requested URL, may be nil if the request did not contain a url. (This should then be reported in the HttpResponseCode)
    
    var url: String?
    
    
    /// The result of a request, either OK or an error
    
    var httpResponseCode: String?
    
    
    /// Further details that could shed a light on why or where an error occured.
    
    var responseDetails: String?
    
    
    /// A copy of the allocation count of a connection. Helps identifying which log entries are associated with the request.
    
    var connectionAllocationCount: Int32?
    
    
    /// A copy of the connection object ID. Helps identifying which log entries are associated with the request.

    var connectionObjectId: Int16?

    
    /// A copy of the socket filedescriptor. Helps identifying which log entries are associated with the request.

    var socket: Int32?
    
    
    /// Used to update a doNotTrace property.
    
    var doNotTrace: Bool?
    
    
    /// The address of the client that send the request.
    
    var ipAddress: String?
    
    
    /// The time of the completion of the HTTP request using NSDate().javaDate

    var requestCompleted: Int64?
    
    
    /// The JSON hierarchy representing this object.
    
    var json: VJson {
        
        let json = VJson()
        
        json[KIND] &= kind.rawValue
        json[REQUEST_RECEIVED] &= requestReceived
        json[DOMAIN] &= domain
        json[URLSTR] &= url
        json[HTTP_RESPONSE_CODE] &= httpResponseCode
        json[RESPONSE_DETAILS] &= responseDetails
        json[CONNECTION_ALLOCATION_COUNT] &= connectionAllocationCount
        json[CONNECTION_OBJECT_ID] &= connectionObjectId
        json[SOCKET] &= socket
        json[DO_NOT_TRACE] &= doNotTrace
        json[CLIENT] &= ipAddress
        json[REQUEST_COMPLETED] &= requestCompleted
        
        return json
    }
    
    
    // Enforces use of the factory operations
    
    private init(kind: MutationKind) {
        self.kind = kind
    }
}
