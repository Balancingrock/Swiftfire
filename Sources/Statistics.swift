// =====================================================================================================================
//
//  File:       Statistics.swift
//  Project:    Swiftfire
//
//  Version:    0.10.11
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2014-2017 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
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
// 0.10.11 - Replaced SwifterJSON with VJson
// 0.10.7 - Merged SwiftfireCore into Swiftfire
// 0.10.1 - Fixed warnings from XCode 8.3
// 0.10.0 - Added count & foreverCount
// 0.9.17 - Header update
// 0.9.15 - Initial release
// =====================================================================================================================

import Foundation
import VJson
import BRUtils


public final class Statistics: VJsonSerializable {
    
    
    /// Contain the entire hierarchy
    
    public var data: VJson = VJson()
    
    
    /// The queue on which all mutations will take place
    
    private let queue = DispatchQueue(
        label: "Statistics",
        qos: .background,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil)

    
    /// All domains
    
    public var domains = StDomains()
    
    
    /// All clients
    
    public var clients = StClients()
    
    
    /// The cutoff javaDate between yesterday and today
    
    public var today: Int64 = Date().javaDateBeginOfDay

    
    /// The timed closure that is used to update 'today'
    
    private var refreshToday: TimedClosure?

    
    /// A JSON representation of all data

    public var json: VJson {
        let json = VJson()
        json["Domains"] &= domains.json
        json["Clients"] &= clients.json
        return json
    }
    
    
    public init() {
        
        refreshToday = TimedClosure(
            queue: DispatchQueue.main,
            delay: WallclockTime(hour: 0, minute: 0, second: 0),
            closure: {
                [unowned self] in
                self.today = Calendar.current.startOfDay(for: Date()).javaDate
            },
            once: false
        )
    }
    
    public func save(toFile url: URL?) {
        
        guard let url = url else { return }
        
        self.json.save(to: url)
    }
    
    public func restore(fromFile url: URL?) -> Result<Bool> {

        guard let url = url else { return .success(true) }
        
        do {
            
            if FileManager.default.fileExists(atPath: url.path) {
                
                let json = try VJson.parse(file: url)
            
                return restore(fromVJson: json)
            }

        } catch let error as VJson.Exception {
            
            return .error(message: error.description)
        
        } catch {}
        
        return .success(true)
    }
    
    public func restore(fromVJson: VJson) -> Result<Bool> {
        
        guard let domains = StDomains(json: fromVJson|"Domains") else { return .error(message: "Item Domains is missing or contains error")}
        guard let clients = StClients(json: fromVJson|"Clients") else { return .error(message: "Item Clients is missing or contains error")}
        
        self.domains = domains
        self.clients = clients
        
        return .success(true)
    }
    
        
    /// Returns the count of the last pathPart in the path.
    ///
    /// - Parameters:
    ///   - domain: The domain for the path parts
    ///   - path: The string of path parts relative to the root of the domain.
    ///
    /// - Returns: The foreverCount property or 0 if the path(part) could not be found.
    
    public func count(domain: String,  path: String) -> Int64 {
        
        // Create an array of path components
        var pathParts = (path as NSString).pathComponents
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the root for the path parts
        var current = domains.getDomain(for: domain)
        
        // Continue until the last part
        for part in pathParts {
            
            // Step to the next part
            current = current!.getPathPart(for: part, nilOnDoNotTrace: false)
            
            if current == nil { return -1 }
        }
        
        // Update the counter (the last path part ended the loop and must still be updated)
        return current?.count ?? -1
    }

    
    /// Returns the forever count of the last pathPart in the path.
    ///
    /// - Parameters:
    ///   - domain: The domain for the path parts
    ///   - path: The string of path parts relative to the root of the domain.
    ///
    /// - Returns: The foreverCount property or 0 if the path(part) could not be found.
    
    public func foreverCount(domain: String,  path: String) -> Int64 {
        
        // Create an array of path components
        var pathParts = (path as NSString).pathComponents
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the root for the path parts
        var current = domains.getDomain(for: domain)
        
        // Continue until the last part
        for part in pathParts {
            
            // Step to the next part
            current = current!.getPathPart(for: part, nilOnDoNotTrace: false)
            
            if current == nil { return 0 }
        }
        
        // Update the counter (the last path part ended the loop and must still be updated)
        return current?.foreverCount ?? 0
    }
    
    /// Stores the data contained in the mutation.
    ///
    /// This operation a (usefull) side effect. The 'requestCompleted' field will be filled in automatically if it is nil on entry.
    ///
    /// - Parameters:
    ///   - mutation: The data to be stored
    ///   - onSuccess: A closure to be executed when the data was successfully stored.
    
    public func submit(mutation: Mutation, onSuccess: (() -> Void)? = nil, onError: ((String) -> Void)?) {
        
        if mutation.requestCompleted == nil {
            mutation.requestCompleted = Date().javaDate
        }
        
        queue.async {
            
            [unowned self] in
            
            switch mutation.kind {
                
            case .addClientRecord:
                switch self.addClientRecord(mutation) {
                case .error(let message): onError?(message)
                case .success: onSuccess?()
                }
                
            case .updateClient:
                switch self.updateClient(mutation) {
                case .error(let message): onError?(message)
                case .success: onSuccess?()
                }
                
            case .updatePathPart:
                switch self.updatePathPart(mutation, onSuccess) {
                case .error(let message): onError?(message)
                case .success: onSuccess?()
                }
            }
        }
    }
    
    private func addClientRecord(_ mutation: Mutation) -> Result<Bool> {
        
        // =========================================================
        // Create the client part first, this must always be present
        // =========================================================
        
        // Ensure that the client exists
        guard let client = clients.getClient(for: mutation.ipAddress) else {
            return .error(message: "Cannot create or get client for address \(mutation.ipAddress ?? "Unknown")")
        }
        
        // Exit if this is a no-trace client
        if client.doNotTrace { return .success(true) }
        
        // Check for presence of necessary information
        
        guard let requestCompleted = mutation.requestCompleted else {
            return .error(message: "Missing RequestCompleted in mutation")
        }
        
        guard let requestReceived = mutation.requestReceived else {
            return .error(message: "Missing RequestReceived in mutation")
        }
        
        guard let httpResponseCode = mutation.httpResponseCode else {
            return .error(message: "Missing HttpResponseCode in mutation")
        }
        
        guard let responseDetails = mutation.responseDetails else {
            return .error(message: "Missing ResponseDetails in mutation")
        }
        
        guard let connectionAllocationCount = mutation.connectionAllocationCount else {
            return .error(message: "Missing ConnectionAllocationCount in mutation")
        }
        
        guard let connectionObjectId = mutation.connectionObjectId else {
            return .error(message: "Missing ConnectionObjectId in mutation")
        }
        
        guard let socket = mutation.socket else {
            return .error(message: "Missing Socket in mutation")
        }
        
        
        // =========================
        // Create a new ClientRecord
        // =========================
        
        let record = StClientRecord(connectionObjectId: connectionObjectId, connectionAllocationCount: connectionAllocationCount, host: nil, requestReceived: requestReceived, requestCompleted: requestCompleted, httpResponseCode: httpResponseCode, responseDetails: responseDetails, socket: socket, url: nil)

        client.records.append(record)

        
        // ======================================================
        // Create the domain/url part only if a domain is present
        // ======================================================
        
        // Ensure the domain exists
        guard let domainStr = mutation.domain else { return .success(true) }
        record.host = domainStr
        
        // And that it has a url
        guard let urlStr = mutation.url else { return .success(true) }
        record.url = urlStr
        
        
        // ================================================================
        // Ensure that all path parts exist and have their counters updated
        // ================================================================
        
        // Create an array of path components
        guard let url = NSURL(string: urlStr) else { return .success(true) }
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        
        // Get the root of the path parts
        var current = domains.getDomain(for: domainStr)
        
        // Exit if tracing is disabled
        if current == nil { return .success(true) }
        
        // Continue until the last part
        for part in pathParts {
            
            // Update the counter
            current!.updateCounter(today: today)
            
            // Step to the next part
            current = current!.getPathPart(for: part)
            
            // Exit if tracing is disabled
            if current == nil { return .success(true) }
        }

        // Update the counter (the last path part ended the loop and must still be updated)
        current!.updateCounter(today: today)

        return .success(true)
    }
    
    private func updatePathPart(_ mutation: Mutation, _ onSuccess: (()->())? = nil) -> Result<Bool> {
        
        guard let urlstr = mutation.url else {
            return .error(message: "Missing URL in UpdatePathPartCommand")
        }
        
        guard let newState = mutation.doNotTrace else {
            return .error(message: "Missing New State in UpdatePathPartCommand")
        }
        
        // Create an array of path components
        guard let url = NSURL(string: urlstr) else { return .success(true) }
        var pathParts = url.pathComponents ?? [""]
        
        // If the first part is a "/", then remove it
        if pathParts.count > 0 && pathParts[0] == "/" { pathParts.remove(at: 0) }
        if pathParts.count == 0 {
            return .error(message: "Empty or '/' URL in UpdatePathPartCommand")
        }
        
        // Get the root of the path parts
        guard let domain = domains.getDomain(for: pathParts[0]) else {
            return .error(message: "Unknown or ambiguous domain in URL of UpdatePathPartCommand")
        }
        var current = domain
        
        while true {
            
            // Matched this part, remove it
            pathParts.remove(at: 0)
            
            // If this was the last, then current is the needed pathpart
            if pathParts.count == 0 { break }
            
            // Check for more
            guard let next = current.getPathPart(for: pathParts[0]) else {
                return .error(message: "Unknown or ambigious path part \(pathParts[0]) in URL of UpdatePathPartCommand")
            }
            
            current = next
        }
        
        // current now contains the sought after path part, update the doNotTrace status
        current.doNotTrace = newState
        
        return .success(true)
    }

    private func updateClient(_ mutation: Mutation) -> Result<Bool> {
        
        guard let address = mutation.ipAddress else {
            return .error(message: "Missing client address in UpdateClientCommand")
        }
        
        guard let newState = mutation.doNotTrace else {
            return .error(message: "Missing New State in UpdateClientCommand")
        }
        
        // Get the root of the path parts
        guard let client = clients.getClient(for: address) else {
            return .error(message: "Unknown or ambiguous client in address of UpdateClientCommand")
        }
        
        // current now contains the sought after path part, update the doNotTrace status
        client.doNotTrace = newState
        
        return .success(true)
    }
}
