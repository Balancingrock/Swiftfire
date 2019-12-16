// =====================================================================================================================
//
//  File:       SessionInfo.swift
//  Project:    Swiftfire
//
//  Version:    1.3.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2019 Marinus van der Lugt, All rights reserved.
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
// 1.3.0 - Changed from struct to class (to make pass-by-reference default)
// 1.0.0 - Raised to v1.0.0, Removed old change log,
//
// =====================================================================================================================

import Foundation

import VJson
import Custom


/// The session information store
///
/// SessionInfo is alive as long as the session itself. Several minutes as a minimum, several hours is also possible. It is thus imperative _NOT_ to store any data structures here that are buffered in a cache. This could lead to duplicate instances once the content of the cache is replaced and another thread/session needs access to the account.

public class SessionInfo {
    
    public subscript(key: SessionInfoKey) -> CustomStringConvertible? {
        set { dict[key] = newValue }
        get { return dict[key] }
    }
    
    public func remove(key: SessionInfoKey) {
        dict.removeValue(forKey: key)
    }
    
    public var dict: Dictionary<SessionInfoKey, CustomStringConvertible> = [:]
    
    public var json: VJson {
        let json = VJson()
        for (key, value) in dict {
            json[key.rawValue] &= value.description
        }
        return json
    }
    
    public func userLogout() { remove(key: .accountUuidKey) }
}

extension SessionInfo {
    
    public func getAccount(inDomain domain: Domain?) -> Account? {
        guard let str = self[.accountUuidKey] as? String else { return nil }
        guard let uuid = UUID(uuidString: str) else { return nil }
        return domain?.accounts.getAccount(for: uuid)
    }
}

extension SessionInfo: CustomStringConvertible {
    
    public var description: String {
        return dict.map({ "\($0.key): \($0.value)" }).sorted().joined(separator: ",\n")
    }
}
