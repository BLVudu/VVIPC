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
    func vvIPCDataRecieve(_ str: String)
    func vvIPCDataRecieveError(_ error: Error) // TODO: some errors
    func vvIPCNotificationReceived(_ str: String, userInfoData: String)
}

// should be on main target
extension VVIPCDelegate {
    public func vvIPCNotificationReceived(_ name: String, userInfoData: String) {
        print("post name: \(name) userInfoData: \(userInfoData)")
        let userInfo = ["data": userInfoData]
        NotificationCenter.default.post(name: Notification.Name(name), object: self, userInfo: userInfo)
    }
}
public struct Error: Swift.Error, CustomStringConvertible {
    let reason: String
    init(_ reason: String) {
        self.reason = reason
    }
    public var description: String {
        return "Error: \(self.reason)"
    }
}


open class VVIPC {
    public init() {
        
    }
    
    deinit {

        if self.socketfd > 0 {
            _ = Darwin.shutdown(self.socketfd, Int32(SHUT_RDWR))
        }

        if self.clientSocket > 0 {
            _ = Darwin.close(self.clientSocket)
        }

        self.socketfd = -1
        self.clientSocket = -1

        self.readBuffer.deallocate()
        print("deinit!!")
    }
    
    weak var delegate: VVIPCDelegate? = nil
    
    var socketfd: Int32 = -1
    var clientSocket: Int32 = -1
    var addr: sockaddr_in? = nil
    var clientAddr: sockaddr_in? = nil
    var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 4096)
    var readStorage: NSMutableData = NSMutableData(capacity: 4096)!
    
    open func serverStart() {
        self.listen()
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.acceptingClientSocket()
        }
    }
    
    open func serverSend(_ str: String) {
        if self.clientSocket == -1 {
            print("fatal error!")
            return
        }
        
        
        
        str.utf8CString.withUnsafeBufferPointer() {
            let s = Darwin.send(self.clientSocket, $0.baseAddress!, $0.count - 1, 0)
            print("s: \(s) self.clientSocket: \(self.clientSocket)")
        }
    }
    
    open func postNotification(_ str: String, userInfoData: String = "") {
        // I know... it should be a better way of doing this.
        self.serverSend("postNoti|-|\(str)|-|\(userInfoData)")
    }
    
    private func send(socket: Int32) {
        
    }
    
    func listen() {
        // Int32(AF_INET) = 2
        // SOCK_STREAM = 1
        // Int32(IPPROTO_TCP) = 6
        // IPv4 TCP
        self.socketfd = socket(Int32(AF_INET), SOCK_STREAM, Int32(IPPROTO_TCP))
        
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
        
        let a = Darwin.listen(self.socketfd, Int32(10))
        print("listen: \(a)")
    }
    
    open func acceptingClientSocket() {
        
        
        var addrStorage = sockaddr_storage()
        var length = socklen_t(MemoryLayout.size(ofValue: addrStorage))
        withUnsafeMutablePointer(to: &addrStorage) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addrPointer in
                withUnsafeMutablePointer(to: &length) { lengthPointer in
                    
                    let fd = Darwin.accept(self.socketfd, addrPointer, lengthPointer)
                    if fd < 0 {
                        print("Error: Socket accept failed.")
                        return
                    }
                    
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
        print("self.clientSocket: \(self.clientSocket)")
        try? self.ignoreSIGPIPE(on: self.clientSocket)
        status = Darwin.connect(self.clientSocket, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
        print("status: \(status) self.clientSocker: \(self.clientSocket)")
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
        print("recvFlags: \(recvFlags) clientSocket: \(self.clientSocket)")
        
        DispatchQueue.global(qos: .default).async {
            var recvCount: Int = 0 // should always return greater then 0
            repeat {
                
                recvCount = Darwin.recv(self.clientSocket, self.readBuffer, 4096, recvFlags)
                if let data = NSMutableData(capacity: 4096) {
                    data.append(self.readBuffer, length: recvCount)
                    data.append(self.readStorage.bytes, length: self.readStorage.length)
                    
                    if let str = NSString(bytes: data.bytes, length: data.length, encoding: String.Encoding.utf8.rawValue) {
                        if str.hasPrefix("postNoti|-|") {
                            let arr = str.components(separatedBy: "|-|")
                            // TODO: check array boundary
                            self.delegate?.vvIPCNotificationReceived(arr[1], userInfoData: arr[2])
                        } else {
                            self.delegate?.vvIPCDataRecieve(str as String)
                        }
                        
                        
                    }
                    
                }
                
                
//                self.delegate?.vvIPCDataRecieve()
            } while recvCount > 0
            
        }
        
        
        
    }
    
    private func ignoreSIGPIPE(on fd: Int32) throws {
        
        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            //throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
            fatalError()
        }
        
    }
}
