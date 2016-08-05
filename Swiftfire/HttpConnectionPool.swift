// =====================================================================================================================
//
//  File:       HttpConnectionPool.swift
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
// v0.9.13 - Upgraded to Swift 3 beta
// v0.9.11 - Added allocation counter
// v0.9.6  - Header update
// v0.9.0  - Initial release
// =====================================================================================================================

import Foundation


private let SOURCE = ((#file as NSString).lastPathComponent as NSString).deletingPathExtension


// The connection pool for all connections that may be active simultaniously

internal var httpConnectionPool = HttpConnectionPool()


// HttpConnection pool management. Each HTTP client will need an object from this connection pool before its request can be processed. Inherits from NSObject to allow 'self' to be used for locking operations.

final class HttpConnectionPool: NSObject {
    
    
    // Used to secure atomic access to the pool.
    
    private static let syncQueue = DispatchQueue(label: "HttpConnectionPool synchronize queue", attributes: [.serial, .qosUserInteractive])
    
    
    // Only one connection pool
    
    private override init() { super.init() }
    
    
    // All available connection objects
    
    private var available: Array<HttpConnection> = []
    
    
    // All connection objects that are in use
    
    private var used: Array<HttpConnection> = []
    
    
    /// Allocates an HTTP Connection and returns it. If no HTTP Connection is available it returns nil.
    /// - Returns: An HTTP Connection object if available, otherwise nil.
    
    func allocate() -> HttpConnection? {
        
        return HttpConnectionPool.syncQueue.sync() {
            
            [unowned self] () -> HttpConnection? in
            
            var connection: HttpConnection?
            
            if self.available.count > 0 {
                connection = self.available.popLast()
            }
            
            if connection != nil {
                connection!.incrementAllocationCounter()
                self.used.insert(connection!, at: 0)
                log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Allocated connection with id = \(connection!.objectId) and allocationCount = \(connection!.allocationCount)" )
            }
            
            return connection
        }
    }
    
    
    /// Moves the given connection object from the 'used' to the 'available' pool.
    
    func free(connection: HttpConnection) {
        
        HttpConnectionPool.syncQueue.sync() {
            
            [unowned self] in
            
            var found: Int?
            for (index, c) in self.used.enumerated() {
                if c === connection {
                    found = index
                    break
                }
            }
            if found != nil {
                self.used.remove(at: found!)
                self.available.insert(connection, at: 0)
                log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Freed connection with id = \(connection.objectId) and allocationCount = \(connection.allocationCount)" )
            } else {
                var foundInAvailable = false
                for c in self.available {
                    if c === connection {
                        foundInAvailable = true
                        break
                    }
                }
                if !foundInAvailable {
                    log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Connection not found in 'used' or 'available' pool")
                } else {
                    log.atLevelEmergency(id: -1, source: #file.source(#function, #line), message: "Connection not found in 'used' pool, probably tried to close twice?")
                }
            }
        }
    }
    
    
    /// Request a connection, even if all connections are in use. Since it might take some time before the request is honoured, use the allocate function afterwards to test if a connection was freed. ***I*** (1)
    /// - Note: This request is binding. The process that processes HTTP requests *must* free its connection object when the 'abortProcessing' flag is set to true. However, this can take time, especially when the system experiences a heavy load.
    
    func request() {
        
        HttpConnectionPool.syncQueue.sync() {
            
            [unowned self] in
            
            // Find the oldest connection still in use and request its release
            
            if self.used.count > 0 {
                log.atLevelDebug(id: -1, source: #file.source(#function, #line), message: "Requesting connection object \(self.used.count - 1) to free itself.")
                self.used.last!.abortProcessing = true
            }
        }
    }
    
    
    /// Removes all old connection objects and creates new ones.
    /// This function will remove all free connection objects from the pool. Then it will wait until the connections that are in use will become free before removing them. Keep in mind that when there is a reasonable load, this can result in degraded performance for a long time as connections that become free will immediately be picked up again before they can be removed. It would be better to stop the server while this function is called and start again it afterwards.
    
    func create() {
        
        var success = false
        
        while !success {
            
            HttpConnectionPool.syncQueue.sync() {
                
                [unowned self] in
                
                log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Current status: Connections available = \(self.available.count), used = \(self.used.count)")
                self.available = []
                if self.used.count == 0 {
                    log.atLevelNotice(id: -1, source: #file.source(#function, #line), message: "Creatng \(Parameters.maxNofAcceptedConnections) new connection objects")
                    for _ in 0 ..< Parameters.maxNofAcceptedConnections {
                        self.available.append(HttpConnection())
                    }
                    success = true
                }
            }
            
            
            // This could take some time, so ensure that this process is aborted when swiftfire must be stopped.
            
            if quitSwiftfire { break }

            sleep(1)
        }
    }
}
