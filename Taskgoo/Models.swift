//
//  Models.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation

class Tasklist : NSObject {
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var tasks: [Task] = []
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
    
    override var description: String {
      get {
        return "id: \(id) title: \(title)"
      }
    }
}

class Task : NSObject {
    @objc dynamic var tasklist: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var status: String = ""
    @objc dynamic var position: String = ""
    @objc dynamic var note: String = ""
}
