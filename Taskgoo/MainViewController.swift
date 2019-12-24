//
//  ViewController.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Cocoa
import p2_OAuth2

public class MainViewController: NSViewController {

    let googleApi = GoogleAPI()
    let dragDropType = NSPasteboard.PasteboardType(rawValue: "public.data")
    var taskContext = "TaskContext"
    var tasklistContext = "TasklistContext"
    var separatorIndex = 3
    var lastIndex = 4
    var syncBacklog: [SyncOperation] = [] {
        didSet {
            if self.syncBacklog.count > 0 {
                self.syncBacklogInfo = "􀙈  \(self.syncBacklog.count)"
            } else {
                self.syncBacklogInfo = ""
            }
        }
    }
    var tmpIdMap: [String : String] = [:]
    
    @IBOutlet var taskListsController: NSArrayController!
    @IBOutlet var tasksController: NSArrayController!
    @IBOutlet weak var tasksTableView: NSTableView!
    @IBOutlet weak var taskListsTableView: NSTableView!
    
    @objc dynamic var tasklists = [Tasklist]()
    @objc dynamic var tasks = [Task]()
    @objc dynamic var loading = false
    @objc dynamic var searchString: String? = "" {
        didSet {
            if self.searchString != nil && self.searchString != "" {
                lastIndex = self.taskListsController.selectionIndex
                var tasklists = [Tasklist.MetaSearch(string: self.searchString!)]
                tasklists.append(contentsOf: self.tasklists)
                self.separatorIndex = 4
                self.taskListsController.content = tasklists
                self.taskListsController.setSelectionIndex(0)
            } else {
                self.separatorIndex = 3
                self.taskListsController.content = self.tasklists
                self.taskListsController.setSelectionIndex(lastIndex)
            }
        }
    }
    @objc dynamic var syncBacklogInfo = ""
    
    var selectedTasklist: Tasklist {
        get {
            return tasklists[taskListsController.selectionIndex]
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        initTableViews()
        loadData()
    }
    
    @IBAction func addTaskList(_ sender: Any) {
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")
        msg.addButton(withTitle: "Cancel")
        msg.messageText = "New task list"
        msg.informativeText = "Enter the title of the task list:"
        msg.alertStyle = .informational

        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        txt.stringValue = ""

        msg.accessoryView = txt
        msg.beginSheetModal(for: self.view.window!) { response in
            if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
                let tasklist = Tasklist(id: "", title: txt.stringValue)
                tasklist.addObserver(self, forKeyPath: "title", options: .new, context: &self.tasklistContext)
                TasklistAdd(tasklist: tasklist).request(googleApi: self.googleApi) { dict, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    if let id = dict?["id"] as? String {
                        tasklist.id = id
                        self.tasklists.append(tasklist)
                        self.taskListsController.content = self.tasklists
                    }
                }
            }
        }
    }
    
    @IBAction func buttonReload(_ sender: Any) {
        if !self.syncBacklog.isEmpty {
            runSyncBacklog()
            return
        }
        loadData()
    }
    
    @IBAction func addDueDate(_ sender: Any) {
        let task = tasksController.selectedObjects[0] as! Task
        let now =  Calendar.current.dateComponents(in: .current, from: Date())
        let tomorrow = DateComponents(year: now.year, month: now.month, day: now.day! + 1, hour: now.hour)
        task.dueDate = Calendar.current.date(from: tomorrow)!
    }
    
    @IBAction func removeDueDate(_ sender: Any) {
        let task = tasksController.selectedObjects[0] as! Task
        task.dueDate = nil
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &taskContext {
            if let newValue = change![.newKey]  {
                if let task = object as? Task {
                    updateTask(task: task, key: keyPath!, newValue: newValue)
                }
            }
            return
        }
        if context == &tasklistContext {
            if let newValue = change![.newKey]  {
                if let tasklist = object as? Tasklist {
                    updateTasklist(tasklist: tasklist)
                }
            }
            return
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    // MARK: Loading
    func loadData() {
        if self.loading {
            return
        }
        self.loading = true
        self.tasklists = [.MetaAll, .MetaToday, .MetaImportant, .Separator]
        
        googleApi.oauth2.authConfig.authorizeContext = view.window
        TasklistList().request(googleApi: googleApi, callback: { dict, error in
            self.loading = false
            if let error = error {
                NSLog(error.asOAuth2Error.description)
                return
            }
            self.tasks.removeAll()
            for (i, item) in (dict!["items"] as! NSArray).enumerated() {
                let item = item as! NSDictionary
                let id = item["id"] as! String
                let title = item["title"] as! String
                let tasklist = Tasklist(id: id, title: title)
                tasklist.addObserver(self, forKeyPath: "title", options: .new, context: &self.tasklistContext)
                self.tasklists.append(tasklist)
                self.loadTasks(tasklistId: id) { tasks in
                    self.tasks.append(contentsOf: tasks)
                }
            }
            self.taskListsController.content = self.tasklists
            self.taskListsController.setSelectionIndex(self.lastIndex)
        })
    }
    
    func loadTasks(tasklistId: String, tasks: [Task] = [], pageToken: String? = nil, callback: @escaping (([Task]) -> Void)) {
        var tasks = tasks
        TasksList(tasklistId: tasklistId).request(googleApi: googleApi, callback: { dict, error in
            if let error = error {
                NSLog(error.asOAuth2Error.description)
                return
            }
            let nextPage = dict?["nextPageToken"] as? String
            for item in dict?["items"] as? NSArray ?? [] {
                let item = item as! NSDictionary
                if let task = try? Task(tasklist: tasklistId, parse: item) {
                    self.bindTaskObservers(task)
                    tasks.append(task)
                }
            }
            if nextPage != nil {
                self.loadTasks(tasklistId: tasklistId, tasks: tasks, pageToken: nextPage, callback: callback)
            } else {
                callback(tasks)
            }
        })
    }
    
    func bindTaskObservers(_ task: Task) {
        task.addObserver(self, forKeyPath: "title", options: .new, context: &self.taskContext)
        task.addObserver(self, forKeyPath: "note", options: .new, context: &self.taskContext)
        task.addObserver(self, forKeyPath: "dueDate", options: .new, context: &self.taskContext)
        task.addObserver(self, forKeyPath: "done", options: .new, context: &self.taskContext)
        task.addObserver(self, forKeyPath: "important", options: .new, context: &self.taskContext)
    }
    
    // MARK: API executors
    @IBAction func addTask(_ sender: NSTextFieldCell) {
        if selectedTasklist.isMeta || sender.stringValue == "" {
            return
        }
        
        let text = sender.stringValue
        sender.stringValue = ""
        
        let tmpId = "tmp\(Int.random(in: 0...10000))"
        let task = Task()
        task.id = tmpId
        task.tasklist = selectedTasklist.id
        task.title = text
        self.bindTaskObservers(task)
        self.tasks.insert(task, at: 0)
        
        TasksAdd(task: task).request(googleApi: googleApi, callback: { dict, error in
            if let error = error {
                self.syncBacklog.append(TasksAdd(task: task))
                print(error)
                return
            }
            do {
                let newTask = try Task(tasklist: task.tasklist, parse: dict! as NSDictionary)
                var index = self.tasks.firstIndex(where: { $0.id == tmpId })!
                self.tasks[index].id = newTask.id
                self.tasks[index].position = newTask.position
            } catch {
                print(dict)
            }
        })
    }
    
    @IBAction func deleteTask(_ sender: Any) {
        let task = tasksController.selectedObjects[0] as! Task
        self.tasks.removeAll(where: { $0.id == task.id })
        if !task.id.starts(with: "tmp") {
            TasksDelete(task: task).request(googleApi: googleApi, callback: { dict, error in
                if let error = error {
                    self.syncBacklog.append(TasksDelete(task: task))
                    print(error)
                    return
                }
            })
        }
    }
    
    func updateTask(task: Task, key: String, newValue: Any?) {
        let data: [String: Any?]
        switch(key) {
        case "note":
            data = ["notes": newValue]
        case "dueDate":
            if let newDate = newValue as? Date {
                let dateFormat = ISO8601DateFormatter()
                dateFormat.formatOptions = [.withInternetDateTime, .withTimeZone, .withFractionalSeconds]
                data = ["due": dateFormat.string(from: newDate)]
                print(data["due"])
            } else {
                data = ["due": nil]
            }
        case "done":
            let done = newValue as! Bool
            data = ["status": done ? "completed" : "needsAction"]
        case "important":
            let important = newValue as! Bool
            if important {
                data = ["title": Task.ImportantPrefix + task.title]
            } else if !important && task.title.starts(with: Task.ImportantPrefix) {
                data = ["title": task.title.substring(from: String.Index(encodedOffset: 2))]
            } else {
                return
            }
        default:
            data = [key: newValue]
        }
        let body = try! JSONSerialization.data(withJSONObject: data)
        TasksUpdate(task: task, body: body).request(googleApi: googleApi, callback: { dict, error in
            if let error = error {
                self.syncBacklog.append(TasksUpdate(task: task, body: body))
                print(error)
                return
            }
        })
    }
    
    func updateTasklist(tasklist: Tasklist) {
        TasklistUpdate(tasklist: tasklist).request(googleApi: googleApi, callback: { dict, error in
            if let error = error {
                print(error)
                return
            }
        })
    }
    
    @objc func deleteTasklist(_ sender: Any) {
        let row = taskListsTableView.clickedRow
        guard row >= 0 else { return }
        let tasklist = self.tasklists[row]
        TasklistDelete(tasklist: tasklist).request(googleApi: googleApi, callback: { dict, error in
            if let error = error {
                print(error)
                return
            }
            self.tasklists.remove(at: row)
            self.taskListsController.content = self.tasklists
        })
    }
    
    func reorderItem(from: Int, to: Int) {
        let filteredTasks = self.tasks.filter({ $0.tasklist == selectedTasklist.id }).sorted(by: { $0.position < $1.position })
        let task = filteredTasks[from]
        var index = self.tasks.firstIndex(where: { $0.id == task.id })!
        var previousId: String? = nil
        if to > 0 {
            previousId = filteredTasks[to-1].id
            self.tasks[index].position = filteredTasks[to-1].position + "Z"
        } else {
            self.tasks[index].position = "0"
        }
        tasksController.rearrangeObjects()
        TasksMove(task: task, previousId: previousId).request(googleApi: googleApi, callback: { dict, error in
            if let error = error {
                print(error)
                self.syncBacklog.append(TasksMove(task: task, previousId: previousId))
                return
            }
            self.loadTasks(tasklistId: task.tasklist) { newTasks in
                for newTask in newTasks {
                    var index = self.tasks.firstIndex(where: { $0.id == newTask.id })!
                    self.tasks[index].position = newTask.position
                }
            }
        })
    }
        
    func runSyncBacklog() {
        if self.syncBacklog.isEmpty {
            loadData()
            return
        }
        let currentRequest = self.syncBacklog[0]
        var newTmpId: String? = nil
        if let taskAdd = currentRequest as? TasksAdd {
            newTmpId = taskAdd.task.id
        }
        currentRequest.tmpIdMap(tmpIdMap).request(googleApi: googleApi) { dict, error in
            if let error = error {
                print(error)
                return
            }
            if newTmpId != nil, let id = dict?["id"] as? String {
                self.tmpIdMap[newTmpId!] = id
            }
            self.syncBacklog.remove(at: 0)
            self.runSyncBacklog()
        }
    }
}
