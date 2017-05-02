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
    
    public func newSession() -> Session? {
        
        guard let connection = (connection as? SFConnection) else { return nil }
        
        return domain.sessions.newSession(
            address: connection.remoteAddress,
            domainName: domain.name,
            logId: connection.logId,
            connectionId: connection.objectId,
            allocationCount: connection.allocationCount,
            timeout: domain.sessionTimeout
        )
    }
}
