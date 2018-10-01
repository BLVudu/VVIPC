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
    
    init () {
        
    }
    
    func loadRecv(socket: Int32) -> NSMutableData? {
        
        let totalBuffer: NSMutableData = NSMutableData(capacity: BUFFER_SIZE)!
        let currentBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: BUFFER_SIZE)
        print("clientSocket: \(socket)")
        
        repeat {
            let recvCount = Darwin.recv(socket, currentBuffer, BUFFER_SIZE, 0)
            print("recvCount: \(recvCount)")
            if recvCount < 0 {
                print("Darwin.recv error errno\(Darwin.errno)")
                return nil
            }
            
            if recvCount == 0 {
                print("Darwin.recv 0 self._socket: \(socket)")
                // close?
//                self.closeSocket(socket: socket)
                return nil
            }
            
            totalBuffer.append(currentBuffer, length: recvCount)
            
            if recvCount < BUFFER_SIZE {
                print("break loop: \(recvCount) BUFFER_SIZE: \(BUFFER_SIZE)")
                break
            } else {
//                print("continue to loop recvCount: \(recvCount) BUFFER_SIZE: \(BUFFER_SIZE)")
            }
            
        } while true
        print("totalBuffer: \(totalBuffer.length)")
        if let data =  NSMutableData(capacity: totalBuffer.length) {
            data.append(totalBuffer.bytes, length: totalBuffer.length)
            return data
            
        } else {
            return nil
        }
    }
    
    
    open func checkClientReceive(socket: Int32) {
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            repeat {
                print("loadRecv.....")
                if let data = self?.loadRecv(socket: socket) {
                    self?.dataReceived(socket: socket, data: data)
                    
                }
            } while socket > 1
        }
    }
    
    
    func dataReceived(socket: Int32, data: NSData) {
        
    }
    
    func ignoreSIGPIPE(_ fd: Int32) throws {
        
        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
            throw Error("setsockopt SO_NOSIGPIPE error")
        }
        
    }
}
