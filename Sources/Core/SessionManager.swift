// =====================================================================================================================
//
//  File:       SessionManager.swift
//  Project:    Swiftfire
//
//  Version:    1.3.1
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
// 1.3.1 - Fixed recursive session thread bug
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation


public final class SessionManager {
    
    
    /// The queue on which all sessions functions run
    
    private static var queue: DispatchQueue = DispatchQueue(
        label: "Sessions",
        qos: DispatchQoS.userInitiated,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil
    )
    
    private static var peridocPurgeQueue: DispatchQueue = DispatchQueue(
        label: "PeriodicSessionPurge",
        qos: DispatchQoS.userInitiated,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil
    )
    
    /// Enable or disable the session log
    
    public var loggingEnabled: Bool {
        set {
            SessionManager.queue.sync {
                self._loggingEnabled = newValue
            }
        }
        get {
            return SessionManager.queue.sync {
                return self._loggingEnabled
            }
        }
    }
    
    private var _loggingEnabled: Bool = false
    
    
    /// The directory in which the session information will be stored if it denotes a directory. No session information will be stored if left (or set to) nil.
    
    private var logDir: URL
    
    
    /// The dictionary with active sessions.
    
    private var active: Dictionary<UUID, Session> = [:]
    
    
    /// Create a new sessions object
    
    public init?(loggingDirectory dir: URL?) {
        guard let dir = dir else { return nil }
        logDir = dir
        periodicPurge()
    }
    
    
    /// If there is an active session for the given id, and the session is not already in use, then return that session. If there is no session, it returns .none.
    ///
    /// - Note: If a session is no longer active, it will be removed from the session storage.
    ///
    /// - Parameters:
    ///   - id: The UUID that is the session.id.
    ///   - logId: Any log entry made will use this logId.
    ///
    /// - Returns: The requested session or nil.
    
    public func getActiveSession(for id: UUID, logId: Int) -> Session? {
        
        return SessionManager.queue.sync {
            
            [weak self] in
            guard let `self` = self else { return nil }
            
            
            // Find the session
            
            guard let session = self.active[id] else { return nil }
            
            
            // Verify it it is still active
            
            if session.isActiveKeepActive {
                
                return session
                
            } else {
                
                // The session is no longer active
                
                return nil
            }
        }
    }
    
    
    /// Creates a new session and adds it to the active sessions.
    
    public func newSession(address: String, domainName: String, logId: Int, connectionId: Int, allocationCount: Int, timeout: Int) -> Session? {
        return SessionManager.queue.sync {
            [weak self] in
            guard let `self` = self else { return nil }
            let session = Session(address: address, domainName: domainName, connectionId: connectionId, allocationCount: allocationCount, timeout: timeout)
            self.active[session.id] = session
            Log.atInfo?.log("Created session with id = \(session.id.uuidString)")
            return session
        }
    }
    
    
    /// This task will activate periodically to remove inactive sessions.
    
    private func periodicPurge() {
        removeInactiveSessions()
        SessionManager.peridocPurgeQueue.asyncAfter(deadline: DispatchTime.now() + 3600.0, execute: periodicPurge)
    }
    
    
    /// Remove all inactive sessions. Sessions are considered inactive when the last activity on that session was longer ago than the timout.
    
    private func removeInactiveSessions() {
        for (key, session) in active {
            if session.isExclusive { continue }
            if session.hasExpired {
                removeSession(key)
            }
        }
    }
    
    
    /// Remove a session from the active sessions list.
    
    private func removeSession(_ id: UUID) {
        guard let session = active[id] else { return }
        if _loggingEnabled { storeSession(session) }
        active[id] = nil
        Log.atInfo?.log("Purged inactive session for \(id.uuidString)")
    }
    
    
    /// Stores the data of a session to disk, if a valid Sessions.storeUrl is specified.
    
    private func storeSession(_ session: Session) {
        let content = session.json.code
        let dateForName = Date(timeIntervalSince1970: TimeInterval(session.started))
        let uuidForName = session.id.uuidString
        let fileName = "\(dateFormatter.string(from: dateForName))-\(uuidForName)"
        let fileUrl = logDir.appendingPathComponent(fileName).appendingPathExtension("json")
        try? content.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
    }
}
