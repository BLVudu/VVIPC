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
    func vvIPCDataRecieveError() {
        
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
//        let server = VVIPCUITest()
        VVIPCUITest.shared.start()
        sleep(1)
        
        VVIPC.shared.connect(delegate: self)
//        client.checkClientReceive()
        sleep(1)
        VVIPCUITest.shared.send("asdf")
//        var str = ""
//        for _ in 0..<100000 {
//            str += "abcdefghij"
//        }
//        print("strcount: \(str.count)")
//        server.send("\u{01}abbbb\u{02}\u{01}ccccc\u{02}")
//        server.send("abbbccbcbcbsdf asdff ssssss  sdfsdfdsfdfasdfsabccccc")
//        server.send(str)
//        client.send("asdfasdkflahfl kasjhdfl sdfasdf")
//        client.getFile("fil\"Hi") { str in
//            print("aa \(str)")
//        }
//        server.postNotification("networkNotification", userInfo: ["userId":"11223"])
//        server.postNotification("networkNotification", userInfo: ["userId":"11223", "uaaa": "bbb"])
//        server.postNotification("networkNotification")
        sleep(1)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
