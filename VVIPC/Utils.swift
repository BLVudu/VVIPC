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

public protocol VVIPCUITestDelegate: class {
    func vvIPCGetFile(_ file: String) -> String?
}

public protocol VVIPCDelegate: class {
    func vvIPCDataRecieve(_ str: String)
    func vvIPCDataRecieveError() // TODO: some errors
    func vvIPCNotificationReceived(_ str: String, userInfo: [String: String])
    
    // receiveDataCompelte
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

public typealias Callback = ((String) -> Void)

let BUFFER_SIZE: Int = 1024 * 64
let DELIMITER_START: String = "\u{01}"
let DELIMITER_END: String = "\u{02}"
let SOCKET_PORT: String = "14112"

public struct VVPostNotification {
    let name: String
    let userInfo: [String: String]
    init(name: String, userInfo: [String: String]) {
        self.name = name
        self.userInfo = userInfo
    }
    init?(_ str: String) {

        guard let data = str.data(using: .utf8) else { return nil }
        guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: [])
        , let json = jsonData as? [String: Any] else {
            print("jsonData error")
            return nil
        }
        
        guard let name = json["name"] as? String else { return nil }
        guard let userInfo = json["userInfo"] as? [String: String] else { return nil }
        
        self.name = name
        self.userInfo = userInfo
    }
    
    public var postBody: String {
        var dic: [String: Any] = [:]
        dic["name"] = self.name
        dic["userInfo"] = self.userInfo
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }
}

public enum CommandType: String {
    case message, getFile, gotFile, postNotification, pushNotification, userDefault
    init?(_ str: String?) {
        guard let s = str else { return nil }
        
        switch s {
        case "message":          self = .message
        case "getFile":          self = .getFile
        case "gotFile":          self = .gotFile
        case "postNotification": self = .postNotification
        case "pushNotification": self = .pushNotification
        case "userDefault":      self = .userDefault
        default:                 return nil
        }
    }
}

public struct VVCommand {
    let id: String
    let type: CommandType
    let body: String
    
    init(id: String, type: CommandType, body: String) {
        self.id = id
        self.type = type
        self.body = body
    }
    
    init?(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            print("convert to json error")
            return nil
        }
        
        guard let commandType = json?["commandType"].flatMap(CommandType.init) else {
            print("convert commandType error")
            return nil
        }
        
        guard let commandId = json?["commandId"] else {
            print("convert commandId error")
            return nil
        }
        
        guard let body = json?["body"] else {
            print("convert body error")
            return nil
        }
        
        self.id = commandId
        self.type = commandType
        self.body = body
    }
    
    public func toDic() -> [String: String] {
        return ["commandId": self.id,
                "commandType": self.type.rawValue,
                "body": self.body]
    }

    public func toJsonStr() -> String {
        let dic = self.toDic()
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }
}
