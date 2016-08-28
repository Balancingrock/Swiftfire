// =====================================================================================================================
//
//  File:       ConsoleData.swift
//  Project:    SwiftfireConsole
//
//  Version:    0.9.14
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
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
// v0.9.14 - Initial release
// =====================================================================================================================

import Foundation
import CoreData

let consoleData = ConsoleData()

class ConsoleData {
    
    var context: NSManagedObjectContext!
    
    fileprivate init() {
    
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Creating Console Data")
        
        
        // Create the managed object context
        
        guard let modelUrl = Bundle.main.url(forResource: "ConsoleDataModel", withExtension: "momd") else {
            log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error loading console data model from bundle")
            sleep(1)
            fatalError("Error loading console data model from bundle")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: modelUrl) else {
            log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error initializing mom from: \(modelUrl)")
            sleep(1)
            fatalError("Error initializing mom from: \(modelUrl)")
        }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let error {
            log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error creating in-memory store: \(error)")
            sleep(1)
            fatalError("Error creating in-memory store: \(error)")
        }
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator

    
        // Data setup
        
        serverParametersSetup()
        serverTelemetrySetup()
        domainItemsSetup()
    }

    
    // MARK: - Server Parameters Window
    
    private func serverParametersSetup() {
    
        for parameter in serverParameterArray {
            let scParameter = NSEntityDescription.insertNewObject(forEntityName: "SCParameter", into: context) as! SCParameter
            scParameter.name = parameter.name.rawValue
            scParameter.label = parameter.label
            scParameter.value = "Not read"
            scParameter.sequence = parameter.sequence
        }
    }
 

    // MARK: - Server Telemetry Window

    private func serverTelemetrySetup() {
        
        for telemetry in serverTelemetryArray {
            let scTelemetry = NSEntityDescription.insertNewObject(forEntityName: "SCTelemetry", into: context) as! SCTelemetry
            scTelemetry.name = telemetry.name.rawValue
            scTelemetry.label = telemetry.label
            scTelemetry.value = "Not read"
            scTelemetry.sequence = telemetry.sequence
        }
    }

    private func domainItemsSetup() {
        
        let serverDomain = NSEntityDescription.insertNewObject(forEntityName: "SCDomainItem", into: context) as! SCDomainItem
        serverDomain.name = "Server"
        serverDomain.isServer = true
    }
}
