//
//  Contributed.swift
//  Swiftfire
//

import Foundation


// Very cool protocol with extension by Mattcomi
// From: http://mattcomi.tumblr.com/post/143043907238/struct-style-printing-of-classes-in-swift
//
// Usage: Simply extend a class with this protocol and the debug information looks fantastic (like the default struct debug information)

public protocol ReflectedStringConvertible : CustomStringConvertible { }

extension ReflectedStringConvertible {
    public var description: String {
        let mirror = Mirror(reflecting: self)
        
        var str = "\(mirror.subjectType)("
        var first = true
        for (label, value) in mirror.children {
            if let label = label {
                if first {
                    first = false
                } else {
                    str += ", "
                }
                str += label
                str += ": "
                str += "\(value)"
            }
        }
        str += ")"
        
        return str
    }
}