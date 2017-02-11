//
//  FunctionResult.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 09/02/17.
//
//

import Foundation

enum FunctionResult<T> {
    case error(message: String)
    case success(T)
}
