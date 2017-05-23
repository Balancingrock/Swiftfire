// =====================================================================================================================
//
//  File:       Function.swift
//  Project:    Swiftfire
//
//  Version:    0.10.6
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
// 0.10.6 - Updated Service.Response type to HttpResponse type
//        - Renamed InfoKey to FunctionInfoKey and moved definition to new file.
// 0.10.0 - Initial release
//
// =====================================================================================================================

import Foundation
import SwifterLog
import SwifterJSON
import SwifterSockets


public final class Function: CustomStringConvertible {
    
    
    /// Should it be necessary, the environment holds references to the original request as well as the connection object that is used and the response so far.
    
    public final class Environment {
        
        
        /// Header from the HTTP(S) request
        
        public var request: HttpRequest
        
        
        /// The connection. Will in fact always be an SFConnection and can be force cast (as! SFConnection).
        ///
        /// Visibility rules prevent the use of SFConnection as the type.
        
        public var connection: Connection
        
        
        /// The domain for which the function is called.
        
        public var domain: Domain
        
        
        /// The response for the HTTP(S) request (may be empty still, depends on previous services)
        
        public var response: HttpResponse
        
        
        /// The service chain info object.
        
        public var serviceInfo: Service.Info
        
        
        /// Create a new instance
        ///
        /// - Note: the connection must in fact be an SFConnection.
        
        public init(request: HttpRequest, connection: Connection, domain: Domain, response: inout HttpResponse, serviceInfo: inout Service.Info) {
            self.request = request
            self.connection = connection
            self.domain = domain
            self.response = response
            self.serviceInfo = serviceInfo
        }
    }
    
    
    /// The arguments to the function can be an array or a VJson object.
    /// The array elements can only be String items.
    /// All other strings will be String.
    /// Note that it is not necessary to put quotes on a string unless it should contain blanks.
    
    public typealias ArrayArguments = Array<String>
    public typealias VJsonArgument = VJson
    
    
    /// This enum ecapsulates the function arguments
    
    public enum Arguments: CustomStringConvertible {
        case array(ArrayArguments)
        case json(VJson)
        
        public var description: String {
            switch self {
            case .array(let arr): return "Array with \(arr.count) items"
            case .json: return "JSON Object"
            }
        }
    }
    
    
    /// The type used to transfer data between function calls.
    
    public typealias Info = Dictionary<FunctionInfoKey, Any>
    
    
    /// The signature of the "Insert Content Here" function calls
    
    public typealias Signature = (_ args: Function.Arguments, _ info: inout Function.Info, _ environment: inout Function.Environment) -> Data?

    
    /// The combo of name and function
    
    public struct Entry {
        public let name: String
        public let function: Function.Signature
        public init(_ name: String, _ function: @escaping Function.Signature) {
            self.name = name
            self.function = function
        }
    }
    
    
    /// The available functions
    
    public var registered: Dictionary<String, Function.Entry> = [:]
    
    
    /// Make this class instantiable
    
    public init() {}
    
    
    /// Register a function
    ///
    /// - Parameters:
    ///   - name: The name for the function, this name may not be present in the list already. To replace a function, first remove it.
    ///   - function: The closure that provides the function.
    ///
    /// - Returns: True if the function was added, false if it was already present.
    
    @discardableResult
    public func register(name: String, function: @escaping Function.Signature) -> Bool {
        if registered[name] == nil {
            registered[name] = Entry(name, function)
            return true
        } else {
            return false
        }
    }
    
    /// Print the names of the registered functions to a string
    
    public var description: String {
        var str = "Registered functions:\n"
        for (index, function) in registered.enumerated() {
            str += " Function name = \(function.key)"
            if index < (registered.count - 1) { str += "\n" }
        }
        return str
    }
}
