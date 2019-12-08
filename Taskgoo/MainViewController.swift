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
    var taskLists = [Tasklist]()
    
    override var representedObject: Any? {
        didSet {
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData();
    }

    func loadData() {
        taskLists.removeAll()
        googleApi.oauth2.authConfig.authorizeContext = view.window
        googleApi.tasklistList(callback: { dict, error in
            if let error = error {
                NSLog(error.asOAuth2Error.description)
                return
            }
            for (i, item) in (dict!["items"] as! NSArray).enumerated() {
                let item = item as! NSDictionary
                let id = item["id"] as! String
                let title = item["title"] as! String
                self.taskLists.append(Tasklist(id: id, title: title))
                self.loadTasks(tasklistId: id) { tasks in
                    self.taskLists[i].tasks = tasks
                    NSLog(String(decoding: try! JSONEncoder().encode(self.taskLists), as: UTF8.self))
                }
            }
        })
    }
    
    func loadTasks(tasklistId: String, tasks: [Task] = [], pageToken: String? = nil, callback: @escaping (([Task]) -> Void)) {
        var tasks = tasks
        self.googleApi.tasksList(tasklistId: tasklistId, callback: { dict, error in
            if let error = error {
                NSLog(error.asOAuth2Error.description)
                return
            }
            let nextPage = dict?["nextPageToken"] as? String
            for item in dict?["items"] as? NSArray ?? [] {
                let item = item as! NSDictionary
                let task = Task()
                task.id = item["id"] as! String
                task.title = item["title"] as! String
                task.status = item["status"] as! String
                tasks.append(task)
            }
            if nextPage != nil {
                self.loadTasks(tasklistId: tasklistId, tasks: tasks, pageToken: nextPage, callback: callback)
            } else {
                callback(tasks)
            }
        })
    }
}
