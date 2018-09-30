//
//  VVIPCTests.swift
//  VVIPCTests
//
//  Created by Pinghsien Lin on 9/28/18.
//  Copyright © 2018 Pinghsien Lin. All rights reserved.
//

import XCTest
@testable import VVIPC



class VVIPCTests: XCTestCase, VVIPCDelegate {
    
    func vvIPCDataRecieve(_ str: String) {
        print("vvIPCDataRecieve: \(str)")
    }
    func vvIPCDataRecieveError(_ error: Error) {
        
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let server = VVServer()
        server.start()
        sleep(1)
        let client = VVClient()
        client.connect(delegate: self)
        client.checkClientReceive()
        server.serverSend("asdf")
//        let vvipc = VVIPC()
//        vvipc.serverStart()
//        sleep(2)
//        print(123)
//        print(123)
//        print(123)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
