//
//  ViewController.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    let googleApi = GoogleAPI()
    
    override var representedObject: Any? {
        didSet {
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData();
    }

    func loadData() {
        googleApi.oauth2.authConfig.authorizeContext = view.window
        googleApi.tasklistList(callback: { dict, error in
            if let error = error {
                NSLog(error.asOAuth2Error.description)
                return
            }
            for item in dict!["items"] as! NSArray {
                let item = item as! NSDictionary
                let id = item["id"] as! String
                let title = item["title"] as! String
                self.googleApi.tasksList(tasklistId: id, callback: { dict, error in
                    if let error = error {
                        NSLog(error.asOAuth2Error.description)
                        return
                    }
                    let nextPage = dict?["nextPageToken"] as? String
                    NSLog(title)
                    NSLog(nextPage ?? "No next page")
                    for item in dict?["items"] as? NSArray ?? [] {
                        let item = item as! NSDictionary
                        let id = item["id"] as! String
                        let status = item["status"] as! String
                        let title = item["title"] as! String
                        NSLog(" - " + title + " / " + status)
                    }
                })
            }
        })
    }
}
