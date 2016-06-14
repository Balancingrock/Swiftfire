//
//  ValueStatisticsTest.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 11/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import XCTest

class ValueStatisticsTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValueStatistics() {

        let vs = ValueStatistics(value: "Value")
        
        var expected = "{\"Value\":\"Value\",\"Count\":0,\"ResetableCount\":0}"
        
        XCTAssertEqual(vs.json.description, expected)
    
        vs.increment()
        expected = "{\"Value\":\"Value\",\"Count\":1,\"ResetableCount\":1}"
        XCTAssertEqual(vs.json.description, expected)
        
        vs.increment()
        expected = "{\"Value\":\"Value\",\"Count\":2,\"ResetableCount\":2}"
        XCTAssertEqual(vs.json.description, expected)

        vs.reset()
        expected = "{\"Value\":\"Value\",\"Count\":2,\"ResetableCount\":0}"
        XCTAssertEqual(vs.json.description, expected)

        vs.increment()
        expected = "{\"Value\":\"Value\",\"Count\":3,\"ResetableCount\":1}"
        XCTAssertEqual(vs.json.description, expected)
        
        do {
            let j = try VJson.createJsonHierarchy(expected)
            if let sv = ValueStatistics<String>(json: j) {
                XCTAssertEqual(sv.json.description, expected)
            } else {
                XCTFail()
            }
        } catch {
            XCTFail()
        }
    }

    func testValuesStatistics() {
        
        var vs = ValuesStatistics<String>(maxCount: 10)
        
        var expected = "{\"MaxCount\":10,\"Values\":[]}"
        
        XCTAssertEqual(vs.json.description, expected)
        
        
        vs.addOrCount("Test")
        expected = "{\"MaxCount\":10,\"Values\":[{\"Value\":\"Test\",\"Count\":1,\"ResetableCount\":1}]}"
        XCTAssertEqual(vs.json.description, expected)

        vs.addOrCount("Hitchhiker")
        expected = "{\"MaxCount\":10,\"Values\":[{\"Value\":\"Test\",\"Count\":1,\"ResetableCount\":1},{\"Value\":\"Hitchhiker\",\"Count\":1,\"ResetableCount\":1}]}"
        XCTAssertEqual(vs.json.description, expected)

        vs.addOrCount("Test")
        expected = "{\"MaxCount\":10,\"Values\":[{\"Value\":\"Test\",\"Count\":2,\"ResetableCount\":2},{\"Value\":\"Hitchhiker\",\"Count\":1,\"ResetableCount\":1}]}"
        XCTAssertEqual(vs.json.description, expected)

        vs.reset()
        expected = "{\"MaxCount\":10,\"Values\":[{\"Value\":\"Test\",\"Count\":2,\"ResetableCount\":0},{\"Value\":\"Hitchhiker\",\"Count\":1,\"ResetableCount\":0}]}"
        XCTAssertEqual(vs.json.description, expected)

        vs.addOrCount("Hitchhiker")
        expected = "{\"MaxCount\":10,\"Values\":[{\"Value\":\"Test\",\"Count\":2,\"ResetableCount\":0},{\"Value\":\"Hitchhiker\",\"Count\":2,\"ResetableCount\":1}]}"
        XCTAssertEqual(vs.json.description, expected)
    }
    
    func testDomainStatistics() {
        
        let resourceFile = Logfile(
            filename: "Resource-Statistics",
            fileExtension: "txt",
            directory: nil,
            options: Logfile.InitOption.NewFileAfterDelay(WallclockTime(hour: 1, minute: 0, second: 0)))!
        
        let ipFile = Logfile(
            filename: "Ip-Statistics",
            fileExtension: "txt",
            directory: nil,
            options: Logfile.InitOption.NewFileAfterDelay(WallclockTime(hour: 1, minute: 0, second: 0)))!
        
        var ds = DomainStatistics(resourceFile: resourceFile, ipFile: ipFile)
        
        
        // Create empty logfiles
        
        ds.save()
        
        
        // Create an entry
        
        var connection = HttpConnection()
        connection.clientIp = "72.83.94.5"
        var httpHeader = HttpHeader(lines: ["GET /index.html HTTP/1.1\n", "Host: localhost:6678\n\n"])
        
        ds.record(httpHeader, connection: connection)
        
        ds.save()
        
        connection = HttpConnection()
        connection.clientIp = "72.83.94.6"
        httpHeader = HttpHeader(lines: ["GET /index.html HTTP/1.1\n", "Host: localhost:6678\n\n"])
        
        ds.record(httpHeader, connection: connection)
        
        connection = HttpConnection()
        connection.clientIp = "72.83.94.5"
        httpHeader = HttpHeader(lines: ["GET /tweet.html HTTP/1.1\n", "Host: localhost:6678\n\n"])
        
        ds.record(httpHeader, connection: connection)
        
        connection = HttpConnection()
        connection.clientIp = "72.83.94.7"
        httpHeader = HttpHeader(lines: ["GET /three.html HTTP/1.1\n", "Host: localhost:6678\n\n"])
        
        ds.record(httpHeader, connection: connection)

        ds.save()
        
        
        // Some time to allow the 'save' to complete
        
        sleep(1)

        // The logilfes (2x 3) should be in "/<user>/Library/Application Support/xctest/logfiles"
        
        ipFile.close()
        resourceFile.close()
    }
}
