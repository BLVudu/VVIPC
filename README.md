## Overview

Apple's UI testing target is running on an different process then the target you are testing on. In order to pass messages to main target, app.launchArguments is the only place you can share data with, and it has to be defined before app is launched. By using VVIPC, you will be able to send message between the processes in run time.

## Features:
- Light weight, purely written in Swift. Easier to install into your projects and no extra dependencies needed.
- A set of tools for mocking state for your main target such as directly send Post Notification and save data to UserDefault to main target.

## Installation (Carthage)
Add into Cartfile:

`github "BLVudu/VVIPC" "master"`

## Installation (CocoaPod)
TBD



## Installation (Manual)

TBD

## Usage
On your UI Test:
``` swift
import VVIPC
func testExample() {
    // create server socket
    let vvipc = VVIPC()
    vvipc.serverStart()
    
    let app = XCUIApplication()
    app.launch()
    // send string to main target:
    vvipc.serverSend("Hello from UI Test!") 
  
    // or send Post Notification:
    vvipc.postNotification("PostNameFromUITest")
}
```
On your main target:
``` swift
import VVIPC

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vvipc = VVIPC()
        // create VVIPC and connect:
        vvipc.conn(delegate: self)
    }
}

extension ViewController: VVIPCDelegate {
    // handle recevied messages from UI Test
    func vvIPCDataRecieve(_ str: String) {
        print("received: \(str)")
    }
    
    func vvIPCDataRecieveError(_ error: Error) {
        print("error: \(error)")
    }
}
```
