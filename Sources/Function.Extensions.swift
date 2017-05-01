//
//  Function.Extensions.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 28/04/17.
//
//

import Foundation
import SwiftfireCore

extension Function.Environment {
    
    /// Creates a new session with the data contained in the environment
    
    public func newSession() -> Session {
        
        return domain.sessions.newSession(
            address: connection.remoteAddress,
            domainName: domain.name,
            logId: (connection as? SFConnection)?.logId ?? -1,
            connectionId: (connection as? SFConnection)?.objectId ?? -1,
            allocationCount: (connection as? SFConnection)?.allocationCount ?? -1
        )
        
    }
}
