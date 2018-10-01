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

let BUFFER_SIZE: Int = 1024 * 64

open class VVClient: VVSocket {
    var _socket: Int32 = -1
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
        
        self._socket = Darwin.socket(info!.pointee.ai_family, info!.pointee.ai_socktype, info!.pointee.ai_protocol)
        print("self.clientSocket: \(self._socket)")
        try? self.ignoreSIGPIPE(self._socket)
        status = Darwin.connect(self._socket, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
        print("status: \(status) self.clientSocker: \(self._socket)")
        if targetInfo != nil {
            freeaddrinfo(targetInfo)
        }
        
        checkClientReceive(socket: self._socket)
    }
    
    open func send(_ str: String) {
        if self._socket == -1 {
            print("fatal error! _socket: \(self._socket)")
            return
        }
        
        str.utf8CString.withUnsafeBufferPointer() {
            let s = Darwin.send(_socket, $0.baseAddress!, $0.count - 1, 0)
            print("s: \(s) __socket: \(_socket)")
        }
    }
    
    
    override func dataReceived(socket: Int32, data: NSData) {
        if let str = NSString(bytes: data.bytes, length: data.length, encoding: String.Encoding.utf8.rawValue) {
            print("loadRecved: \(str.length)")
            
            if str.hasPrefix("postNoti|-|") {
                let arr = str.components(separatedBy: "|-|")
                // TODO: check array boundary
                self.delegate?.vvIPCNotificationReceived(arr[1], userInfoData: arr[2])
            } else {
                self.delegate?.vvIPCDataRecieve(str as String)
            }
 
        }
    }
    
    func closeSocket() {
        if self._socket > 0 {
            // will trigger recv count = 0
            _ = Darwin.close(self._socket)
        }
        self._socket = -1
    }
    
    deinit {
        self.closeSocket()
        print("vvclient deinit!!")
    }
}
