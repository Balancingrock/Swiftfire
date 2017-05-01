//
//  ServerParameters.DidSetActions.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 24/04/17.
//
//

import Foundation
import SwifterLog


func setupParametersDidSetActions() {
    
    parameters.aslFacilityRecordAtAndAboveLevel.addDidSetAction {
        if let level = Log.Level(rawValue: parameters.aslFacilityRecordAtAndAboveLevel.value) {
            Log.theLogger.aslFacilityRecordAtAndAboveLevel = level
        } else {
            Log.atError?.log(id: -1, source: "ServerParameters.DidSetActions", message: "Cannot create loglevel from \(parameters.aslFacilityRecordAtAndAboveLevel.value) for aslFacilityRecordAtAndAboveLevel")
        }
    }
    
    parameters.fileRecordAtAndAboveLevel.addDidSetAction {
        if let level = Log.Level(rawValue: parameters.fileRecordAtAndAboveLevel.value) {
            Log.theLogger.fileRecordAtAndAboveLevel = level
        } else {
            Log.atError?.log(id: -1, source: "ServerParameters.DidSetActions", message: "Cannot create loglevel from \(parameters.fileRecordAtAndAboveLevel.value) for fileRecordAtAndAboveLevel")
        }
    }
    
    parameters.callbackAtAndAboveLevel.addDidSetAction {
        if let level = Log.Level(rawValue: parameters.callbackAtAndAboveLevel.value) {
            Log.theLogger.callbackAtAndAboveLevel = level
        } else {
            Log.atError?.log(id: -1, source: "ServerParameters.DidSetActions", message: "Cannot create loglevel from \(parameters.callbackAtAndAboveLevel.value) for callbackAtAndAboveLevel")
        }
    }
    
    parameters.stdoutPrintAtAndAboveLevel.addDidSetAction {
        if let level = Log.Level(rawValue: parameters.stdoutPrintAtAndAboveLevel.value) {
            Log.theLogger.stdoutPrintAtAndAboveLevel = level
        } else {
            Log.atError?.log(id: -1, source: "ServerParameters.DidSetActions", message: "Cannot create loglevel from \(parameters.stdoutPrintAtAndAboveLevel.value) for stdoutPrintAtAndAboveLevel")
        }
    }
    
    parameters.networkTransmitAtAndAboveLevel.addDidSetAction {
        if let level = Log.Level(rawValue: parameters.networkTransmitAtAndAboveLevel.value) {
            Log.theLogger.networkTransmitAtAndAboveLevel = level
        } else {
            Log.atError?.log(id: -1, source: "ServerParameters.DidSetActions", message: "Cannot create loglevel from \(parameters.networkTransmitAtAndAboveLevel.value) for networkTransmitAtAndAboveLevel")
        }
    }
}
