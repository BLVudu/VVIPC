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

import Foundation



open class VVClient: VVSocket {

    weak var delegate: VVIPCDelegate? = nil
    
    open func connect(delegate: VVIPCDelegate?) {
        self.delegate = delegate
        
        var hints = addrinfo(
            ai_flags: AI_PASSIVE,
            ai_family: 0,
            ai_socktype: 1,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil)
        var targetInfo: UnsafeMutablePointer<addrinfo>?
        
        // Retrieve the info on our target...
        var status: Int32 = getaddrinfo("127.0.0.1", "14112", &hints, &targetInfo)
        
        
        let info = targetInfo
        
        self.socketId = Darwin.socket(info!.pointee.ai_family, info!.pointee.ai_socktype, info!.pointee.ai_protocol)
        print("self.clientSocket: \(self.socketId)")
        try? self.ignoreSIGPIPE(self.socketId)
        status = Darwin.connect(self.socketId, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
        print("status: \(status) self.clientSocker: \(self.socketId)")
        if targetInfo != nil {
            freeaddrinfo(targetInfo)
        }
        
        checkClientReceive()
    }

    var callback: ((String) -> Void)? = nil
    
    open func getFile(_ fileName: String) {
        if self.socketId == -1 {
            print("fatal error! get file _socket: \(self.socketId)")
            return
        }
        
        let str = "getFile|-|" + fileName
        
        self.callback = { str in
            print("call back string")
        }
        
        self.send(str)
    }
    
    
    override func dataReceived(_ data: Data) {
        
        guard let str = String(data: data, encoding: .utf8) else {
            print("client dataReceived error;")
            return
        }
        
        print("dataReceived: \(str)")
        
        if str.hasPrefix("postNoti|-|") {
            let arr = str.components(separatedBy: "|-|")
            // TODO: check array boundary
            self.delegate?.vvIPCNotificationReceived(arr[1], userInfoData: arr[2])
        } else if str.hasPrefix("gotFile|-|") {
            let arr = str.components(separatedBy: "|-|")
            print("got file content: \(arr[1])")
            // TODO: check array boundary
//                self.delegate?.vvIPCNotificationReceived(arr[1], userInfoData: arr[2])
        } else {
            self.delegate?.vvIPCDataRecieve(str as String)
        }
 
        
    }
    
    func closeSocket() {
        if self.socketId > 0 {
            // will trigger recv count = 0
            _ = Darwin.close(self.socketId)
        }
        self.socketId = -1
    }
    
    deinit {
        self.closeSocket()
        print("vvclient deinit!!")
    }
}
