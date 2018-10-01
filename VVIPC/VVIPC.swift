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
    
    // receiveDataCompelte
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
