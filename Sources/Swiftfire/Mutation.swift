// =====================================================================================================================
//
//  File:       Mutation.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2016-2019 Marinus van der Lugt, All rights reserved.
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
import VJson


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

public enum MutationKind: Int16 {
    
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

public final class Mutation {
    
    public static func createAddClientRecord() -> Mutation { return Mutation(kind: .addClientRecord) }
    public static func createUpdatePathPart() -> Mutation { return Mutation(kind: .updatePathPart) }
    public static func createUpdateClient() -> Mutation { return Mutation(kind: .updateClient) }
/*
    public static func createRemoveClientRecords() -> Mutation { return Mutation(kind: .RemoveClientRecords) }
    public static func createRemoveAllClientRecords() -> Mutation { return Mutation(kind: .RemoveAllClientRecords) }
    public static func createRemoveClient() -> Mutation { return Mutation(kind: .RemoveClient) }
    public static func createRemoveAllClients() -> Mutation { return Mutation(kind: .RemoveAllClients) }
    public static func createRemovePathPart() -> Mutation { return Mutation(kind: .RemovePathPart) }
    public static func createRemoveAllPathParts() -> Mutation { return Mutation(kind: .RemoveAllPathParts) }
    public static func createEmptyDatabase() -> Mutation { return Mutation(kind: .EmptyDatabase) }
*/
    
    
    /// Create a new ClientMutation and initialize it with the content from the connection.
    ///
    /// - Parameter from: The HTTP Connection to use for setup.
    ///
    /// - Returns: A partly initialized client mutation.
    
    static func createAddClientRecord(from connection: SFConnection) -> Mutation {
        let mutation = Mutation.createAddClientRecord()
        mutation.ipAddress = connection.remoteAddress
        mutation.connectionAllocationCount = Int32(connection.allocationCount)
        mutation.connectionObjectId = Int16(connection.objectId)
        mutation.socket = Int32(connection.logId)
        return mutation
    }

    
    /// Create a mutation from the given JSON code if possible. Nil otherwise.
    
    public static func mutation(json: VJson?) -> Mutation? {
        
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

    public let kind: MutationKind
    
    
    /// The time of the receipt of the HTTP request using NSDate().javeDate
    
    public var requestReceived: Int64?
    
    
    /// The domain name of the domain the request is for, may be nil if the request did not contain a domain. (This should then be reported in the HttpResponseCode)
    
    public var domain: String?
    
    
    /// The requested URL, may be nil if the request did not contain a url. (This should then be reported in the HttpResponseCode)
    
    public var url: String?
    
    
    /// The result of a request, either OK or an error
    
    public var httpResponseCode: String?
    
    
    /// Further details that could shed a light on why or where an error occured.
    
    public var responseDetails: String?
    
    
    /// A copy of the allocation count of a connection. Helps identifying which log entries are associated with the request.
    
    public var connectionAllocationCount: Int32?
    
    
    /// A copy of the connection object ID. Helps identifying which log entries are associated with the request.

    public var connectionObjectId: Int16?

    
    /// A copy of the socket filedescriptor. Helps identifying which log entries are associated with the request.

    public var socket: Int32?
    
    
    /// Used to update a doNotTrace property.
    
    public var doNotTrace: Bool?
    
    
    /// The address of the client that send the request.
    
    public var ipAddress: String?
    
    
    /// The time of the completion of the HTTP request using NSDate().javaDate

    public var requestCompleted: Int64?
    
    
    /// The JSON hierarchy representing this object.
    
    public var json: VJson {
        
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
