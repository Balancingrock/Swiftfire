// =====================================================================================================================
//
//  File:       Service.swift
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
import SwifterSockets
import SwifterLog
import Http


/// Services are processes that generate an output and/or side effects from the given input. A domain can have multiple services but they all run sequentially. Each of the services also receives the output of the services that went before it.
///
/// This class maintains a list of services that domains can choose from. This list is populated during startup and remains fixed during server operations.
///
/// To register a service, call the "register" operation in the startup of the main file.

final class Service {
    

    /// This type allows services in the chain to communicate downstream: a service in the chain can give information to downstream services.
    ///
    /// It must be a class to prevent uneccesary copying -or the use of 'UnsafeMutablePointer'- during function processing.
    
    class Info {
        var dict: Dictionary<ServiceInfoKey, CustomStringConvertible> = [:]
        subscript(key: ServiceInfoKey) -> CustomStringConvertible? {
            get { return dict[key] }
            set { dict[key] = newValue }
        }
        init() {}
    }
    

    /// The enum returned by a service
    
    enum Result {
        
        
        /// The nominal case, continue with the next service in the chain.
        
        case next
        
        
        /// When the services should be aborted.
        ///
        /// Note that when an abort is returned, no other service will be called, not even the service that would return a reply to the client.
        
        case abort
    }
    
    
    /// The signature for a service.
    ///
    /// - Parameters:
    ///   - request: The HTTP request that resulted in this service call.
    ///     - payload: The body of the request, will be 'nil' if the body has not been received yet. (Found within 'request')
    ///   - connection: The SFConnection which is used by this request.
    ///   - domain: The domain to be serviced.
    ///   - info: The information dictionary passed along the chain. Can contain parameters for downstream services. Initial contents is a single entry
    ///   - response: The service response from a higher piority service (i.e. earlier in the service chain). The initial response has all items set to nil.
    ///
    /// - Returns: 'true' to continue the service chain, 'false' to abort it. Note: this is designed to abort a service chain in case of errors, but it may be usefull in other situations as well. However normally the service chain is expected to continue from start to finish such that every service gets a chance to perform its intended function. Returning 'false' for non-error cases places conditions on the sequence of services which necessitates proper end user instructions.

    typealias Signature = (_ request: Request, _ connection: SFConnection, _ domain: Domain, _ info: inout Service.Info, _ response: inout Response) -> Service.Result


    /// The combo of name and service
    
    struct Entry {
        public let name: String
        public let service: Signature
        public init(_ name: String, _ service: @escaping Service.Signature) {
            self.name = name
            self.service = service
        }
    }
    
    
    /// The available services

    var registered: Dictionary<String, Service.Entry> = [:]
    
    
    /// Make this class instantiable
    
    init() {}
}


// MARK: - Operational inerface

extension Service {
    
    /// Register a service
    ///
    /// - Parameters:
    ///   - name: The name for the service, this name may not be present in the list already. To replace a service, first remove it.
    ///   - service: The closure that provides the service.
    ///
    /// - Returns: True if the services was added, false if it was already present.

    @discardableResult
    func register(name: String, service: @escaping Service.Signature) -> Bool {
        if registered[name] == nil {
            registered[name] = Entry(name, service)
            return true
        } else {
            return false
        }
    }
}


// MARK: - CustomStringConvertible

extension Service: CustomStringConvertible {
    
    public var description: String {
        var str = "Registered services:\n"
        for (index, service) in registered.enumerated() {
            str += " Service name = \(service.key)"
            if index < (registered.count - 1) { str += "\n" }
        }
        return str
    }
}
