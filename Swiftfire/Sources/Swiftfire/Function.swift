// =====================================================================================================================
//
//  File:       Function.swift
//  Project:    Swiftfire
//
//  Version:    1.0.0
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
// 1.0.0 Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation
import SwifterLog
import VJson
import SwifterSockets
import Http


final class Function {
    
    
    /// Should it be necessary, the environment holds references to the original request as well as the connection object that is used and the response so far.
    
    final class Environment {
        
        
        /// Header from the HTTP(S) request
        
        var request: Request
        
        
        /// The connection. Will in fact always be an SFConnection and can be force cast (as! SFConnection).
        ///
        /// Visibility rules prevent the use of SFConnection as the type.
        
        var connection: SFConnection
        
        
        /// The domain for which the function is called.
        
        var domain: Domain
        
        
        /// The response for the HTTP(S) request (may be empty still, depends on previous services)
        
        var response: Response
        
        
        /// The service chain info object.
        
        var serviceInfo: Service.Info
        
        
        /// Create a new instance
        ///
        /// - Note: the connection must in fact be an SFConnection.
        
        init(request: Request, connection: SFConnection, domain: Domain, response: inout Response, serviceInfo: inout Service.Info) {
            self.request = request
            self.connection = connection
            self.domain = domain
            self.response = response
            self.serviceInfo = serviceInfo
        }
        
        
        /// Creates a new session with the data contained in the environment
        
        func newSession() -> Session? {
            
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
    
    typealias ArrayArguments = Array<String>
    typealias VJsonArgument = VJson
    
    
    /// This enum ecapsulates the function arguments
    
    enum Arguments: CustomStringConvertible {
        case array(ArrayArguments)
        case json(VJson)
        
        var description: String {
            switch self {
            case .array(let arr): return "Array with \(arr.count) items"
            case .json: return "JSON Object"
            }
        }
    }
    
    
    /// The type used to transfer data between function calls.
    
    typealias Info = Dictionary<FunctionInfoKey, Any>
    
    
    /// The signature of the "Insert Content Here" function calls
    
    typealias Signature = (_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data?

    
    /// The combo of name and function
    
    struct Entry {
        let name: String
        let function: Function.Signature
        init(_ name: String, _ function: @escaping Function.Signature) {
            self.name = name
            self.function = function
        }
    }
    
    
    /// The available functions
    
    var registered: Dictionary<String, Function.Entry> = [:]
    
    
    /// Make this class instantiable
    
    init() {}
}


// MARK: - Operational

extension Function {
    
    
    /// Register a function
    ///
    /// - Parameters:
    ///   - name: The name for the function, this name may not be present in the list already. To replace a function, first remove it.
    ///   - function: The closure that provides the function.
    ///
    /// - Returns: True if the function was added, false if it was already present.
    
    @discardableResult
    func register(name: String, function: @escaping Function.Signature) -> Bool {
        if registered[name] == nil {
            registered[name] = Entry(name, function)
            return true
        } else {
            return false
        }
    }
}


// MARK: - CustomStringConvertible

extension Function: CustomStringConvertible {
    
    var description: String {
        var str = "Registered functions:\n"
        for (index, function) in registered.enumerated() {
            str += " Function name = \(function.key)"
            if index < (registered.count - 1) { str += "\n" }
        }
        return str
    }
}
