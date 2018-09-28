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

public protocol VVIPCDelegate: class {
    open func vvIPCDataRecieve(_ str: String)
    open func vvIPCDataRecieveError(_ error: Error) // TODO: some errors
    open func vvIPCNotificationReceived(_ str: String, userInfoData: String)
}

// should be on main target
extension VVIPCDelegate {
    open func vvIPCNotificationReceived(_ name: String, userInfoData: String) {
        print("===== post name: \(name) userInfoData: \(userInfoData)")
        let userInfo = ["data": userInfoData]
        NotificationCenter.default.post(name: Notification.Name(name), object: self, userInfo: userInfo)
    }
}

open class VVIPC {
    open init() {
        
    }
    
    weak var delegate: VVIPCDelegate? = nil
    
    var socketfd: Int32 = -1
    var clientSocket: Int32 = -1
    var addr: sockaddr_in? = nil
    var clientAddr: sockaddr_in? = nil
    var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 4096)
    var readStorage: NSMutableData = NSMutableData(capacity: 4096)!
    
    open func serverStart() {
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            self.listensocket()
        }
    }
    
    open func serverSend(_ str: String) {
        if self.clientSocket == -1 {
            print("fatal error!")
            return
        }
        
        
        
        str.utf8CString.withUnsafeBufferPointer() {
            let s = Darwin.send(self.clientSocket, $0.baseAddress!, $0.count - 1, 0)
            print("==again==== s: \(s) self.clientSocket: \(self.clientSocket)")
        }
    }
    
    open func postNotification(_ str: String, userInfoData: String = "") {
        // I know... it should be a better way of doing this.
        self.serverSend("postNoti|-|\(str)|-|\(userInfoData)")
    }
    
    private func send(socket: Int32) {
        
    }
    
    
    
    open func listensocket() {
        self.socketfd = socket(2, 1, 6)
        print(self.socketfd)
        do {
            try self.ignoreSIGPIPE(on: self.socketfd)
        } catch {
            print("err")
        }
        
        
        var hints = addrinfo(
            ai_flags: AI_PASSIVE,
            ai_family: 2,
            ai_socktype: 1,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil)
        var targetInfo: UnsafeMutablePointer<addrinfo>?
        
        // Retrieve the info on our target...
        let status: Int32 = getaddrinfo(nil, "14112", &hints, &targetInfo)
        
        print("status \(status)")
        
        let info = targetInfo

        if Darwin.bind(self.socketfd, info!.pointee.ai_addr, info!.pointee.ai_addrlen) == 0 {
            
            
        }
        
        print(Int(littleEndian: 42) == 42)
        
        let a = listen(self.socketfd, Int32(10))
        print("listen: \(a)")
        
        var addressStorage = sockaddr_storage()
        var addressStorageLength = socklen_t(MemoryLayout.size(ofValue: addressStorage))
        withUnsafeMutablePointer(to: &addressStorage) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addressPointer in
                withUnsafeMutablePointer(to: &addressStorageLength) { addressLengthPointer in
                    
                    let fd = Darwin.accept(self.socketfd, addressPointer, addressLengthPointer)
                    
                    do {
                        self.clientSocket = fd
                        try self.ignoreSIGPIPE(on: self.clientSocket)
                    } catch {
                        print("err")
                    }
                    print("accepted fd: \(fd) self.socketfd: \(self.socketfd)")
                    
                }
            }
        }
        
    }
    
    open func conn(delegate: VVIPCDelegate?) {
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
        
        self.clientSocket = Darwin.socket(info!.pointee.ai_family, info!.pointee.ai_socktype, info!.pointee.ai_protocol)
        print("====== self.clientSocket: \(self.clientSocket)")
        try? self.ignoreSIGPIPE(on: self.clientSocket)
        status = Darwin.connect(self.clientSocket, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
        print("===== status: \(status) self.clientSocker: \(self.clientSocket)")
        if targetInfo != nil {
            freeaddrinfo(targetInfo)
        }
        
        checkClientReceive()
    }
    
    open func checkClientReceive() {
        var recvFlags: Int32 = 0
        if self.readStorage.length > 0 {
            recvFlags |= Int32(MSG_DONTWAIT)
        }
        self.readBuffer.initialize(repeating: 0x0, count: 4096)
        print("===== recvFlags: \(recvFlags) clientSocket: \(self.clientSocket)")
        
        DispatchQueue.global(qos: .default).async {
            var recvCount: Int = 0 // should always return greater then 0
            repeat {
                print("===== coutn........")
                recvCount = Darwin.recv(self.clientSocket, self.readBuffer, 4096, recvFlags)
                if let data = NSMutableData(capacity: 4096) {
                    data.append(self.readBuffer, length: recvCount)
                    data.append(self.readStorage.bytes, length: self.readStorage.length)
                    print("===== coutn: \(recvCount) \(data)")
                    if let str = NSString(bytes: data.bytes, length: data.length, encoding: String.Encoding.utf8.rawValue) {
                        if str.hasPrefix("postNoti|-|") {
                            let arr = str.components(separatedBy: "|-|")
                            // TODO: check array boundary
                            self.delegate?.vvIPCNotificationReceived(arr[1], userInfoData: arr[2])
                        } else {
                            self.delegate?.vvIPCDataRecieve(str as String)
                        }
                        
                        print("===== str: \(str)")
                    }
                    
                }
                
                
//                self.delegate?.vvIPCDataRecieve()
            } while recvCount > 0
            
        }
        print("===== done count:")
        
        
    }
    
    private func ignoreSIGPIPE(on fd: Int32) throws {
        
        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            //throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
            fatalError()
        }
        
    }
}
