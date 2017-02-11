//
//  Statistics.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON
import SwifterLog


/// Singleton for all statistcs data

let statistics = Statistics()


final class Statistics: VJsonSerializable {
    
    
    /// The queue on which all mutations will take place
    
    private let queue = DispatchQueue(
        label: "Statistics",
        qos: .background,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil)

    
    /// All domains
    
    var domains = ST_Domains()
    
    
    /// All clients
    
    var clients = ST_Clients()
    
    
    /// The cutoff javaDate between yesterday and today
    
    var today: Int64 = Date().javaDateBeginOfDay

    
    /// The timed closure that is used to update 'today'
    
    var refreshToday: TimedClosure

    
    /// A JSON representation of all data

    var json: VJson {
        let json = VJson()
        json["Domains"] &= domains.json
        json["Clients"] &= clients.json
        return json
    }
    
    
    fileprivate init() {
        
        log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Creating statistics singleton")
        
        refreshToday = TimedClosure(
            queue: DispatchQueue.main,
            delay: WallclockTime(hour: 0, minute: 0, second: 0),
            closure: {
                statistics.today = Calendar.current.startOfDay(for: Date()).javaDate
            },
            once: false
        )
    }
    
    func save() {
        
        guard let file = FileURLs.statisticsDir?.appendingPathComponent("statistics.json") else { return }

        self.json.save(to: file)
    }
    
    func load() {
        
        do {
            guard let file = FileURLs.statisticsDir?.appendingPathComponent("statistics.json") else { return }
            
            if FileManager.default.fileExists(atPath: file.path) {
                
                let json = try VJson.parse(file: file)
            
                guard let domains = ST_Domains(json: json|"Domains") else { return }
                guard let clients = ST_Clients(json: json|"Clients") else { return }
            
                self.domains = domains
                self.clients = clients
            }

        } catch let error as VJson.Exception {
            
            log.atLevelCritical(id: -1, source: #file.source(#function, #line), message: error.description)
        
        } catch {}
    }
    
    func submit(mutation: Mutation, onSuccess: (()->())? = nil) {
        
        queue.async {
            
            switch mutation.kind {
                
            case .addClientRecord: statistics.addClientRecord(mutation, onSuccess)
            case .updateClient: statistics.updateClient(mutation, onSuccess)
            case .updatePathPart: statistics.updatePathPart(mutation, onSuccess)
            }
        }
    }
    
    fileprivate func addClientRecord(_ mutation: Mutation, _ onSuccess: (()->())? = nil) {
        
        // =========================================================
        // Create the client part first, this must always be present
        // =========================================================
        
        // Ensure that the client exists
        guard let client = clients.getClient(for: mutation.ipAddress) else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Cannot create or get client for address \(mutation.ipAddress)")
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
        
        let record = ST_ClientRecord(connectionObjectId: connectionObjectId, connectionAllocationCount: connectionAllocationCount, host: nil, requestReceived: requestReceived, requestCompleted: requestCompleted, httpResponseCode: httpResponseCode, responseDetails: responseDetails, socket: socket, url: nil)

        client.records.append(record)

        
        // ======================================================
        // Create the domain/url part only if a domain is present
        // ======================================================
        
        // Ensure the domain exists
        guard let domainStr = mutation.domain else { return }
        record.host = domainStr
        
        // And that it has a url
        guard let urlStr = mutation.url else { return }
        record.url = urlStr
        
        
        // ================================================================
        // Ensure that all path parts exist and have their counters updated
        // ================================================================
        
        // Create an array of path components
        guard let url = NSURL(string: urlStr) else { return }
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the root of the path parts
        var current = domains.getDomain(for: domainStr)
        
        // Exit if tracing is disabled
        if current == nil { return }
        
        // Continue until the last part
        for part in pathParts {
            
            // Update the counter
            current!.updateCounter()
            
            // Step to the next part
            current = current!.getPathPart(for: part)
            
            // Exit if tracing is disabled
            if current == nil { return }
        }
    }
    
    fileprivate func updatePathPart(_ mutation: Mutation, _ onSuccess: (()->())? = nil) {
        
        guard let urlstr = mutation.url else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing URL in UpdatePathPartCommand")
            return
        }
        
        guard let newState = mutation.doNotTrace else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing New State in UpdatePathPartCommand")
            return
        }
        
        // Create an array of path components
        guard let url = NSURL(string: urlstr) else { return }
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        if pathParts.count == 0 {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Empty or '/' URL in UpdatePathPartCommand")
            return
        }
        
        // Get the root of the path parts
        guard let domain = domains.getDomain(for: pathParts[0]) else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambiguous domain in URL of UpdatePathPartCommand")
            return
        }
        var current = domain
        
        while true {
            
            // Matched this part, remove it
            pathParts.remove(at: 0)
            
            // If this was the last, then current is the needed pathpart
            if pathParts.count == 0 { break }
            
            // Check for more
            guard let next = current.getPathPart(for: pathParts[0]) else {
                log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambigious path part \(pathParts[0]) in URL of UpdatePathPartCommand")
                return
            }
            
            current = next
        }
        
        // current now contains the sought after path part, update the doNotTrace status
        current.doNotTrace = newState
        
        onSuccess?()
    }

    fileprivate func updateClient(_ mutation: Mutation, _ onSuccess: (()->())? = nil) {
        
        guard let address = mutation.ipAddress else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing client address in UpdateClientCommand")
            return
        }
        
        guard let newState = mutation.doNotTrace else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Missing New State in UpdateClientCommand")
            return
        }
        
        // Get the root of the path parts
        guard let client = clients.getClient(for: address) else {
            log.atLevelError(id: -1, source: #file.source(#function, #line), message: "Unknown or ambiguous client in address of UpdateClientCommand")
            return
        }
        
        // current now contains the sought after path part, update the doNotTrace status
        client.doNotTrace = newState
        
        onSuccess?()
    }
}
