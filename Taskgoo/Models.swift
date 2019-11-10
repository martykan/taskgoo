//
//  Models.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation

class Tasklist {
    var id: String = ""
    var title: String = ""
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

class Task {
    var tasklist: String = ""
    var text: String = ""
}
