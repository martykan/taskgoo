//
//  Models.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation

class Tasklist : NSObject {
    // Predefined categories
    static let MetaAll = Tasklist(id: "META:all", title: "􀃲  All tasks")
    static let MetaToday = Tasklist(id: "META:today", title: "􀉉  Today")
    static let MetaImportant = Tasklist(id: "META:important", title: "􀋃  Important")
    static let MetaSearch = Tasklist(id: "META:search", title: "􀊫  Search result")
    static func MetaSearch(string: String) -> Tasklist {
        let tasklist = Tasklist.MetaSearch
        tasklist.search = string
        return tasklist
    }
    static let Separator = Tasklist(id: "SEPARATOR", title: "-")
    
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var search: String? = nil
    
    // How it filters the tasks view
    @objc dynamic var filter: NSPredicate {
        get {
            switch(id) {
            case Tasklist.MetaAll.id:
                return NSPredicate(value: true)
            case Tasklist.MetaToday.id:
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
                components.hour = 00
                components.minute = 00
                components.second = 00
                let startDate = Calendar.current.date(from: components)
                components.hour = 23
                components.minute = 59
                components.second = 59
                let endDate = Calendar.current.date(from: components)
                return NSPredicate(format: "(dueDate >= %@) AND (dueDate <= %@)", argumentArray: [startDate!, endDate!])
            case Tasklist.MetaImportant.id:
                return NSPredicate(format: "important == true")
            case Tasklist.MetaSearch.id:
                return NSPredicate(format: "title contains[cd] %@", search!)
            default:
                return NSPredicate(format: "tasklist == %@", id)
            }
        }
    }
    
    // How it sorts the tasks view
    @objc dynamic var sort: [NSSortDescriptor] {
        get {
            switch(id) {
            case "META:all":
                return [NSSortDescriptor(key: "dueDate", ascending: false), NSSortDescriptor(key: "title", ascending: true)]
            default:
                return [NSSortDescriptor(key: "tasklist", ascending: true), NSSortDescriptor(key: "position", ascending: true)]
            }
        }
    }
    @objc dynamic var isMeta: Bool {
        get {
            return id.starts(with: "META")
        }
    }
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
