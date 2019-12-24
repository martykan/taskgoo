//
//  AppDelegate.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Cocoa
import p2_OAuth2

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBAction func actionLogout(_ sender: Any) {
        GoogleAPI().oauth2.forgetTokens()
        if let path = Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent().absoluteString {
            NSLog("restart \(path)")
            _ = Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [path])
            NSApp.terminate(self)
        }
    }
}
