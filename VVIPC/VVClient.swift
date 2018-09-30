//
//  VVClient.swift
//  VVIPC
//
//  Created by Pinghsien Lin on 9/30/18.
//  Copyright © 2018 Pinghsien Lin. All rights reserved.
//

import Foundation
open class VVClient {
    var _socket: Int32 = -1
    weak var delegate: VVIPCDelegate? = nil
    
    var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 4096)
    var readStorage: NSMutableData = NSMutableData(capacity: 4096)!
    public init() {
        
    }
    
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
        try? self.ignoreSIGPIPE(on: self._socket)
        status = Darwin.connect(self._socket, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
        print("status: \(status) self.clientSocker: \(self._socket)")
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
        print("recvFlags: \(recvFlags) clientSocket: \(self._socket)")
        
        DispatchQueue.global(qos: .default).async {
            var recvCount: Int = 0 // should always return greater then 0
            repeat {
                
                recvCount = Darwin.recv(self._socket, self.readBuffer, 4096, recvFlags)
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
    
    deinit {

        if self._socket > 0 {
            _ = Darwin.close(self._socket)
        }
        
        self._socket = -1
        
        self.readBuffer.deallocate()
        print("vvclient deinit!!")
    }
}
