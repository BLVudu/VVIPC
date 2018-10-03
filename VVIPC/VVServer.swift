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
open class VVServer: VVSocket {
    var serverSocketFd: Int32 = -1
    
    open func start() {
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let strongSelf = self else { return }
            do {
                try strongSelf.createServerSocketAndListen()
                print("server listening...")
                
                strongSelf.acceptingClientSocket()
                print("accepted clientSocketFd: \(strongSelf.socketId), serverSocketFd: \(strongSelf.serverSocketFd)")
            } catch let err {
                print(err)
            }
        }
    }
    
    private func createServerSocketAndListen() throws {
        
        // Int32(AF_INET) = 2
        // SOCK_STREAM = 1
        // Int32(IPPROTO_TCP) = 6
        // IPv4 TCP
        self.serverSocketFd = Darwin.socket(Int32(AF_INET), SOCK_STREAM, Int32(IPPROTO_TCP))
        if self.serverSocketFd < 0 {
            throw Error("serverSocketFd created error")
        }
        print("server socket created: \(serverSocketFd)")
        
        try self.ignoreSIGPIPE(self.serverSocketFd)
        
        // reuse port:
        var on: Int32 = 1
        if setsockopt(self.serverSocketFd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            fatalError("reuse port error!!")
        }
        
        
        var hints = addrinfo(
            ai_flags: AI_PASSIVE,
            ai_family: 2,
            ai_socktype: 1, //SOCK_STREAM
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil)
        var targetInfo: UnsafeMutablePointer<addrinfo>?
        
        
        let status: Int32 = getaddrinfo(nil, SOCKET_PORT, &hints, &targetInfo)
        if status != 0 {
            throw Error("server socket getting address error")
        }
        
        print("status \(status)")
        
        var info = targetInfo
        
        // TODO: this should be in background queue
        while info != nil {
            let bound = Darwin.bind(self.serverSocketFd, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
            if bound == 0 {
                break
                
            }
            print("bind error! errno: \(errno)")
            fatalError("next bind!!!!!!")
            
            info = info?.pointee.ai_next
        }
        
        let lis = Darwin.listen(self.serverSocketFd, Int32(10))
        if lis < 0 {
            throw Error("server listen error")
        }
    }
    
    private func acceptingClientSocket() {
        
        
        var addrStorage = sockaddr_storage()
        var length = socklen_t(MemoryLayout.size(ofValue: addrStorage))
        withUnsafeMutablePointer(to: &addrStorage) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addrPointer in
                withUnsafeMutablePointer(to: &length) { lengthPointer in
                    
                    let fd = Darwin.accept(self.serverSocketFd, addrPointer, lengthPointer)
                    if fd < 0 {
                        print("Error: Socket accept failed.")
                        return
                    }
                    
                    do {
                        self.socketId = fd
                        try self.ignoreSIGPIPE(self.socketId)
                        
                        self.checkClientReceive()
                    } catch let err {
                        print(err)
                        return
                    }
                }
            }
        }
    }
    
    override func dataReceived(_ data: Data) {
        guard let cmd = VVCommand(data: data) else {
            print("convert to vvCommand error")
            return
        }
        
        if cmd.type == .getFile {
            // TODO: get body's file name
            print("filename: \(cmd.body)")
            self.send("thisis a file!!", commandType: .gotFile, commandId: cmd.id)
            return
        }
        
        // Note: not use yet
        if let cb = self.commands[cmd.id] {
            cb(cmd.body)
            self.commands[cmd.id] = nil
            return
        }
        
        // TODO:
        
        guard let str = String(data: data, encoding: .utf8) else {
            print("server dataReceived error;")
            return
        }
        
        print("on server \(socket) dataReceived: \(str)")
        
        if str.hasPrefix("getFile|-|") {
            let arr = str.components(separatedBy: "|-|")
            
            let fileName = arr[1]
            print("getfile: \(fileName)")
            self.send("gotFile|-|this is a file!!")
            
        } else {
//            self.delegate?.vvIPCDataRecieve(str as String)
        }
    }

    open func postNotification(_ name: String, userInfo: [String: String] = [:]) {

        let p = VVPostNotification(name: name, userInfo: userInfo)
        
        self.send(p.postBody, commandType: .postNotification, commandId: "")
    }
    
    open func shutdown() {
        print("shutdown")
        if self.serverSocketFd > 0 {
            _ = Darwin.shutdown(self.serverSocketFd, Int32(SHUT_RDWR))
        }
        // VVClient also needs to be closed?
        if self.socketId > 0 {
            // will trigger recv count = 0
            _ = Darwin.close(self.socketId)
        }
        
        self.serverSocketFd = -1
        self.socketId = -1
    }
    

    deinit {
        print("deinit server socket")
        self.shutdown()
        
    }
}
