// =====================================================================================================================
//
//  File:       Statistics-Swiftfire.swift
//  Project:    Swiftfire
//
//  Version:    0.9.14
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
// v0.9.14 - Upgraded to Xcode 8 beta 6
// v0.9.13 - Upgraded to Xcode 8 beta 3 (Swift 3)
// v0.9.12 - Changed cd counters to daily counters
//         - Added support for 'doNotTrace' options
//         - Changed timestamps from double to int64
//         - Added GuiRequest protocol
// v0.9.11 - Initial release
// =====================================================================================================================


import Foundation
import CoreData


let statistics = Statistics()


final class Statistics: NSObject {

    
    // The queue on which all mutations will take place
    
    private static let queue = DispatchQueue(
        label: "CoreDataStatistics",
        qos: .default,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil)
    
    
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
    
    override fileprivate init() {
        
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Creating statistics singleton")
        
        guard let modelUrl = Bundle.main.url(forResource: "Statistics", withExtension:"momd") else {
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
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        super.init()
        
        refreshToday = TimedClosure(
            queue: DispatchQueue.main,
            delay: WallclockTime(hour: 0, minute: 0, second: 0),
            closure: {
                [weak self] in
                self?.managedObjectContext.perform({
                    [weak self] in
                    self?.today = Calendar.current.startOfDay(for: Date()).javaDate
                })
            },
            once: false
        )
        
        guard let statisticsDir = FileURLs.statisticsDir else {
            log.atLevelCritical(id: -1, source: #file.source(#function, #line), message: "Unable to retrieve statistics directory")
            return
        }
        
        managedObjectContext.perform({
            do {
                let storeURL = statisticsDir.appendingPathComponent("StatisticsModel.sqlite")
                try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            } catch {
                log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error migrating store: \(error)")
                return
            }
        })
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
        
        
        managedObjectContext.perform({
            
            [unowned self] in
            
            // Empty the current context
            
            self.managedObjectContext.reset()
            
            // Create the domains first because this includes the creation of CDCounters. When the Clients are created the CDClientRecord will need the CDCounters to be present.
            
            _ = CDDomains.createFrom(json: jdomains, inContext: self.managedObjectContext)
            _ = CDClients.createFrom(json: jclients, inContext: self.managedObjectContext)
        })
    }
    
    
    /// Saves the content of the core data model to disk if anything was changed.
    /// - Returns: Nil if all went as planned. A NSError if something went wrong.
    
    @discardableResult
    func save() -> NSError? {
        
        var result: NSError?
        
        managedObjectContext.performAndWait({
            
            [unowned self] in
            
            if self.managedObjectContext.hasChanges {
                do {
                    try self.managedObjectContext.save()
                    result = nil
                } catch {
                    log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Error saving statistics: \(error)")
                    result = error as NSError
                }
            }
        })
        
        return result
    }
    
    
    /// - Returns: The Client Managed Object for the given address. Creates a new one if necessary.
    
    private func getClient(forAddress address: String?) throws -> CDClient? {
        
        
        guard let address = address else { return nil }
        
        let fetchRequest = NSFetchRequest<CDClient>(entityName: "CDClient")
        fetchRequest.predicate = NSPredicate(format: "address == %@", address)
        
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
    
    
    /// - Returns: The existing CDPathPart for the given domain name or -if absent- creates a new one.
    
    private func getDomain(forName name: String?) -> CDPathPart? {
        
        // Find and return an existing one
        for p in cdDomains.domains! {
            let pp = p as! CDPathPart
            if pp.pathPart! == name {
                if pp.doNotTrace { return nil }
                return pp
            }
        }
        
        // Create a new one
        let pp = NSEntityDescription.insertNewObject(forEntityName: "CDPathPart", into: managedObjectContext) as! CDPathPart
        pp.pathPart = name
        pp.domains = cdDomains
        
        // Add a counter to it
        let c = NSEntityDescription.insertNewObject(forEntityName: "CDCounter", into: managedObjectContext) as! CDCounter
        c.forDay = Date().javaDateBeginOfDay
        
        pp.counterList = c
        
        return pp
    }
    
    
    /// - Returns: Nil if the part already exists and has its "doNotTrace" member set to 'true'. Otherwise it returns the found part or creates a new one (and returns that).
    
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
    
    
    /// - Returns: The last PathPart belonging to the end of the given URL string or nil if that could not be found. Will not create a new PathPart if none is found.
    
    private func getPartPart(atPath: String?) -> CDPathPart? {
        
        guard let urlstr = atPath else { return nil }
        
        // Create an array of path components
        let url = URL(string: urlstr) ?? URL(string: "")!
        var pathParts = url.pathComponents
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the domain for the first path part
        let matchedDomains = (cdDomains.domains?.allObjects as! [CDPathPart]).filter(){ $0.pathPart! == pathParts[0]}
        if matchedDomains.count != 1 {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambiguous domain in URL of UpdatePathPartCommand")
            return nil
        }
        var result = matchedDomains[0]
        
        while pathParts.count > 0 {
            
            // Matched this part, remove it
            pathParts.remove(at: 0)
            
            if pathParts.count == 0 { return result }
            
            // Check for the next level path parts
            if result.next != nil || result.next?.count == 0 {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown path part \(pathParts[0]) in URL of UpdatePathPartCommand")
                return nil
            }
            let matchedParts = (result.next!.allObjects as! [CDPathPart]).filter(){ $0.pathPart! == pathParts[0]}
            if matchedParts.count != 1 {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambigious path part \(pathParts[0]) in URL of UpdatePathPartCommand")
                return nil
            }
            
            // Advance down the tree
            result = matchedDomains[0]
        }
        
        return nil // the 'result' is not the path part we are looking for
    }
    
    /// Performs the requested mutation.
    ///
    /// - Parameter mutation: The mutation to be performed.
    
    func submit(mutation: Mutation) {
        
        managedObjectContext.perform({
            
            [unowned self] in

            // Perform the action associated with the mutation
            
            switch mutation.kind {
            case .AddClientRecord: do { try self.addClientRecord(mutation: mutation) } catch {}
            case .UpdatePathPart: self.updatePathPart(mutation: mutation)
            case .UpdateClient: self.updateClient(mutation: mutation)
/*            case .EmptyDatabase: self.emptyDatabase(mutation)
            case .RemoveAllClientRecords: self.removeAllClientRecords(mutation)
            case .RemoveAllClients: self.removeAllClients(mutation)
            case .RemoveAllPathParts: self.removeAllPathParts(mutation)
            case .RemoveClient: self.removeClient(mutation)
            case .RemoveClientRecords: self.removeClientRecords(mutation)
            case .RemovePathPart: self.removePathParts(mutation)
                 */
            }
            
            // Store the mutation itself
            
            let cdMutation = NSEntityDescription.insertNewObject(forEntityName: "CDMutation", into: self.managedObjectContext) as! CDMutation
            cdMutation.client = mutation.client
            cdMutation.connectionAllocationCount = mutation.connectionAllocationCount ?? -1
            cdMutation.connectionObjectId = mutation.connectionObjectId ?? -1
            cdMutation.domain = mutation.domain
            cdMutation.doNotTrace = mutation.doNotTrace ?? false
            cdMutation.httpResponseCode = mutation.httpResponseCode
            cdMutation.kind = mutation.kind.rawValue
            cdMutation.requestCompleted = mutation.requestCompleted ?? 0
            cdMutation.requestReceived = mutation.requestReceived ?? 0
            cdMutation.responseDetails = mutation.responseDetails
            cdMutation.socket = mutation.socket ?? -1
            cdMutation.url = mutation.url
            
            if self.firstMutation == nil {
                self.firstMutation = cdMutation
                self.lastMutation = cdMutation
            } else {
                cdMutation.previous = self.lastMutation // Side effect: The 'next' of lastMutation will now point to cdMutation
                self.lastMutation = cdMutation
            }
        })
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
        record.host = domainStr
        
        // And that it has a url
        guard let urlStr = mutation.url else { return }
        record.url = urlStr
        
        
        // ================================
        // Ensure that all path parts exist
        // ================================
        
        // Create an array of path components
        let url = NSURL(string: urlStr) ?? NSURL(string: "")!
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the root of the path parts
        var current = getDomain(forName: domainStr)
        
        // Exit if tracing is disabled
        if current == nil { return }
        
        // Continue until the last part
        for part in pathParts {
            current = getPathPart(forPart: part, fromPathPart: current!)
            // Exit if tracing is disabled
            if current == nil { return }
        }
        
        
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
                newCounter.forDay = today
            }
            current!.counterList!.count += 1
            current!.counterList!.mutableSetValue(forKey: "clientRecords").add(record)
            current!.foreverCount += 1
            current = current!.previous
        } while current != nil
        
    }

    private func updatePathPart(mutation: Mutation) {
        
        guard let urlstr = mutation.url else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing URL in UpdatePathPartCommand")
            return
        }
        
        guard let newState = mutation.doNotTrace else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing New State in UpdatePathPartCommand")
            return
        }
        
        // Create an array of path components
        let url = NSURL(string: urlstr) ?? NSURL(string: "")!
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        if pathParts.count == 0 {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Empty or '/' URL in UpdatePathPartCommand")
            return
        }
        
        // Get the root of the path parts
        let matchedDomains = (cdDomains.domains?.allObjects as! [CDPathPart]).filter(){ $0.pathPart! == pathParts[0]}
        if matchedDomains.count != 1 {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambiguous domain in URL of UpdatePathPartCommand")
            return
        }
        var current = matchedDomains[0]
        
        while true {
            
            // Matched this part, remove it
            pathParts.remove(at: 0)
            
            // If this was the last, then current is the needed pathpart
            if pathParts.count == 0 { break }
            
            // Check for more
            if let matchedParts = ((current.next?.allObjects as? [CDPathPart])?.filter(){ $0.pathPart! == pathParts[0]})  {
                if matchedParts.count != 1 {
                    log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambigious path part \(pathParts[0]) in URL of UpdatePathPartCommand")
                    return
                } else {
                    // Advance down the tree
                    current = matchedParts[0]
                }
            } else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown path part \(pathParts[0]) in URL of UpdatePathPartCommand")
                return
            }
        }
        
        // current now contains the sought after path part, update the doNotTrace status
        current.doNotTrace = newState
        
        // Try to signal the console (if any) that the path part is updated
        let message = ReadStatisticsReply(statistics: self.json)
        toConsole?.transfer(message)
    }
    
    
    private func updateClient(mutation: Mutation) {
        
        guard let address = mutation.client else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing client address in UpdateClientCommand")
            return
        }
        
        guard let newState = mutation.doNotTrace else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing New State in UpdateClientCommand")
            return
        }
        
        // Get the root of the path parts
        let matchedClients = (cdClients.clients?.allObjects as! [CDClient]).filter(){ $0.address! == address }
        if matchedClients.count != 1 {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambiguous client in address of UpdateClientCommand")
            return
        }
        let client = matchedClients[0]
        
        // current now contains the sought after path part, update the doNotTrace status
        client.doNotTrace = newState
        
        // Try to signal the console (if any) that the path part is updated
        let message = ReadStatisticsReply(statistics: self.json)
        toConsole?.transfer(message)
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
