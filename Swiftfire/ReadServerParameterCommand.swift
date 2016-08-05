// =====================================================================================================================
//
//  File:       ReadServerParameterCommand.swift
//  Project:    Swiftfire
//
//  Version:    0.9.13
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/Swiftfire
//
//  Copyright:  (c) 2016 Marinus van der Lugt, All rights reserved.
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.11 - Updated for VJson 0.9.8
// v0.9.6  - Header update
// v0.9.4  - Initial release (replaces part of MacDef.swift)
// =====================================================================================================================

import Foundation


private let COMMAND_NAME = "ReadServerParameterCommand"


final class ReadServerParameterCommand {
    
    let parameter: ServerParameter
    
    var json: VJson {
        let j = VJson()
        j[COMMAND_NAME].stringValue = parameter.rawValue
        return j
    }
    
    init?(parameter: ServerParameter?) {
        guard let parameter = parameter else { return nil }
        self.parameter = parameter
    }
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        guard let jname = (json|COMMAND_NAME)?.stringValue else { return nil }
        guard let jparameter = ServerParameter(rawValue: jname) else { return nil }
        parameter = jparameter
    }
    
    func execute() {
        
        func createBoolReply(parameter: ServerParameter, value: Bool) -> VJson {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, \(parameter.rawValue) = \(value)")
            return ReadServerParameterReply(parameter: parameter, value: value).json
        }
        
        func createStringReply(parameter: ServerParameter, value: String) -> VJson {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, \(parameter.rawValue) = \(value)")
            return ReadServerParameterReply(parameter: parameter, value: value).json
        }
        
        func createIntReply(parameter: ServerParameter, value: Int) -> VJson {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, \(parameter.rawValue) = \(value)")
            return ReadServerParameterReply(parameter: parameter, value: value).json
        }
        
        func createDoubleReply(parameter: ServerParameter, value: Double) -> VJson {
            log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Reading, \(parameter.rawValue) = \(value)")
            return ReadServerParameterReply(parameter: parameter, value: value).json
        }

        
        var result: VJson

        switch parameter {
        case .debugMode: result = createBoolReply(parameter: parameter, value: Parameters.debugMode)
        case .autoStartup: result = createBoolReply(parameter: parameter, value: Parameters.autoStartup)
        case .headerLoggingEnabled: result = createBoolReply(parameter: parameter, value: Parameters.headerLoggingEnabled)
        case .flushHeaderLogfileAfterEachWrite: result = createBoolReply(parameter: parameter, value: Parameters.flushHeaderLogfileAfterEachWrite)
        case .servicePortNumber: result = createStringReply(parameter: parameter, value: Parameters.httpServicePortNumber)
        case .macPortNumber: result = createStringReply(parameter: parameter, value: Parameters.macPortNumber)
        case .clienMessageBufferSize: result = createIntReply(parameter: parameter, value: Parameters.clientMessageBufferSize)
        case .httpKeepAliveInactivityTimeout: result = createIntReply(parameter: parameter, value: Parameters.httpKeepAliveInactivityTimeout)
        case .maxNumberOfAcceptedConnections: result = createIntReply(parameter: parameter, value: Parameters.maxNofAcceptedConnections)
        case .maxNumberOfPendingConnections: result = createIntReply(parameter: parameter, value: Int(Parameters.maxNofPendingConnections))
        case .maxWaitForPendingConnections: result = createIntReply(parameter: parameter, value: Parameters.maxWaitForPendingConnections)
        case .logfileMaxNofFiles: result = createIntReply(parameter: parameter, value: log.logfileMaxNumberOfFiles)
        case .logfileMaxSize: result = createIntReply(parameter: parameter, value: Parameters.logfileMaxSize)
        case .maxFileSizeForHeaderLogging: result = createIntReply(parameter: parameter, value: Parameters.maxFileSizeForHeaderLogging)
        case .httpResponseClientTimeout: result = createDoubleReply(parameter: parameter, value: Parameters.httpResponseClientTimeout)
        case .macInactivityTimeout: result = createDoubleReply(parameter: parameter, value: Parameters.macInactivityTimeout)
        case .aslFacilityRecordAtAndAboveLevel: result = createIntReply(parameter: parameter, value: log.aslFacilityRecordAtAndAboveLevel.rawValue)
        case .fileRecordAtAndAboveLevel: result = createIntReply(parameter: parameter, value: log.fileRecordAtAndAboveLevel.rawValue)
        case .stdoutPrintAtAndAboveLevel: result = createIntReply(parameter: parameter, value: log.stdoutPrintAtAndAboveLevel.rawValue)
        case .callbackAtAndAboveLevel: result = createIntReply(parameter: parameter, value: log.callbackAtAndAboveLevel.rawValue)
        case .networkTransmitAtAndAboveLevel: result = createIntReply(parameter: parameter, value: log.networkTransmitAtAndAboveLevel.rawValue)
        case .networkLogtargetIpAddress: result = createStringReply(parameter: parameter, value: log.networkTarget?.address ?? "")
        case .networkLogtargetPortNumber: result = createStringReply(parameter: parameter, value: log.networkTarget?.port ?? "")
        }
        
        toConsole?.transferToConsole(message: result.description)
    }
}
