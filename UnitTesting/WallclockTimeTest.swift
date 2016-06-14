//
//  WallclockTimeTest.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 13/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import XCTest

class WallclockTimeTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCreation() {

        let a = WallclockTime(hour: 123, minute: 456, second: 7890)
        
        XCTAssertEqual(a.hour, 12)
        XCTAssertEqual(a.minute, 47)
        XCTAssertEqual(a.second, 30)
        
        XCTAssertEqual(a.description, "12:47:30")
        
        XCTAssertNil(WallclockTime(string: ""), "Should not create a wallclock time from an empty string")
        
        XCTAssertNil(WallclockTime(string: "A"), "Should not create a wallclock time from an \"A\" string")
        
        var b = WallclockTime(string: ":")!
        XCTAssertEqual(b.description, "0:0:0")

        b = WallclockTime(string: "4")!
        XCTAssertEqual(b.description, "0:0:4")

        b = WallclockTime(string: ":4")!
        XCTAssertEqual(b.description, "0:0:4")
        
        b = WallclockTime(string: "5:4")!
        XCTAssertEqual(b.description, "0:5:4")

        b = WallclockTime(string: ":5:4")!
        XCTAssertEqual(b.description, "0:5:4")

        b = WallclockTime(string: "3:5:4")!
        XCTAssertEqual(b.description, "3:5:4")

        XCTAssertNil(WallclockTime(string: ":3:4:5"), "Should not create a wallclock time from an \":3:4:5\" string")

        
        let aDate = NSDate(string: "2001-03-24 10:45:32 +0000")!
        let aWallclockTime = aDate.wallclockTime
        
        XCTAssertEqual(aWallclockTime.description, "11:45:32") // Note this uses the currentCalendar which in my case is +0100
    }
    
    func testArithmetic() {
        
        let a = WallclockTime(hour: 4, minute: 5, second: 6)
        let b = WallclockTime(hour: 4, minute: 5, second: 6)
        
        let c = a + b
        
        XCTAssertEqual(c.time.description, "8:10:12")
        XCTAssertFalse(c.tomorrow)
        
        let d = WallclockTime(hour: 23, minute: 59, second: 59)
        let e = WallclockTime(string: "1")!
        
        let f = d + e
        
        XCTAssertEqual(f.time.description, "0:0:0")
        XCTAssertTrue(f.tomorrow)

        let g = d + a
        
        XCTAssertEqual(g.time.description, "4:5:5")
        XCTAssertTrue(g.tomorrow)
        
        let aDate = NSDate(string: "2001-03-24 10:45:32 +0000")!
        let h = aDate + e
        
        XCTAssertEqual(h.wallclockTime.description, "11:45:33") // Note this uses the currentCalendar which in my case is +0100
    }
    
    func testCompare() {
        
        let a = WallclockTime(hour: 4, minute: 5, second: 6)
        let b = WallclockTime(hour: 4, minute: 5, second: 6)
        
        XCTAssertTrue(a == b)
        XCTAssertEqual(a, b)
        
        let c = b + WallclockTime(hour: 0, minute: 0, second: 1)
        
        XCTAssertTrue(c.time > b)
        XCTAssertTrue(c.time != b)
        XCTAssertTrue(c.time >= b)
        XCTAssertTrue(b < c.time)
        XCTAssertTrue(b <= c.time)
    }
}
