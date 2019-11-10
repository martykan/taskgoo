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
    
    let baseURL = URL(string: "https://www.googleapis.com")!
    
    public init() {
        let oauth = OAuth2CodeGrant(settings: [
            "keychain": false,
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
    
    func tasklistList(callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = baseURL.appendingPathComponent("tasks/v1/users/@me/lists")
        let req = oauth2.request(forURL: url)
        request(req: req, callback: callback)
    }
    
    func tasksList(tasklistId: String, callback: @escaping ((_ dict: OAuth2JSON?, _ error: Error?) -> Void)) {
        let url = baseURL.appendingPathComponent("tasks/v1/lists/" + tasklistId + "/tasks")
        let req = oauth2.request(forURL: url)
        request(req: req, callback: callback)
    }
}
