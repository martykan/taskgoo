//
//  GoogleAuthLoader.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation
import p2_OAuth2

class GoogleAPI: OAuth2DataLoader {
        
    public init() {
        let oauth = OAuth2CodeGrant(settings: [
            "keychain": true,
            "client_id": "921625277666-gqdl56ck6h6loesm40sa510862q5agl6.apps.googleusercontent.com",
            "client_secret": "5jq-QA7-ZCpInV87_Ju276vU",
            "authorize_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://www.googleapis.com/oauth2/v3/token",
            "scope": "profile https://www.googleapis.com/auth/tasks",
            "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob"],
        ])
        oauth.authConfig.authorizeEmbedded = true
        oauth.logger = OAuth2DebugLogger(.debug)
        super.init(oauth2: oauth, host: "https://www.googleapis.com")
        alsoIntercept403 = true
    }
    
    func request(req: URLRequest, callback: @escaping ((OAuth2JSON?, Error?) -> Void)) {
        perform(request: req) { response in
            for (key, value) in response.request.allHTTPHeaderFields ?? [:] {
                // NSLog("Req Header: " + key + ": " + value)
            }
            // NSLog("Status: %d", response.response.statusCode)
            do {
                // NSLog(String(decoding: try response.responseData(), as: UTF8.self))
                let dict = try response.responseJSON()
                DispatchQueue.main.async {
                    callback(dict, nil)
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    callback(nil, error)
                }
            }
        }
    }
}

protocol SyncOperation {
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void))
}

class TasklistList : SyncOperation {
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation {
        return self
    }
    
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = URL(string: "https://www.googleapis.com/tasks/v1/users/@me/lists")!
        let req = googleApi.oauth2.request(forURL: url)
        googleApi.request(req: req, callback: callback)
    }
}

class TasksList : SyncOperation {
    let tasklistId: String
    
    init(tasklistId: String) {
        self.tasklistId = tasklistId
    }
    
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation {
        return self
    }
    
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = URL(string: "https://www.googleapis.com/tasks/v1/lists/" + tasklistId + "/tasks?showCompleted=true")!
        let req = googleApi.oauth2.request(forURL: url)
        googleApi.request(req: req, callback: callback)
    }
}

class TasksAdd : SyncOperation {
    let task: Task
    
    init(task: Task) {
        self.task = task
    }
    
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation {
        return self
    }
    
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = URL(string: "https://www.googleapis.com/tasks/v1/lists/" + task.tasklist + "/tasks")!
        var req = googleApi.oauth2.request(forURL: url)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"
        let body: Dictionary<String, Any> = [
            "title": task.title
        ]
        req.httpBody = try! JSONSerialization.data(withJSONObject: body)
        googleApi.request(req: req, callback: callback)
    }
}

class TasksUpdate : SyncOperation {
    let task: Task
    let body: Data
    
    init(task: Task, body: Data) {
        self.task = task
        self.body = body
    }
    
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation {
        if let id = tmpIdMap[self.task.id] {
            self.task.id = id
        }
        return self
    }
    
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = URL(string: "https://www.googleapis.com/tasks/v1/lists/" + task.tasklist + "/tasks/" + task.id)!
        var req = googleApi.oauth2.request(forURL: url)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "PATCH"
        req.httpBody = body
        googleApi.request(req: req, callback: callback)
    }
}

class TasksMove : SyncOperation {
    let task: Task
    let previousId: String?
    
    init(task: Task, previousId: String?) {
        self.task = task
        self.previousId = previousId
    }
    
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation {
        if let id = tmpIdMap[self.task.id] {
            self.task.id = id
        }
        return self
    }
    
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        var url = URL(string: "https://www.googleapis.com/tasks/v1/lists/" + task.tasklist + "/tasks/" + task.id + "/move")!
        if previousId != nil {
            url = URL(string: url.absoluteString + "?previous=" + previousId!)!
        }
        var req = googleApi.oauth2.request(forURL: url)
        req.httpMethod = "POST"
        googleApi.request(req: req, callback: callback)
    }
}

class TasksDelete : SyncOperation {
    let task: Task
    
    init(task: Task) {
        self.task = task
    }
    
    func tmpIdMap(_ tmpIdMap: [String : String]) -> SyncOperation {
        if let id = tmpIdMap[self.task.id] {
            self.task.id = id
        }
        return self
    }
    
    func request(googleApi: GoogleAPI, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = URL(string: "https://www.googleapis.com/tasks/v1/lists/" + task.tasklist + "/tasks/" + task.id)!
        var req = googleApi.oauth2.request(forURL: url)
        req.httpMethod = "DELETE"
        googleApi.request(req: req, callback: callback)
    }
}
