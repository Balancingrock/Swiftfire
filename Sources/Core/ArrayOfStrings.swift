//
//  ArrayOfStrings.swift
//  Core
//
//  Created by Rien van der lugt on 01/08/2019.
//

import Foundation

import VJson


public struct ArrayOfStrings: Sequence {
    
    var list: Array<String>
    
    public var count: Int { return list.count }
    
    public mutating func remove(at index: Int) { list.remove(at: index) }
    
    public mutating func append(_ item: String) { list.append(item) }
    
    public subscript(index: Int) -> String {
        get {
            return list[index]
        }
        set {
            list[index] = newValue
        }
    }
    
    public func store(to file: URL?) {
        guard let file = file else { return }
        let json = VJson.array()
        list.forEach { (str) in
            json.append(str)
        }
        json.save(to: file)
    }
    
    public mutating func load(from file: URL?) {
        guard let file = file else { return }
        guard let json = try? VJson.parse(file: file) else { return }
        list = []
        json.forEach { if let str = $0.stringValue { list.append(str) } }
    }
    
    public init(_ values: Array<String> = []) {
        self.list = values
    }
    
    public struct DomainGenerator: IteratorProtocol {
        
        public typealias Element = String
        
        private var source: Array<String>
        
        public init(source: ArrayOfStrings) {
            self.source = source.list
        }
        
        // The GeneratorType protocol
        public mutating func next() -> Element? {
            
            // Only when the source has values to deliver
            if source.count > 0 {
                return source.removeFirst()
            }
            // Nothing left to send
            return nil
        }
    }
    
    public func makeIterator() -> DomainGenerator {
        return DomainGenerator(source: self)
    }
}
