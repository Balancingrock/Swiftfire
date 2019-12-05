// =====================================================================================================================
//
//  File:       Services.SF.Registration.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provisions:
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
// 1.3.0 - Removed serviceName_DecodePostFormUrlEncoded
// 1.1.0 - Fixed loading & storing of domain service names
// 1.0.0 - Initial version
//
// =====================================================================================================================

import Foundation

import Core
import Services


// ==============================================
// Descriptions for the available domain services
// ==============================================

// Note: If any of these texts are changed it will be necessary to re-assign new services for existing domains.

private let serverAdmin = "Handle server Admin Domain"


// =================================================
// Add to the next function to register new services
// =================================================
// Notice that the sequence itself is not important

/// Register the admin related domain services

public func sfRegisterServices() {
    services.register(name: serverAdmin, service: service_serverAdmin)
}


/// The services for the server admin (pseudo) domain

public var serverAdminServices: Array<String> {
    return [
        serviceName_GetSession,
        serviceName_WaitUntilBodyComplete,
        serverAdmin,
        serviceName_RestartSessionTimeout,
        serviceName_TransferResponse
    ]
 }
