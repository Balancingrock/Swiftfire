// =====================================================================================================================
//
//  File:       Session.swift
//  Project:    Swiftfire
//
//  Version:    0.10.7
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
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
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
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
// 0.10.7 - Fixed bug: made info public.
//        - Added subscript access to SessionDictionary
//        - Renamed SessionDictionary to SessionInfo
// 0.10.6 - Initial release
//
// =====================================================================================================================
//
// Sessions can be used to create a statefull user experience.
//
// Sessions act as a storage for data that should be preserved across HttpRequests. In addition sessions can be used to
// guarantee a single (virtual) thread of execution. I.e. it is possible to ensure that multiple HttpRequests do not 
// corrupt the data in a session due to concurrent access.
//
// Session IDs are stored in http cookies and have a timout associated with them.
//
// =====================================================================================================================

import Foundation
import SwifterJSON
import SwifterLog


/// A record with debugging info. Specifically this record allows the developper to associate connections with sessions such that debugging information in the log (which also contains the connection id) can be associated with a session.

private struct DebugInfo: CustomStringConvertible {
    
    let connectionId: Int
    let allocationCount: Int
    let timestamp: Int64
    let clientIp: String
    
    var json: VJson {
        let json = VJson()
        json["ConnectionId"] &= connectionId
        json["AllocationCount"] &= allocationCount
        json["Timestamp"] &= timestamp
        json["ClientIp"] &= clientIp
        return json
    }
    
    var description: String {
        var str = "DebugInfo:\n"
        str += " ConnectionId:    \(connectionId)\n"
        str += " AllocationCount: \(allocationCount)\n"
        str += " Timestamp:       \(timestamp)\n"
        str += " ClientIp:        \(clientIp)"
        return str
    }
}


/// The array with debug information

private struct DebugInfoArray: CustomStringConvertible {
    
    var arr: Array<DebugInfo> = []
    
    var json: VJson {
        let json = VJson.array()
        arr.forEach({ json.append($0.json) })
        return json
    }
    
    var description: String {
        var str = ""
        if arr.count == 0 { str += "Empty" }
        str += arr.map({
            $0.description.components(separatedBy: "\n").map({ "  \($0)" }).joined(separator: "\n")
        }).joined(separator: ",\n")
        return str
    }
}


/// The session information store

public struct SessionInfo: CustomStringConvertible {
    
    public subscript(key: SessionInfoKey) -> CustomStringConvertible? {
        set { dict[key] = newValue }
        get { return dict[key] }
    }
    
    fileprivate var dict: Dictionary<SessionInfoKey, CustomStringConvertible> = [:]
    
    fileprivate var json: VJson {
        let json = VJson()
        for (key, value) in dict {
            json[key.rawValue] &= value.description
        }
        return json
    }
    
    public var description: String {
        return dict.map({ "\($0.key): \($0.value)" }).sorted().joined(separator: ",\n")
    }
}


/// The session for statefull client experiences.

public class Session: CustomStringConvertible {

    
    /// The queue on which all session functions run
    
    private static var queue: DispatchQueue = DispatchQueue(
        label: "Sessions",
        qos: DispatchQoS.userInitiated,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil
    )

    
    /// The Session ID name used in the cookies.
    
    public static let cookieId = "SessionId"

    
    // A cookie that will represent this session in the outgoing http response.
    
    public var cookie: HttpCookie {
        return Session.queue.sync {
            let sessionTimeout = HttpCookie.Timeout.maxAge(self.timeout)
            return HttpCookie(name: Session.cookieId, value: id.uuidString, timeout: sessionTimeout, path: "/", domain: nil, secure: nil, httpOnly: true)
        }
    }
    
    
    /// The ID for this Session
    
    public let id: UUID = UUID()

    
    /// The time this session was started.
    
    public let started: Int64 = Date().javaDate
    
    
    /// The time this session was used for the last time.
    
    public fileprivate(set) var lastActivity: Int64
    
    
    /// A custom dictionary for information that must be associated with the session.
    
    public var info: SessionInfo = SessionInfo()
    
    
    /// The timeout for this session in seconds.
    
    private var timeout: Int
    
    
    /// The session is expired if 'timeout' time has elapsed since the last update of 'lastActivity'.
    ///
    /// - Note: This function cannot be used to determine if the session is still active. Use 'isActiveKeepActive' to determine if the session is still active (and update 'lastActivity' in the process).
    
    public var hasExpired: Bool {
        let now = Date().javaDate
        return now > lastActivity + Int64(timeout * 1000)
    }
    
    
    /// Keeps the session active if it is still active. It does this by updating the 'lastActivity' to now if the session is still active.
    
    public var isActiveKeepActive: Bool {
        return Session.queue.sync {
            [weak self] in
            guard let `self` = self else { return false }
            let now = Date().javaDate
            if now <= self.lastActivity + Int64(self.timeout * 1000) {
                self.lastActivity = now
                return true
            } else {
                return false
            }
        }
    }
    
    
    /// The subscript operators to access the information in the session info store
    
    public subscript(key: SessionInfoKey) -> CustomStringConvertible? {
        set {
            Session.queue.async {
                [weak self] in
                guard let `self` = self else { return }
                self.info.dict[key] = newValue
            }
        }
        get {
            return Session.queue.sync {
                [weak self] in
                guard let `self` = self else { return "" }
                return self.info.dict[key]
            }
        }
    }
    
    
    /// Debugging information
    
    private var debugInfo = DebugInfoArray()

    
    /// Textual representation
    
    public var description: String {
        return Session.queue.sync {
            [weak self] in
            guard let `self` = self else { return "" }
            var str = "Session:\n"
            str += " Id: \(self.id.uuidString)\n"
            str += " Started: \(self.started)\n"
            str += " Last used:  \(self.lastActivity)\n"
            str += " Is Exclusive: \(self.isExclusive)\n"
            str += " Timeout: \(self.timeout) Seconds\n"
            str += " Has expired: \(self.hasExpired)\n"
            str += " Session Info:\n"
            str += self.info.description.components(separatedBy: "\n").map({"  \($0)"}).joined(separator: "\n")
            str += " Debug Info Array:\n"
            str += self.debugInfo.description.components(separatedBy: "\n").map({"  \($0)"}).joined(separator: "\n")
            return str
        }
    }
    

    /// Creates a new session
    
    fileprivate init(address: String, domainName: String, connectionId: Int, allocationCount: Int, timeout: Int) {
        self.lastActivity = started
        self.timeout = timeout
        let info = DebugInfo(connectionId: connectionId, allocationCount: allocationCount, timestamp: started, clientIp: address)
        debugInfo.arr.append(info)
    }
    
    
    /// The JSON representation for the session.
    
    fileprivate var json: VJson {
        return Session.queue.sync {
            [weak self] in
            guard let `self` = self else { return VJson() }
            let json = VJson()
            json["Id"] &= self.id.description
            json["Started"] &= self.started
            json["LastActivity"] &= self.lastActivity
            json["DebugInfo"] &= self.debugInfo.json
            json["SessionInfo"] &= self.info.json
            return json
        }
    }
    
    
    /// Adds an activity to the list of debug information. Also updates the 'lastActivity'.
    
    public func addActivity(address: String, domainName: String, connectionId: Int, allocationCount: Int) {
        Session.queue.async {
            [weak self] in
            guard let `self` = self else { return }
            self.lastActivity = Date().javaDate
            let info = DebugInfo(connectionId: connectionId, allocationCount: allocationCount, timestamp: self.lastActivity, clientIp: address)
            self.debugInfo.arr.append(info)
        }
    }
    
    
    /// For exclusive use of the session. If the value is true then exclusive use of this session has been granted.
    
    public private(set) var isExclusive: Bool = false
    
    
    /// Claim exclusivity of the session. Exclusivity can be used if a session must be protected again concurrent use by multiple connection requests.
    ///
    /// - Note: Exclusivity must be released before another connection request can gain exclusivity. If exclusivity is not released, it cannot be regained and the only way for the end-user to regain that functionality of the site is to time-out the session or erase the session-cookie.
    ///
    /// - Returns: 'True' if exclusivity was successfully claimed, 'false' otherwise.
    
    public func claimExclusivity() -> Bool {
        return Session.queue.sync {
            [weak self] in
            guard let `self` = self else { return false }
            if self.isExclusive { return false }
            self.isExclusive = true
            return true
        }
    }
    
    
    /// Release exclusivity of the session
    
    public func releaseExclusivity() {
        Session.queue.async {
            [weak self] in
            guard let `self` = self else { return }
            self.lastActivity = Date().javaDate // prevent immediate removal of session from the active list when releasing it
            self.isExclusive = false
        }
    }
}


public final class Sessions: CustomStringConvertible {

    
    /// The time format used for the filenames
    
    private static var fileNameFormatter: DateFormatter = {
        let ltf = DateFormatter()
        ltf.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSSZ"
        return ltf
    }()

    
    /// The queue on which all sessions functions run
    
    private static var queue: DispatchQueue = DispatchQueue(
        label: "Sessions",
        qos: DispatchQoS.userInitiated,
        attributes: DispatchQueue.Attributes(),
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
        target: nil
    )
    
    
    /// The directory in which the session information will be stored if it denotes a directory. No session information will be stored if left (or set to) nil.
    
    public var logDirUrl: URL? {
        set {
            Sessions.queue.sync {
                [weak self] in
                self?._logDirUrl = newValue
            }
        }
        get {
            return Sessions.queue.sync {
                [weak self] in
                return self?._logDirUrl
            }
        }
    }
    
    private var _logDirUrl: URL?
    
    
    /// The total number of active sessions.
    ///
    /// - Note: The expired sessions will be removed before the tally is made.
    
    public var count: Int {
        return Sessions.queue.sync {
            
            [weak self] in
            guard let `self` = self else { return 0 }
            
            self.removeInactiveSessions()
            return self.active.count
        }
    }
    
    
    /// The dictionary with active sessions.
    
    private var active: Dictionary<UUID, Session> = [:]
    
    
    /// Create a textual representation
    
    public var description: String {
        
        return Sessions.queue.sync {
            
            [weak self] in
            guard let `self` = self else { return "*** nil ***" }

            var str = "Sessions:\n"
            str += " Logging dir:   \(self._logDirUrl?.path ?? "None")\n"
            str += " Session count: \(self.active.count)\n"
            
            if self.active.count == 0 {
                str += " Sessions: None"
            } else {
                str += " Sessions:\n"
                str += self.active.map({ " \($0.value)"}).joined(separator: "\n")
            }
            
            return str
        }
    }
    
    
    /// Create a new sessions object
    
    public init(logDirUrl: URL? = nil) {
        _logDirUrl = logDirUrl
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
    
    public func getActiveSession(for id: UUID, logId: Int32) -> Session? {
        
        return Sessions.queue.sync {
            
            [weak self] in
            guard let `self` = self else { return nil }

            
            // Find the session
            
            guard let session = self.active[id] else { return nil }
                
            
            // Verify it it is still active
            
            if session.isActiveKeepActive {
                
                return session
                
            } else {
                
                // The session is no longer active
                
                self.removeInactiveSessions()
                
                return nil
            }
        }
    }
    
    
    /// Creates a new session and adds it to the active sessions.
    
    public func newSession(address: String, domainName: String, logId: Int32, connectionId: Int, allocationCount: Int, timeout: Int) -> Session? {
        return Sessions.queue.sync {
            [weak self] in
            guard let `self` = self else { return nil }
            let session = Session(address: address, domainName: domainName, connectionId: connectionId, allocationCount: allocationCount, timeout: timeout)
            self.active[session.id] = session
            SwifterLog.atInfo?.log(id: logId, source: #file.source(#function, #line), message: "Created session with id = \(session.id.uuidString)")
            return session
        }
    }
    
    
    /// This task will activate periodically to remove inactive sessions.
    
    private func periodicPurge() {
        removeInactiveSessions()
        Sessions.queue.asyncAfter(deadline: DispatchTime.now() + 3600.0, execute: periodicPurge)
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
        storeSession(session)
        active[id] = nil
        SwifterLog.atInfo?.log(id: -1, source: #file.source(#function, #line), message: "Purged inactive session for \(id.uuidString)")
    }
    
    
    /// Stores the data of a session to disk, if a valid Sessions.storeUrl is specified.
    
    private func storeSession(_ session: Session) {
        guard let logDirUrl = _logDirUrl else { return }
        let content = session.json.code
        let dateForName = Date(timeIntervalSince1970: TimeInterval(session.started))
        let uuidForName = session.id.uuidString
        let fileName = "\(Sessions.fileNameFormatter.string(from: dateForName))-\(uuidForName)"
        let fileUrl = logDirUrl.appendingPathComponent(fileName).appendingPathExtension("json")
        try? content.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
    }
}
