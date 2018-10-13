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
            vvLog("convert to json error")
            return nil
        }
        
        guard let commandType = json?["commandType"].flatMap(CommandType.init) else {
            vvLog("convert commandType error")
            return nil
        }
        
        guard let commandId = json?["commandId"] else {
            vvLog("convert commandId error")
            return nil
        }
        
        guard let body = json?["body"] else {
            vvLog("convert body error")
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
