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
        
        let expectedResult = "\"Domain\":{\"Name\":\"domain.toplevel\",\"IncludeWww\":true,\"Root\":\"/Library/WebServer/Documents\",\"ForewardUrl\":\"\",\"Enabled\":false,\"AccessLogEnabled\":false,\"404LogEnabled\":false,\"Telemetry\":{\"NofRequests\":{\"Value\":0,\"GuiLabel\":\"Total Number of Requests\"},\"Nof200\":{\"Value\":0,\"GuiLabel\":\"Number of Succesfull Replies (200)\"},\"Nof400\":{\"Value\":0,\"GuiLabel\":\"Number of Bad Requests (400)\"},\"Nof403\":{\"Value\":0,\"GuiLabel\":\"Number of Forbidden (403)\"},\"Nof404\":{\"Value\":0,\"GuiLabel\":\"Number of Not Found (404)\"},\"Nof500\":{\"Value\":0,\"GuiLabel\":\"Number of Server Errors (500)\"},\"Nof501\":{\"Value\":0,\"GuiLabel\":\"Number of Not Implemented (501)\"},\"Nof505\":{\"Value\":0,\"GuiLabel\":\"Number of HTTP Version Not Supported (505)\"}}}"
        
        let domain = Domain()
        let str = domain.json.description

        XCTAssertEqual(str, expectedResult)
    }
}
