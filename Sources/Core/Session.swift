// =====================================================================================================================
//
//  File:       Session.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Added nofRegistrationAttempts
// 1.0.0 - Raised to v1.0.0, Removed old change log,
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

import VJson
import SwifterLog
import Http
import Custom


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
    
    public var cookie: Cookie {
        return Session.queue.sync {
            let sessionTimeout = Cookie.Timeout.maxAge(self.timeout)
            return Cookie(name: Session.cookieId, value: id.uuidString, timeout: sessionTimeout, path: "/", domain: nil, secure: nil, httpOnly: true)
        }
    }
    
    
    /// The ID for this Session
    
    public let id: UUID = UUID()

    
    /// The time this session was started.
    
    public let started: Int64 = Date().javaDate
    
    
    /// The time this session was active for the last time.
    
    fileprivate(set) var lastActivity: Int64
    
    
    /// The number of registration attempts
    
    public var nofRegistrationAttempts: Int = 0
    
    
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
            if self.info.dict.count == 0 {
                str += " Session Info: Empty\n"
            } else {
                str += " Session Info:\n"
                str += self.info.description.components(separatedBy: "\n").map({"  \($0)"}).joined(separator: "\n")
                str += "\n"
            }
            str += " Session Debug Info:\n"
            str += self.debugInfo.description.components(separatedBy: "\n").map({" \($0)"}).joined(separator: "\n")
            return str
        }
    }
    

    /// Creates a new session
    
    init(address: String, domainName: String, connectionId: Int, allocationCount: Int, timeout: Int) {
        self.lastActivity = started
        self.timeout = timeout
        let info = DebugInfo(connectionId: connectionId, allocationCount: allocationCount, timestamp: started, clientIp: address)
        debugInfo.arr.append(info)
    }
    
    
    /// The JSON representation for the session.
    
    var json: VJson {
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
    
    private(set) var isExclusive: Bool = false
    
    
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


