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


open class VVSocket {
    var socketId: Int32 = -1
    var buf: Data = Data(capacity: BUFFER_SIZE)
    
    var commands: [String: Callback] = [:]
    var commandId: Int = 0
    
    public init () {
        
    }
    
    
    open func checkClientReceive() {
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            repeat {
                guard let socket = self?.socketId, socket > 0 else {
                    break;
                }
                self?.loadRecv()
            } while true
        }
    }
    
    
    
    private func loadRecv() {
        let start: UInt8 = UInt8(DELIMITER_START.data(using: .utf8)![0])
        let end: UInt8 = UInt8(DELIMITER_END.data(using: .utf8)![0])
        
        let currentBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: BUFFER_SIZE)
        print("clientSocket: \(self.socketId)")
        
        repeat {
            let recvCount = Darwin.recv(self.socketId, currentBuffer, BUFFER_SIZE, 0)
            print("recvCount: \(recvCount) \(currentBuffer)")
            if recvCount < 0 {
                print("Darwin.recv error errno\(Darwin.errno)")
                self.socketId = -1
                return
            }
            
            if recvCount == 0 {
                print("Darwin.recv 0 self._socket: \(self.socketId)")
                self.socketId = -1
                return
            }
            
            let receivedData: NSMutableData = NSMutableData(capacity: BUFFER_SIZE)!
            receivedData.append(currentBuffer, length: recvCount)
            
            guard let data =  NSMutableData(capacity: receivedData.length) else {
                print("fatal error: creating NSMutableData error!")
                return
            }
            
            data.append(receivedData.bytes, length: receivedData.length)
            
            // TODO: support Unicode
            (data as Data).forEach { byte in
                if byte == start {
                    self.buf.removeAll(keepingCapacity: true)
                } else if byte == end {
                    self.dataReceived(self.buf)
                    self.buf.removeAll(keepingCapacity: true)
                } else {
                    self.buf.append(byte)
                }
            }
            
            print("totalBu ffer: \(self.buf)")
            
        } while true
    }
    
    func dataReceived(_ data: Data) {
        
    }
    
    open func send(_ str: String, commandType: CommandType = .message, commandId: String = "") {
        if self.socketId == -1 {
            print("fatal error! _socket: \(self.socketId)")
            return
        }
        
        let vvCommand = VVCommand(id: commandId, type: commandType, body: str)
        
        let json = vvCommand.toJsonStr() 
        let wrap = DELIMITER_START + json + DELIMITER_END
        wrap.utf8CString.withUnsafeBufferPointer() {
            let s = Darwin.send(socketId, $0.baseAddress!, $0.count - 1, 0)
            print("s: \(s) __socket: \(socketId)")
        }
    }
    
    
    func ignoreSIGPIPE(_ fd: Int32) throws {
        
        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            fatalError("setsockopt SO_NOSIGPIPE error")
        }
        
    }
}
