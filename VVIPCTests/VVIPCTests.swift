/*
 * Copyright (C) 2018 VUDU inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


import XCTest
@testable import VVIPC



class VVIPCTests: XCTestCase, VVIPCDelegate {
    
    func vvIPCDataRecieve(_ str: String) {
        print("vvIPCDataRecieve: \(str.count)")
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
//        client.checkClientReceive()
        sleep(1)
        var str = ""
        for _ in 0..<1000000 {
            str += "abcdefghij"
        }
        print("strcount: \(str.count)")
//        server.send("a")
//        server.send(str)
        client.getFile("filHi")
//        sleep(1)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
