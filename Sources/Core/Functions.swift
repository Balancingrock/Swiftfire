// =====================================================================================================================
//
//  File:       Functions.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Removed inout from the service and function signature
// 1.2.0 - Changed key of functionInfo to string
// 1.0.0 - Raised to v1.0.0, Removed old change log
//
// =====================================================================================================================

import Foundation
import SwifterLog
import VJson
import SwifterSockets
import Http
import Custom


public final class Functions {
    
    
    /// Should it be necessary, the environment holds references to the original request as well as the connection object that is used and the response so far.
    
    public final class Environment {
        
        
        /// Header from the HTTP(S) request
        
        public var request: Request
        
        
        /// The connection. Will in fact always be an SFConnection and can be force cast (as! SFConnection).
        ///
        /// Visibility rules prevent the use of SFConnection as the type.
        
        public var connection: SFConnection
        
        
        /// The domain for which the function is called.
        
        public var domain: Domain
        
        
        /// The response for the HTTP(S) request (may be empty still, depends on previous services)
        
        public var response: Response
        
        
        /// The service chain info object.
        
        public var serviceInfo: Services.Info
        
        
        /// Create a new instance
        ///
        /// - Note: the connection must in fact be an SFConnection.
        
        public init(request: Request, connection: SFConnection, domain: Domain, response: Response, serviceInfo: Services.Info) {
            self.request = request
            self.connection = connection
            self.domain = domain
            self.response = response
            self.serviceInfo = serviceInfo
        }
        
        
        /// Creates a new session with the data contained in the environment
        
        public func newSession() -> Session? {
            
            return domain.sessions.newSession(
                address: connection.remoteAddress,
                domainName: domain.name,
                logId: connection.logId,
                connectionId: connection.objectId,
                allocationCount: connection.allocationCount,
                timeout: domain.sessionTimeout
            )
        }
    }
    
    
    /// The arguments to the function can be an array or a VJson object.
    /// The array elements can only be String items.
    /// All other strings will be String.
    /// Note that it is not necessary to put quotes on a string unless it should contain blanks.
    
    public typealias ArrayArguments = Array<String>
    typealias VJsonArgument = VJson
    
    
    /// This enum ecapsulates the function arguments
    
    public enum Arguments: CustomStringConvertible {
        case arrayOfString(ArrayArguments)
        case json(VJson)
        
        public var description: String {
            switch self {
            case .arrayOfString(let arr): return "Array with \(arr.count) items"
            case .json: return "JSON Object"
            }
        }
    }
    
    
    /// The type used to transfer data between function calls.
    
    public typealias Info = Dictionary<String, Any>
    
    
    /// The signature of the "Insert Content Here" function calls
    
    public typealias Signature = (_ args: Functions.Arguments, _ info: inout Functions.Info, _ environment: Functions.Environment) -> Data?

    
    /// The combo of name and function
    
    public struct Entry {
        let name: String
        let function: Functions.Signature
        init(_ name: String, _ function: @escaping Functions.Signature) {
            self.name = name
            self.function = function
        }
    }
    
    
    /// The available functions
    
    public var registered: Dictionary<String, Functions.Entry> = [:]
    
    
    /// Make this class instantiable
    
    public init() {}
}


// MARK: - Operational

extension Functions {
    
    
    /// Register a function
    ///
    /// - Parameters:
    ///   - name: The name for the function, this name may not be present in the list already. To replace a function, first remove it.
    ///   - function: The closure that provides the function.
    ///
    /// - Returns: True if the function was added, false if it was already present.
    
    @discardableResult
    public func register(name: String, function: @escaping Functions.Signature) -> Bool {
        if registered[name] == nil {
            registered[name] = Entry(name, function)
            return true
        } else {
            return false
        }
    }
}


// MARK: - CustomStringConvertible

extension Functions: CustomStringConvertible {
    
    public var description: String {
        var str = "Registered functions:\n"
        for (index, function) in registered.enumerated() {
            str += " Function name = \(function.key)"
            if index < (registered.count - 1) { str += "\n" }
        }
        return str
    }
}
