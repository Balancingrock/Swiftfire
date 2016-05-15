// =====================================================================================================================
//
//  File:       MacDef.swift
//  Project:    Swiftfire
//
//  Version:    0.9.3
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swiftfire.html
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
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
// v0.9.3 - Removed telemetry that has been relocated from the server to the domains
//        - Added command "ReadDomainTelemetry"
// v0.9.0 - Initial release
// =====================================================================================================================

import Foundation

class ReadDomainTelemetryCommand {
    
    static let JSON_ID = "ReadDomainTelemetryCommand"
    
    let domainName: String
    
    var json: VJson {
        let j = VJson.createJsonHierarchy()
        j[ReadDomainTelemetryCommand.JSON_ID].stringValue = domainName
        return j
    }
    
    init?(domainName: String?) {
        guard let domainName = domainName else { return nil }
        self.domainName = domainName
    }
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jdomainName = json.objectOfType(VJson.JType.STRING, atPath: ReadDomainTelemetryCommand.JSON_ID)?.stringValue else { return nil }
        domainName = jdomainName
    }
}

class ReadDomainTelemetryReply {
    
    static let JSON_ID = "ReadDomainTelemetryReply"
    
    var domainName: String
    var domainTelemetry: DomainTelemetry
    
    var json: VJson {
        let jsonTelemetry = domainTelemetry.json("Telemetry")
        let j = VJson.createJsonHierarchy()
        j[ReadDomainTelemetryReply.JSON_ID]["Domain"].stringValue = domainName
        j[ReadDomainTelemetryReply.JSON_ID].addChild(jsonTelemetry)
        return j
    }
    
    init(domainName: String, domainTelemetry: DomainTelemetry) {
        self.domainName = domainName
        self.domainTelemetry = domainTelemetry.duplicate
    }
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jname = json.objectOfType(VJson.JType.STRING, atPath: ReadDomainTelemetryReply.JSON_ID, "Domain")?.stringValue else { return nil }
        guard let jtelemetryJson = json.objectOfType(VJson.JType.OBJECT, atPath: ReadDomainTelemetryReply.JSON_ID, "Telemetry") else { return nil }
        guard let jtelemetry = DomainTelemetry(json: jtelemetryJson) else { return nil }
        
        domainName = jname
        domainTelemetry = jtelemetry
    }
}

class MacDef {

    enum Command: String {
        case READ = "Read"
        case WRITE = "Write"
        case CREATE = "Create"
        case REMOVE = "Remove"
        case UPDATE = "Update"
        case START = "Start"
        case STOP = "Stop"
        case QUIT = "Quit"
        case DELTA = "Delta" // Range 0 .. 10 (i.e. maximum delay is 10 seconds, if more is needed, issue more delta commands.
        case SAVE_PARAMETERS = "SaveParameters"
        case SAVE_DOMAINS = "SaveDomains"
        case RESTORE_PARAMETERS = "RestoreParameters"
        case RESTORE_DOMAINS = "RestoreDomains"
        
        /**
         Creates a VJson item with the specified data included as a JSON type.
         */
        func jsonHierarchyWithValue(value: Any?) -> VJson? {
            
            switch self {
            
            case .READ where value is Parameter:
                let json = VJson.createJsonHierarchy()
                json[self.rawValue].stringValue = (value as! Parameter).rawValue
                return json
                
            case .WRITE, .CREATE, .REMOVE, .UPDATE where value is VJson:
                let json = VJson.createJsonHierarchy()
                json[self.rawValue].addChild((value as! VJson))
                return json
            
            case .START, .STOP, .QUIT, .SAVE_PARAMETERS, .SAVE_DOMAINS, .RESTORE_PARAMETERS, .RESTORE_DOMAINS where value == nil:
                let json = VJson.createJsonHierarchy()
                json[self.rawValue].nullValue = true
                return json
            
            case .DELTA where value is Int:
                let json = VJson.createJsonHierarchy()
                json[self.rawValue].integerValue = (value as! Int)
                return json
            
            default: return nil
            }
        }
    }
    
    enum Parameter: String {
        
        // Read/Write parameters
        case SERVICE_PORT_NUMBER = "ServicePortNumber"
        case MAX_NOF_ACCEPTED_CONNECTIONS = "MaxNofAcceptedConnections"
        case MAX_NOF_PENDING_CONNECTIONS = "MaxNofPendingConnections"
        case MAX_WAIT_FOR_PENDING_CONNECTIONS = "MaxWaitForPendingConnections"
        case MAX_NOF_PENDING_CLIENT_MESSAGES = "MaxNofPendingClientMessages"
        case MAX_CLIENT_MESSAGE_SIZE = "MaxClientMessageSize"
        case DEBUG_MODE = "DebugMode"
        case ASL_LOGLEVEL = "AslLogLevel"
        case STDOUT_LOGLEVEL = "StdoutLogLevel"
        case FILE_LOGLEVEL = "FileLogLevel"
        case CALLBACK_LOGLEVEL = "CallbackLogLevel"
        case NETWORK_LOGLEVEL = "NetworkLogLevel"
        case NETWORK_LOG_TARGET_ADDRESS = "NetworkLogTargetAddress"
        case NETWORK_LOG_TARGET_PORT = "NetworkLogTargetPort"
        
        // Read only parameters
        case VERSION_NUMBER = "VersionNumber"
        case SERVER_STATUS = "ServerStatus"
        case NOF_ACCEPTED_CLIENTS = "NofAcceptedClients"
        case NOF_HTTP_400_REPLIES = "NofHttp400Replies"
        case NOF_HTTP_502_REPLIES = "NofHttp502Replies"
        case DOMAINS = "Domains"
        
        static let all = [SERVICE_PORT_NUMBER, MAX_NOF_ACCEPTED_CONNECTIONS, MAX_NOF_PENDING_CONNECTIONS, MAX_WAIT_FOR_PENDING_CONNECTIONS, MAX_NOF_PENDING_CLIENT_MESSAGES, MAX_CLIENT_MESSAGE_SIZE, DEBUG_MODE, ASL_LOGLEVEL, STDOUT_LOGLEVEL, FILE_LOGLEVEL, CALLBACK_LOGLEVEL, NETWORK_LOGLEVEL, NETWORK_LOG_TARGET_ADDRESS, NETWORK_LOG_TARGET_PORT, VERSION_NUMBER, SERVER_STATUS, NOF_ACCEPTED_CLIENTS, NOF_HTTP_400_REPLIES, NOF_HTTP_502_REPLIES, DOMAINS]
        
        var label: String {
            switch self {
            case SERVICE_PORT_NUMBER: return "HTTP Service Port Number (usually: 80)"
            case MAX_NOF_ACCEPTED_CONNECTIONS: return "Maximum Number of Client Connections in Parallel"
            case MAX_NOF_PENDING_CONNECTIONS: return "Maximum Number of Pending Client Connections"
            case MAX_WAIT_FOR_PENDING_CONNECTIONS: return "Maximum Wait for Pending Client Connections"
            case MAX_NOF_PENDING_CLIENT_MESSAGES: return "Maximum Number of Pending Client Messages"
            case MAX_CLIENT_MESSAGE_SIZE: return "Maximum Size of a Client Message in Bytes"
            case DEBUG_MODE: return "Enable more Debug Information to be Logged"
            case ASL_LOGLEVEL: return "Send Logging at this -and above- level to the ASL Facility"
            case STDOUT_LOGLEVEL: return "Send Logging at this -and above- level to stdout (console)"
            case FILE_LOGLEVEL: return "Send Logging at this -and above- level to the Logfiles"
            case NETWORK_LOGLEVEL: return "Send Logging at this -and above- level to a Network Target"
            case CALLBACK_LOGLEVEL: return "Send Logging at this -and above- level to the Callback Targets"
            case NETWORK_LOG_TARGET_ADDRESS: return "The Network Target IP Address for Logging"
            case NETWORK_LOG_TARGET_PORT: return "The Network Target Port for logging"
            case VERSION_NUMBER: return "The Version Number of Swiftfire"
            case SERVER_STATUS: return "The Status of Swiftfire"
            case NOF_ACCEPTED_CLIENTS: return "The Total Number of Client Connections"
            case NOF_HTTP_400_REPLIES: return "The Total Number of HTTP 400 Errors Generated"
            case NOF_HTTP_502_REPLIES: return "The Total Number of HTTP 502 Errors Generated"
            case DOMAINS: return "Domains"
            }
        }
        
        var toolTip: String {
            switch self {
            case SERVICE_PORT_NUMBER: return "HTTP Service Port Number (usually: 80)"
            case MAX_NOF_ACCEPTED_CONNECTIONS: return "Maximum Number of Client Connections in Parallel"
            case MAX_NOF_PENDING_CONNECTIONS: return "Maximum Number of Pending Client Connections"
            case MAX_WAIT_FOR_PENDING_CONNECTIONS: return "Maximum Wait for Pending Client Connections"
            case MAX_NOF_PENDING_CLIENT_MESSAGES: return "Maximum Number of Pending Client Messages"
            case MAX_CLIENT_MESSAGE_SIZE: return "Maximum Size of a Client Message in Bytes"
            case DEBUG_MODE: return "Enable more Debug Information to be Logged"
            case ASL_LOGLEVEL: return "Send Logging at this -and above- level to the ASL Facility"
            case STDOUT_LOGLEVEL: return "Send Logging at this -and above- level to stdout (console)"
            case FILE_LOGLEVEL: return "Send Logging at this -and above- level to the Logfiles"
            case NETWORK_LOGLEVEL: return "Send Logging at this -and above- level to a Network Target"
            case CALLBACK_LOGLEVEL: return "Send Logging at this -and above- level to the Callback Targets"
            case NETWORK_LOG_TARGET_ADDRESS: return "The Network Target IP Address for Logging"
            case NETWORK_LOG_TARGET_PORT: return "The Network Target Port number for logging"
            case VERSION_NUMBER: return "The Version Number of Swiftfire"
            case SERVER_STATUS: return "The Status of Swiftfire"
            case NOF_ACCEPTED_CLIENTS: return "The Total Number of Client Connections"
            case NOF_HTTP_400_REPLIES: return "The Total Number of HTTP 400 Errors Generated"
            case NOF_HTTP_502_REPLIES: return "The Total Number of HTTP 502 Errors Generated"
            case DOMAINS: return "Domains"
            }
        }

        
        /**
         Creates a JSON type from this parameter with the given value.
         
         - Parameter value: The value for this parameter.

         - Returns: The JSON type created. Returns nil if the supplied value is of the wrong type.
         */
        
        func jsonWithValue(value: Any?) -> VJson? {
            
            switch self {
                
            case SERVICE_PORT_NUMBER, VERSION_NUMBER, SERVER_STATUS, NETWORK_LOG_TARGET_ADDRESS, NETWORK_LOG_TARGET_PORT where value is String:
                
                return VJson.createString(value: (value as! String), name: self.rawValue)
                
                
            case MAX_NOF_ACCEPTED_CONNECTIONS, MAX_NOF_PENDING_CONNECTIONS, MAX_WAIT_FOR_PENDING_CONNECTIONS, MAX_NOF_PENDING_CLIENT_MESSAGES, MAX_CLIENT_MESSAGE_SIZE, ASL_LOGLEVEL, STDOUT_LOGLEVEL, FILE_LOGLEVEL, CALLBACK_LOGLEVEL, NETWORK_LOGLEVEL, NOF_ACCEPTED_CLIENTS, NOF_HTTP_400_REPLIES, NOF_HTTP_502_REPLIES where value is Int:
                
                return VJson.createNumber(value: (value as! Int), name: self.rawValue)
                

            case DEBUG_MODE where value is Bool:
                
                return VJson.createBool(value: (value as! Bool), name: self.rawValue)

            
            case DOMAINS where value is Domains:

                let domains = value as! Domains
                
                let obj = VJson.createArray(name: self.rawValue)
                
                for d in domains {
                    obj.appendChild(d.json)
                }
                
                return obj
            
            
            default: return nil
            }
        }
        
        
        /**
         Retrieves the value for this parameter from the JSON object. Note that the name of the JSON object is not checked.
         
         - Parameter json: The JSON object from which the value should be extracted.
         
         - Returns: The extracted value. Nil if the correct type is not present in the JSON object.
         */

        func valueFromJson(json: VJson?) -> Any? {
            
            switch self {
                
            case SERVICE_PORT_NUMBER, VERSION_NUMBER, SERVER_STATUS, NETWORK_LOG_TARGET_ADDRESS, NETWORK_LOG_TARGET_PORT where ((json?.isString) != nil):
                
                return json!.stringValue
            
                
            case MAX_NOF_ACCEPTED_CONNECTIONS, MAX_NOF_PENDING_CONNECTIONS, MAX_WAIT_FOR_PENDING_CONNECTIONS, MAX_NOF_PENDING_CLIENT_MESSAGES, MAX_CLIENT_MESSAGE_SIZE, ASL_LOGLEVEL, STDOUT_LOGLEVEL, FILE_LOGLEVEL, CALLBACK_LOGLEVEL, NETWORK_LOGLEVEL, NOF_ACCEPTED_CLIENTS, NOF_HTTP_400_REPLIES, NOF_HTTP_502_REPLIES where ((json?.isNumber) != nil):
                
                return json!.integerValue
            
                
            case DEBUG_MODE where ((json?.isBool) != nil):
                
                return json!.boolValue
            
                
            case DOMAINS where ((json?.isObject) != nil):
                
                return json!.arrayValue!
            
                
            default: return nil
            }
        }
        
        
        /**
         Creates a JSON object of this parameter with the value as interpreted from the given String.
         
         - Parameter value: The string to be read and interpreted.
         
         - Returns: The VJson object with name/value as specified in the string . Returns nil if the necessary value cannot be created and for the DOMAINS parameter.
         */
        
        func jsonWithValueFromString(value: String) -> VJson? {
            
            switch self {
                
            case SERVICE_PORT_NUMBER, VERSION_NUMBER, SERVER_STATUS, NETWORK_LOG_TARGET_ADDRESS, NETWORK_LOG_TARGET_PORT:
                
                return jsonWithValue(value)

                
            case MAX_NOF_ACCEPTED_CONNECTIONS, MAX_NOF_PENDING_CONNECTIONS, MAX_WAIT_FOR_PENDING_CONNECTIONS, MAX_NOF_PENDING_CLIENT_MESSAGES, MAX_CLIENT_MESSAGE_SIZE, ASL_LOGLEVEL, STDOUT_LOGLEVEL, FILE_LOGLEVEL, CALLBACK_LOGLEVEL, NETWORK_LOGLEVEL, NOF_ACCEPTED_CLIENTS, NOF_HTTP_400_REPLIES, NOF_HTTP_502_REPLIES:
                
                if let ival = Int(value) {
                    return jsonWithValue(ival)
                } else {
                    return nil
                }
                
                
            case DEBUG_MODE:
                
                if let bval = Bool(value) {
                    return jsonWithValue(bval)
                } else {
                    return nil
                }
            
                
            case DOMAINS:
                
                return nil
            }
        }

        
        /**
         Retrieves the value for this parameter from the JSON OBJECT as a String.
         
         - Parameter json: The JSON OBJECT with a (parameter:value).
         
         - Returns: The value of the JSON object as a String. Nil if the correct type is not present in the JSON object and for the DOMAINS parameter.
         */

        func stringValue(json: VJson) -> String? {
            
            switch self {
            
            case SERVICE_PORT_NUMBER, MAX_NOF_ACCEPTED_CONNECTIONS, MAX_NOF_PENDING_CONNECTIONS, MAX_WAIT_FOR_PENDING_CONNECTIONS, MAX_NOF_PENDING_CLIENT_MESSAGES, MAX_CLIENT_MESSAGE_SIZE, DEBUG_MODE, ASL_LOGLEVEL, STDOUT_LOGLEVEL, FILE_LOGLEVEL, CALLBACK_LOGLEVEL, NETWORK_LOGLEVEL, VERSION_NUMBER, SERVER_STATUS, NOF_ACCEPTED_CLIENTS, NOF_HTTP_400_REPLIES, NOF_HTTP_502_REPLIES, NETWORK_LOG_TARGET_PORT, NETWORK_LOG_TARGET_ADDRESS:
                
                return json.asString
                
                
            case DOMAINS: return nil
            }
        }
        
        
        /**
         - Returns: Nil if the string can be intepreted as a valid value, an error message otherwise.
         */
        
        func validateStringValue(value: String?) -> String? {
            
            guard let v = value else { return "No value present" }
            
            switch self {
            
            case SERVICE_PORT_NUMBER, VERSION_NUMBER, SERVER_STATUS, NETWORK_LOG_TARGET_ADDRESS, NETWORK_LOG_TARGET_PORT:
                
                return nil
                
                
            case MAX_NOF_ACCEPTED_CONNECTIONS, MAX_NOF_PENDING_CONNECTIONS, MAX_WAIT_FOR_PENDING_CONNECTIONS, MAX_NOF_PENDING_CLIENT_MESSAGES, MAX_CLIENT_MESSAGE_SIZE, NOF_ACCEPTED_CLIENTS, NOF_HTTP_400_REPLIES, NOF_HTTP_502_REPLIES:
                
                if let iv = Int(v) {
                    if v == iv.description { return nil }
                    return "Invalid characters in integer"
                } else {
                    return "Cannot convert \(v) to an integer"
                }
                
                
            case ASL_LOGLEVEL, STDOUT_LOGLEVEL, FILE_LOGLEVEL, CALLBACK_LOGLEVEL, NETWORK_LOGLEVEL:
                
                if let iv = Int(v) {
                    if v != iv.description { return "Invalid characters in integer" }
                    if iv < 0 && iv > 8 { return "Level should be in range 0..8" }
                    return nil
                } else {
                    return "Cannot convert \(v) to an integer"
                }

                
            case DEBUG_MODE:
                
                if let _ = Bool(v) {
                    return nil
                } else {
                    return "Cannot convert \(v) to a boolean.\nExpected one of: 0, 1, false, true, no, yes"
                }
                
                
            case DOMAINS:
                
                return nil
            }
        }
        
        static func create(rawValue: String?) -> Parameter? {
            if rawValue == nil { return nil }
            return Parameter(rawValue: rawValue!)
        }
    }
    
    enum CommandRemove: String {
        case DOMAIN = "Domain"
    }
    
    enum CommandCreate: String {
        case DOMAIN = "Domain"
    }
    
    enum CommandUpdate: String {
        case OLD = "Old"
        case NEW = "New"
        case DOMAIN = "Domain"  // Actually the domain resides inside an OLD or NEW object
    }
    
}