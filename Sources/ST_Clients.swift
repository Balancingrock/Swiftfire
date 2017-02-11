//
//  ST_Clients.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 08/02/17.
//
//

import Foundation
import SwifterJSON


/// The top level entry for the client statistics.

final class ST_Clients: VJsonConvertible {
    
    
    /// A list with all the clients
    
    var clients: [ST_Client] = []
    
    
    /// The VJson hierarchy contains all client info
    
    var json: VJson {
        return VJson(clients)
    }
    
    
    /// Recreates this object from a VJson hierarchy.
    
    init?(json: VJson?) {
        guard let json = json else { return nil }
        for jClient in json {
            guard let client = ST_Client(json: jClient) else { return nil }
            self.clients.append(client)
        }
    }
    
    
    /// Creates a new object.
    
    init() {}
    
    
    /// Returns the client for the given address. Creates a new client if it does not exist yet.
    
    func getClient(for address: String?) -> ST_Client? {
        guard let address = address else { return nil }
        for client in clients {
            if client.address == address { return client }
        }
        let client = ST_Client(address: address)
        clients.append(client)
        return client
    }

}
