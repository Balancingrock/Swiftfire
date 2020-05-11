// =====================================================================================================================
//
//  File:       Service.Setup.ExecuteUpdateServices.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019-2020 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Split off from Service.Setup
//
// =====================================================================================================================

import Foundation

import Http
import Core


/// This command updates the domain services.
///
/// - Parameters:
///     - request: The request that resulted in the activation of this procedure.
///     - domain: The domain for the services.

func executeUpdateServices(_ request: Request, _ domain: Domain) {
    
    struct ServiceItem {
        let index: Int
        let name: String
    }
    
    var serviceArr: Array<ServiceItem> = []
    
    var index = 0
    
    var error = false;
    
    while let _ = request.info["seqname\(index)"] {
        
        if let _ = request.info["usedname\(index)"] {
            
            if  let newIndexStr = request.info["seqname\(index)"],
                let newIndex = Int(newIndexStr) {
                
                if let newName = request.info["namename\(index)"] {
                    serviceArr.append(ServiceItem(index: newIndex, name: newName))
                } else {
                    error = true
                    Log.atError?.log("Missing nameName for index \(index)")
                }
                
            } else {
                error = true
                Log.atError?.log("Missing seqName for index \(index)")
            }
        }
        index += 1
    }
    
    guard error == false else { return }
    
    serviceArr.sort(by: { $0.index < $1.index })
    
    domain.serviceNames = serviceArr.map({ $0.name })
    
    domain.rebuildServices()
    
    domain.storeSetup()
    
    var str = ""
    if domain.serviceNames.count == 0 {
        str += "\nDomain Service Names:\n None\n"
    } else {
        str += "\nDomain Service Names:\n"
        domain.serviceNames.forEach() { str += " service name = \($0)\n" }
    }

    Log.atNotice?.log("Updated services for domain \(domain.name) to/n\(str)")
}
