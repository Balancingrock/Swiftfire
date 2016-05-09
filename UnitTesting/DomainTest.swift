//
//  DomainTest.swift
//  Swifterfire
//
//  Created by Marinus van der Lugt on 09/01/15.
//  Copyright (c) 2015 Marinus van der Lugt. All rights reserved.
//

import Cocoa
import XCTest

class DomainTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testJson() {

        // Create a default domain and check if the json description is as expected
        
        let expectedResult = "{\"Domain\":{\"Name\":\"domain-name.extension\",\"IncludeWww\":true,\"Root\":\"root-folder\",\"ForewardUrl\":\"\",\"Enabled\":false}}"
        
        let domain = Domain()
        let str = domain.json.description

        XCTAssertEqual(str, expectedResult)
    }
}
