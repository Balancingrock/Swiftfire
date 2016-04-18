//
//  UInt8BufferTest.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 15/03/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import XCTest

class UInt8BufferTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {

        let buf = UInt8Buffer(sizeInBytes: 100)
        
        XCTAssertEqual(buf.size, 100)
        XCTAssertEqual(buf.fill, 0)
    }
    
    func testAdd() {
        
        let buf = UInt8Buffer(sizeInBytes: 20)
        
        XCTAssertEqual(buf.size, 20)
        XCTAssertEqual(buf.fill, 0)

        buf.add("12345".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        XCTAssertEqual(buf.size, 20)
        XCTAssertEqual(buf.fill, 5)
        XCTAssertEqual(buf.ptr.count, 5)
        XCTAssertEqual(buf.stringValue, "12345")

        buf.add("12345".dataUsingEncoding(NSUTF8StringEncoding)!)

        XCTAssertEqual(buf.size, 20)
        XCTAssertEqual(buf.fill, 10)
        XCTAssertEqual(buf.ptr.count, 10)
        XCTAssertEqual(buf.stringValue, "1234512345")

        buf.add("abcdeabcde".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        XCTAssertEqual(buf.size, 20)
        XCTAssertEqual(buf.fill, 20)
        XCTAssertEqual(buf.ptr.count, 20)
        XCTAssertEqual(buf.stringValue, "1234512345abcdeabcde")
    }
    
    func testInit2() {
        
        let buf = UInt8Buffer(sizeInBytes: 20)
        
        XCTAssertEqual(buf.size, 20)
        XCTAssertEqual(buf.fill, 0)
        
        buf.add("12345".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        XCTAssertEqual(buf.size, 20)
        XCTAssertEqual(buf.fill, 5)
        XCTAssertEqual(buf.ptr.count, 5)
        XCTAssertEqual(buf.stringValue, "12345")

        let buf2 = UInt8Buffer(from: buf, startByteOffset: 1, endByteOffset: 3)
        
        XCTAssertEqual(buf2.size, 3)
        XCTAssertEqual(buf2.fill, 3)
        XCTAssertEqual(buf2.ptr.count, 3)
        XCTAssertEqual(buf2.stringValue, "234")

    }
}
