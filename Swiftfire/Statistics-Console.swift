// =====================================================================================================================
//
//  File:       Statistics-Console.swift
//  Project:    Swiftfire
//
//  Version:    0.9.12
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
// v0.9.12 - Added statisticsWindowController to recalculate the count values after loading
//         - Added 'updatePathPart' and 'updateClient' to mutation switch statements
//         - Changed timestamps from double to Int64
//         - Added GuiRequest, generateTestContent
// v0.9.11 - Initial release
// =====================================================================================================================


import Foundation
import CoreData


let statistics = Statistics()


// In order to avoid having to link Cocoa with Swiftfire, a protocl is used to request GUI services.
// These services will only be used from the SwiftfireConsole.

protocol GuiRequest {
    func displayHistory(pathPart: CDPathPart)
}


final class Statistics: NSObject {
    
    
    // The Gui Request protocol handler (nil for Swiftfire)
    
    var gui: GuiRequest?
    
    
    var statisticsWindowController: StatisticsWindowController?
    
    
    /// The store coordinator
    
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    
    /// The managed object context
    
    let managedObjectContext: NSManagedObjectContext
    
    
    /// The top level object with references to all domains
    
    var cdDomains: CDDomains {
        do {
            let fetchDomainsRequest = NSFetchRequest<CDDomains>(entityName: "CDDomains")
            let domainsArray = try self.managedObjectContext.fetch(fetchDomainsRequest)
            switch domainsArray.count {
            case 0: return NSEntityDescription.insertNewObject(forEntityName: "CDDomains", into: self.managedObjectContext) as! CDDomains
            case 1: return domainsArray[0]
            default: fatalError("Too many CDDomains in core data store (expected 1, found: \(domainsArray.count))")
            }
        } catch {
            fatalError("Unable to fetch CDDomains with error: \(error)")
        }
    }
    
    
    /// The top level object with references to all clients.
    /// - Note: The domains themselves are CDPathParts just like the other parts of a URL.
    
    var cdClients: CDClients {
        do {
            let fetchClientsRequest = NSFetchRequest<CDClients>(entityName: "CDClients")
            let clientsArray = try self.managedObjectContext.fetch(fetchClientsRequest)
            switch clientsArray.count {
            case 0: return NSEntityDescription.insertNewObject(forEntityName: "CDClients", into: self.managedObjectContext) as! CDClients
            case 1: return clientsArray[0]
            default: fatalError("Too many CDClients in core data store (expected 1, found: \(clientsArray.count))")
            }
        } catch {
            fatalError("Unable to fetch CDClients with error: \(error)")
        }
    }
    
    
    /// The top level mutation pointers
    
    var firstMutation: CDMutation?
    var lastMutation: CDMutation?
    
    
    /// A JSON representation of the whole store
    
    var json: VJson {
        self.save()
        let json = VJson()
        let domains = cdDomains // Ensure that the lazy variable is evaluated. Using the cdDomains.json directly has led to spurious crashes.
        let clients = cdClients // Ensure that the lazy variable is evaluated. Using the cdClients.json directly has led to spurious crashes.
        json.add(domains.json, forName: "CDDomains")
        json.add(clients.json, forName: "CDClients")
        
        return json
    }
    
    
    /// The cutoff javaDate between yesterday and today
    
    var today: Int64 = Date().javaDateBeginOfDay
    
    
    /// The timed closure that is used to update 'today'
    
    var refreshToday: TimedClosure?
    
    
    /// Creates a new instance of the statistics object.
    /// - Note: There should be only 1 instance for each target.
    
    override private init() {
        
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Creating statistics singleton")
        
        guard let modelUrl = Bundle.main.urlForResource("Statistics", withExtension:"momd") else {
            log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error loading domain statistics model from bundle")
            sleep(1)
            fatalError("Error loading domain statistics model from bundle")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelUrl) else {
            log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error initializing mom from: \(modelUrl)")
            sleep(1)
            fatalError("Error initializing mom from: \(modelUrl)")
        }
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        super.init()
        
        
        guard let statisticsDir = FileURLs.statisticsDir else {
            log.atLevelCritical(id: -1, source: #file.source(#function, #line), message: "Unable to retrieve statistics directory")
            return
        }
            
        
        do {
            let storeURL = try statisticsDir.appendingPathComponent("StatisticsModel.sqlite")
            try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error migrating store: \(error)")
            return
        }
    }
    
    
    /// Reinitialize the core data context with the contents of the given JSON code.
    
    func load(json: VJson) {
        
        log.atLevelDebug(id: -1, source: #file.source(#function, #line))
        
        guard let jdomains = json|"CDDomains" else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "No 'CDDomains' item found in JSON code")
            return
        }
        
        guard let jclients = json|"CDClients" else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "No 'CDClients' item found in JSON code")
            return
        }

        
        // Empty the current context
        
        managedObjectContext.reset()
        
        // Create the domains first because this includes the creation of CDCounters. When the Clients are created the CDClientRecord will need the CDCounters to be present.
        
        _ = CDDomains.createFrom(json: jdomains, inContext: managedObjectContext)
        _ = CDClients.createFrom(json: jclients, inContext: managedObjectContext)
        
        statisticsWindowController?.recalculateCountValue()
    }
    
    
    /// Saves the content of the core data model to disk if anything was changed.
    /// - Returns: Nil if all went as planned. A NSError if something went wrong.
    
    @discardableResult
    func save() -> NSError? {
        
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error saving statistics: \(error)")
                return error as NSError
            }
        }

        return nil
    }
    
    
    /// Generates test content
    
    func generateTestContent() {
        
        // Empty the store
        managedObjectContext.reset()
        
        let cdDomains = NSEntityDescription.insertNewObject(forEntityName: "CDDomains", into: managedObjectContext) as! CDDomains
        _ = NSEntityDescription.insertNewObject(forEntityName: "CDClients", into: managedObjectContext) as! CDClients
        
        let d1 = NSEntityDescription.insertNewObject(forEntityName: "CDPathPart", into: managedObjectContext) as! CDPathPart
        d1.pathPart = "overbeterleven.nl"
        d1.domains = cdDomains
        
        let d1c1 = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
        d1c1.pathPart = d1
        d1c1.count = 1
        d1c1.forDay = Date().javaDateBeginOfDay
        
        let d1c2 = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
        d1c2.previous = d1c1
        d1c2.count = 2
        d1c2.forDay = Date().javaDateBeginOfYesterday
        
        let d1c3 = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
        d1c3.previous = d1c2
        d1c3.count = 3
        d1c3.forDay = Date().javaDateBeginOfYesterday - 12 * 60 * 60 * 1000
    }
    
    
    /**
     - Returns: The Client Managed Object for the given address. Creates a new one if necessary.
     */
    
    private func getClient(forAddress address: String?) throws -> CDClient? {
        
        guard let address = address else { return nil }
        
        let fetchRequest = NSFetchRequest<CDClient>(entityName: "CDClient")
        fetchRequest.predicate = Predicate(format: "address == %@", address)

        let clients = try managedObjectContext.fetch(fetchRequest)
        
        switch clients.count {
        
        case 0:
        
            log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Creating new Client entity for IP Address = \(address)")
            
            let client = NSEntityDescription.insertNewObject(forEntityName: "CDClient", into: managedObjectContext) as! CDClient
            client.address = address
            client.clients = cdClients

            return client

            
        case 1:
            
            return clients[0]
        
            
        default:
            
            fatalError("Too many CDClient's found for address \(address)")
        }
    }
    
    
    /**
     - Returns: The existing CDPathPart for the given part or -if absent- creates a new one.
     */
    
    private func getPathPart(forPart part: String?) -> CDPathPart? {
        
        // Find and return an existing one
        for p in cdDomains.domains! {
            let pp = p as! CDPathPart
            if pp.pathPart! == part {
                if pp.doNotTrace { return nil }
                return pp
            }
        }
        
        // Create a new one
        let pp = NSEntityDescription.insertNewObject(forEntityName: "CDPathPart", into: managedObjectContext) as! CDPathPart
        pp.pathPart = part
        pp.domains = cdDomains
        
        // Add a counter to it
        let c = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
        c.forDay = Date().javaDateBeginOfDay
        
        pp.counterList = c
        
        return pp
    }
    
    
    /**
     - Returns: Nil if the part already exists and has its "doNotTrace" member set to 'true'. Otherwise it returns the found part or creates a new one (and returns that).
     */
    
    private func getPathPart(forPart part: String, fromPathPart pathPart: CDPathPart) -> CDPathPart? {
        
        // Find an existing one
        for p in pathPart.next! {
            let pp = p as! CDPathPart
            if pp.pathPart! == part {
                if pp.doNotTrace { return nil }
                return pp
            }
        }
        
        // Is it allowed to create new pathParts?
        if pathPart.doNotTrace { return nil }
        
        // Create a new one
        let pp = NSEntityDescription.insertNewObject(forEntityName: "CDPathPart", into: managedObjectContext) as! CDPathPart
        pp.pathPart = part
        pp.previous = pathPart
        
        // Add a counter to it
        let c = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
        c.forDay = Date().javaDateBeginOfDay
        
        pp.counterList = c

        return pp
    }
    
    
    /**
     Performs the requested mutation.
     
     - Parameter mutation: The mutation to be performed.
     */
    
    func submit(mutation: Mutation) {
        
        // Perform the action associated with the mutation
        
        switch mutation.kind {
        case .AddClientRecord: do { try addClientRecord(mutation: mutation) } catch {}
        case .UpdatePathPart: updatePathPart(mutation: mutation)
        case .UpdateClient: updateClient(mutation: mutation)
/*
        case .EmptyDatabase: emptyDatabase(mutation)
        case .RemoveAllClientRecords: removeAllClientRecords(mutation)
        case .RemoveAllClients: removeAllClients(mutation)
        case .RemoveAllPathParts: removeAllPathParts(mutation)
        case .RemoveClient: removeClient(mutation)
        case .RemoveClientRecords: removeClientRecords(mutation)
        case .RemovePathPart: removePathParts(mutation)
*/
        }
        
        
        // Store the mutation itself
        
        let cdMutation = NSEntityDescription.insertNewObject(forEntityName: "CDMutation", into: managedObjectContext) as! CDMutation
        cdMutation.client = mutation.client
        cdMutation.connectionAllocationCount = mutation.connectionAllocationCount ?? -1
        cdMutation.connectionObjectId = mutation.connectionObjectId ?? -1
        cdMutation.domain = mutation.domain
        cdMutation.doNotTrace = mutation.doNotTrace ?? false
        cdMutation.httpResponseCode = mutation.httpResponseCode
        cdMutation.kind = mutation.kind.rawValue
        cdMutation.requestCompleted = mutation.requestCompleted ?? -1
        cdMutation.requestReceived = mutation.requestReceived ?? -1
        cdMutation.responseDetails = mutation.responseDetails
        cdMutation.socket = mutation.socket ?? -1
        cdMutation.url = mutation.url
        
        if firstMutation == nil {
            firstMutation = cdMutation
            lastMutation = cdMutation
        } else {
            cdMutation.previous = lastMutation // Side effect: The 'next' of lastMutation will now point to cdMutation
            lastMutation = cdMutation
        }
    }
    
    private func addClientRecord(mutation: Mutation) throws {
        
        // =========================================================
        // Create the client part first, this must always be present
        // =========================================================
        
        // Ensure that the client exists
        guard let client = try getClient(forAddress: mutation.client) else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Cannot create or get client for address \(mutation.client)")
            return
        }
        
        // Exit if this is a no-trace client
        if client.doNotTrace { return }

        // Check for presence of necessary information
        
        guard let requestCompleted = mutation.requestCompleted else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing RequestCompleted in mutation")
            return
        }
        
        guard let requestReceived = mutation.requestReceived else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing RequestReceived in mutation")
            return
        }
        
        guard let httpResponseCode = mutation.httpResponseCode else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing HttpResponseCode in mutation")
            return
        }
        
        guard let responseDetails = mutation.responseDetails else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing ResponseDetails in mutation")
            return
        }
        
        guard let connectionAllocationCount = mutation.connectionAllocationCount else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing ConnectionAllocationCount in mutation")
            return
        }
        
        guard let connectionObjectId = mutation.connectionObjectId else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing ConnectionObjectId in mutation")
            return
        }
        
        guard let socket = mutation.socket else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing Socket in mutation")
            return
        }

        
        // =========================
        // Create a new ClientRecord
        // =========================

        let record = NSEntityDescription.insertNewObject(forEntityName: "CDClientRecord", into: managedObjectContext) as! CDClientRecord
        record.client = client // Side effect: Also adds the record to the client
        record.requestReceived = requestReceived
        record.requestCompleted = requestCompleted
        record.httpResponseCode = httpResponseCode
        record.responseDetails = responseDetails
        record.connectionAllocationCount = connectionAllocationCount
        record.connectionObjectId = connectionObjectId
        record.socket = socket

        
        // ======================================================
        // Create the domain/url part only if a domain is present
        // ======================================================
        
        // Ensure the domain exists
        guard let domainStr = mutation.domain else { return }

        // And that it has a url
        guard let urlStr = mutation.url else { return }

        
        // ================================
        // Ensure that all path parts exist
        // ================================
        
        // Create an array of path components
        let url = NSURL(string: urlStr) ?? NSURL(string: "")!
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the root of the path parts
        var current = getPathPart(forPart: domainStr)
        
        // Exit if tracing is disabled
        if current == nil { return }
        
        // Continue until the last part
        for part in pathParts {
            current = getPathPart(forPart: part, fromPathPart: current!)
            // Exit if tracing is disabled
            if current == nil { return }
        }
        
        
        // ========================
        // Update the client record
        // ========================
        
        record.urlCounter = current!.counterList! // Side effect: Also adds the record to the counter.

        
        // =========================
        // Update all counter values
        // =========================
        
        // The current pathpart is the last, now roll back and increment each of the counters along the way (as well as the forever counter)
        repeat {
            if current!.counterList!.forDay < today {
                // Create new counter
                let newCounter = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
                newCounter.next = current!.counterList!
                newCounter.pathPart = current
            }
            current!.counterList!.count += 1
            current!.counterList!.mutableSetValue(forKey: "clientRecords").add(record)
            current!.foreverCount += 1
            current = current!.previous
        } while current != nil

    }
    
    private func updatePathPart(mutation: Mutation) {
        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unexpectedly called")
    }
    
    private func updateClient(mutation: Mutation) {
        log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unexpectedly called")        
    }

/*
    private func emptyDatabase(mutation: Mutation) {
        
    }

    private func removeAllClientRecords(mutation: Mutation) {
        
    }

    private func removeAllClients(mutation: Mutation) {
        
    }
    
    private func removeAllPathParts(mutation: Mutation) {
        
    }
    
    private func removeClient(mutation: Mutation) {
        
    }
    
    private func removeClientRecords(mutation: Mutation) {
        
    }
    
    private func removePathParts(mutation: Mutation) {
        
    }

*/
}
