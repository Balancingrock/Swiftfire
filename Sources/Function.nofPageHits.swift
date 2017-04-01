//
//  Function.nofPageHits.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 31/03/17.
//
//

import Foundation
import SwiftfireCore


/// Returns the number of hits for a resource.
///
/// If the arguments contain a String, then the string will be intepreted as a resource path (relative to the domain) and the count for that resource will be returned.
///
/// If the argument does not contain any arguments, it will return the count for the currently requested resource.

func sf_nofPageHits(_ args: Function.Arguments, _ info: inout Function.Info, _ environment: Function.Environment) -> Data? {
    
    var count: Int64 = -1
    
    var path: String?
    
    if case .array(let arr) = args {
        if arr.count > 0 {
            if let p = arr[0] as? String {
                path = p
            }
        }
    }
    
    if path == nil {
        path = environment.chainInfo[Service.ChainInfoKey.relativeResourcePathKey] as? String
    }

    if let path = path {
        count = statistics.foreverCount(domain: environment.domain.name, path: path)
    }

    Log.atDebug?.log(id: (environment.connection as! SFConnection).logId, source: #file.source(#function, #line), message: "ForeverCount for \(path) = \(count)")

    return count.description.data(using: String.Encoding.utf8)
}
