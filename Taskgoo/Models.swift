//
//  Models.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation

class Tasklist : Encodable {
    var id: String = ""
    var title: String = ""
    var tasks: [Task] = []
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

class Task : Encodable {
    var tasklist: String = ""
    var id: String = ""
    var title: String = ""
    var status: String = ""
}
