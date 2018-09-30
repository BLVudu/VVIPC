//
//  VVServer.swift
//  VVIPC
//
//  Created by Pinghsien Lin on 9/30/18.
//  Copyright © 2018 Pinghsien Lin. All rights reserved.
//

import Foundation
open class VVServer {
    var serverSocketFd: Int32 = -1
    
    var clientSocketFd: Int32 = -1
    
    public init() {
        
    }
    
    open func start() {
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let strongSelf = self else { return }
            do {
                try strongSelf.createServerSocketAndListen()
                print("server listening...")
                
                strongSelf.acceptingClientSocket()
                print("accepted clientSocketFd: \(strongSelf.clientSocketFd), serverSocketFd: \(strongSelf.serverSocketFd)")
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
        
        
        let status: Int32 = getaddrinfo(nil, "14112", &hints, &targetInfo)
        if status != 0 {
            throw Error("server socket getting address error")
        }
        
        print("status \(status)")
        
        let info = targetInfo
        
        // TODO: this should be in background queue
        
        let bound = Darwin.bind(self.serverSocketFd, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
        if bound != 0 {
            throw Error("server socket bind error")
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
                        self.clientSocketFd = fd
                        try self.ignoreSIGPIPE(self.clientSocketFd)
                    } catch let err {
                        print(err)
                        return
                    }
                }
            }
        }
    }
    
    open func serverSend(_ str: String) {
        if self.clientSocketFd == -1 {
            print("fatal error!")
            return
        }
        
        
        
        str.utf8CString.withUnsafeBufferPointer() {
            let s = Darwin.send(self.clientSocketFd, $0.baseAddress!, $0.count - 1, 0)
            print("s: \(s) self.clientSocket: \(self.clientSocketFd)")
        }
    }
    
    open func postNotification(_ str: String, userInfoData: String = "") {
        // I know... it should be a better way of doing this.
        self.serverSend("postNoti|-|\(str)|-|\(userInfoData)")
    }
    
    private func ignoreSIGPIPE(_ fd: Int32) throws {
        
        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            throw Error("setsockopt SO_NOSIGPIPE error")
        }
        
    }

    deinit {
        print("deinit server socket")
        if self.serverSocketFd > 0 {
            _ = Darwin.shutdown(self.serverSocketFd, Int32(SHUT_RDWR))
        }
        // VVClient also needs to be closed?
        if self.clientSocketFd > 0 {
            _ = Darwin.close(self.clientSocketFd)
        }
        
        self.serverSocketFd = -1
        self.clientSocketFd = -1
        
    }
}
