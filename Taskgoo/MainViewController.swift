//
//  ViewController.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Cocoa

public class MainViewController: NSViewController {

    let googleApi = GoogleAPI()
    let dragDropType = NSPasteboard.PasteboardType(rawValue: "public.data")
    
    @IBOutlet var taskListsController: NSArrayController!
    @IBOutlet var tasksController: NSArrayController!
    @IBOutlet weak var tasksTableView: NSTableView!
    
    @objc dynamic var originalTasklist = [Tasklist]()
    @objc dynamic var loading = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        tasksTableView.dataSource = self
        tasksTableView.delegate = self
        tasksTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "public.data")])
        loadData()
    }
    
    @IBAction func buttonReload(_ sender: Any) {
        loadData()
    }
    
    // MARK: Loading
    func loadData() {
        self.loading = true
        self.originalTasklist.removeAll()
        googleApi.oauth2.authConfig.authorizeContext = view.window
        googleApi.tasklistList(callback: { dict, error in
            self.loading = false
            if let error = error {
                NSLog(error.asOAuth2Error.description)
                return
            }
            for (i, item) in (dict!["items"] as! NSArray).enumerated() {
                let item = item as! NSDictionary
                let id = item["id"] as! String
                let title = item["title"] as! String
                self.originalTasklist.append(Tasklist(id: id, title: title))
                self.loadTasks(tasklistId: id) { tasks in
                    let tasks = tasks.sorted(by: { $0.position < $1.position })
                    self.originalTasklist[i].tasks = tasks
                    self.taskListsController.content = self.originalTasklist
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
                task.note = item["notes"] as? String ?? ""
                task.position = item["position"] as! String
                task.observe(\.title, options: []) { (model, change) in
                    print("change observed")
                    print(change)
                }
                tasks.append(task)
            }
            if nextPage != nil {
                self.loadTasks(tasklistId: tasklistId, tasks: tasks, pageToken: nextPage, callback: callback)
            } else {
                callback(tasks)
            }
        })
    }
    
    // MARK: API executors
    @IBAction func addTask(_ sender: NSTextFieldCell) {
        let text = sender.stringValue
        if text == "" {
            return
        }
        sender.stringValue = ""
        let lists = taskListsController.content as! [Tasklist]
        let selectedList = lists[taskListsController.selectionIndex]
        let task = Task()
        task.title = text
        selectedList.tasks.insert(task, at: 0)
        googleApi.tasksAdd(tasklistId: selectedList.id, title: text, callback: { dict, error in
            if let error = error {
                // TODO: queue sync
                print(error)
                return
            }
            let id = dict!["id"] as! String
            selectedList.tasks[0].id = id
        })
    }
    
    @IBAction func deleteTask(_ sender: Any) {
        let lists = taskListsController.content as! [Tasklist]
        let selectedList = lists[taskListsController.selectionIndex]
        let task = selectedList.tasks[tasksController.selectionIndex]
        selectedList.tasks.remove(at: tasksController.selectionIndex)
        if task.id != "" {
            googleApi.tasksDelete(tasklistId: selectedList.id, taskId: task.id, callback: { dict, error in
                if let error = error {
                    // TODO: queue sync
                    print(error)
                    return
                }
            })
        }
    }
    
    func reorderItem(from: Int, to: Int) {
        let lists = taskListsController.content as! [Tasklist]
        let selectedList = lists[taskListsController.selectionIndex]
        let targetIndex = from < to ? to - 1 : to
        let task = selectedList.tasks.remove(at: from)
        selectedList.tasks.insert(task, at: targetIndex)
        let previousId = targetIndex > 0 ? selectedList.tasks[targetIndex-1].id : nil
        googleApi.tasksMove(tasklistId: selectedList.id, taskId: task.id, previousId: previousId, callback: { dict, error in
            if let error = error {
                // TODO: queue sync
                print(error)
                return
            }
            print(dict)
        })
    }
}

extension MainViewController : NSTableViewDelegate, NSTableViewDataSource {
    // MARK: Drag and drop reordering
    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let data = NSKeyedArchiver.archivedData(withRootObject: row)
        let item = NSPasteboardItem()
        item.setData(data, forType: self.dragDropType)
        return item
    }

    public func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        guard let source = info.draggingSource as? NSTableView,
            source === tasksTableView
            else { return [] }
        
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pb = info.draggingPasteboard
        if let itemData = pb.pasteboardItems?.first?.data(forType: dragDropType),
            let oldRow = NSKeyedUnarchiver.unarchiveObject(with: itemData) as? Int
        {
            reorderItem(from: oldRow, to: row)
            return true
        }
        return false
    }
}
