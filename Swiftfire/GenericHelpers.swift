//
//  GenericHelpers.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 24/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation

infix operator ??= {}

func ??=<T> (inout lhs: T?, rhs: T) {
    if lhs == nil { lhs = rhs }
}

class SFError: NSError {
    init(message: String) {
        super.init(domain: "nl.balancingrock.swiftfire", code: -1, userInfo: [NSLocalizedDescriptionKey:message])
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented for SFError")
    }
}