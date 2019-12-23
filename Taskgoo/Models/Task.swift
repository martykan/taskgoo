//
//  Task.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation

class Task : NSObject {
    // Important is marked in title
    static let ImportantPrefix = "⭐ "
    
    @objc dynamic var tasklist: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var titleFormatted: NSMutableAttributedString {
        get {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: self.title)
            // Apply strikethrough if done
            if self.done {
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            }
            return attributeString
        }
        set(new) {
            self.title = new as! String
        }
    }
    @objc dynamic var status: String = ""
    @objc dynamic var important: Bool = false
    @objc dynamic var done: Bool = false
    @objc dynamic var position: String = ""
    @objc dynamic var note: String = ""
    @objc dynamic var dueDate: Date? = nil
    @objc dynamic var dueDateFormatted: String {
        get {
            // For tooltip
            let dateFormat = DateFormatter()
            dateFormat.dateStyle = .long
            dateFormat.timeStyle = .none
            if self.dueDate != nil {
                return dateFormat.string(from: self.dueDate!)
            }
            return "-"
        }
    }
    
    // Monitor dependant bindings
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        return [
            #keyPath(Task.titleFormatted): [#keyPath(Task.title), #keyPath(Task.done)],
            #keyPath(Task.dueDateFormatted): [#keyPath(Task.dueDate)]
        ][key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    override init() {
        super.init()
    }
    
    // Parses from JSON
    init(tasklist: String, parse item: NSDictionary) throws {
        super.init()
        guard let id = item["id"] as? String,
        let title = item["title"] as? String,
        let status = item["status"] as? String,
        let position = item["position"] as? String
        else { throw "Invalid object" }
        
        self.tasklist = tasklist
        self.id = id
        self.title = title
        // Important is marked in title
        if self.title.starts(with: Task.ImportantPrefix) {
            self.title = self.title.substring(from: String.Index(encodedOffset: 2))
            self.important = true
        }
        self.status = status
        self.done = self.status == "completed"
        self.note = item["notes"] as? String ?? ""
        self.position = position
        // Parse due date from ISO8601 string
        if let dueString = item["due"] as? String {
            let dateFormat = ISO8601DateFormatter()
            dateFormat.formatOptions = [.withInternetDateTime, .withTimeZone, .withFractionalSeconds]
            self.dueDate = dateFormat.date(from: dueString)
        }
    }
}
