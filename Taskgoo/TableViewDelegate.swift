//
//  TableViewDelegate.swift
//  Taskgoo
//
//  Created by Tomáš Martykán on 01/04/1976.
//  Copyright © 2019 Tomáš Martykan. All rights reserved.
//

import Foundation
import Cocoa

extension MainViewController : NSTableViewDelegate, NSTableViewDataSource {
    func initTableViews() {
        taskListsTableView.dataSource = self
        taskListsTableView.delegate = self
        taskListsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "public.data")])
        tasksTableView.dataSource = self
        tasksTableView.delegate = self
        tasksTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "public.data")])
        
        let taskListsMenu = NSMenu()
        taskListsMenu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteTasklist(_:)), keyEquivalent: ""))
        taskListsTableView.menu = taskListsMenu
    }
    
    // MARK: Divider
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier = "NormalCell"
        if(tableView == taskListsTableView && row == self.separatorIndex) {
            cellIdentifier = "DividerCell"
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
          return cell
        }
        return nil
    }
    
    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if(tableView == taskListsTableView && row == self.separatorIndex) {
            return false
        }
        return true
    }
    
    // MARK: Drag and drop reordering
    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard tableView === tasksTableView && !selectedTasklist.isMeta
        else { return nil }
        
        let data = try! NSKeyedArchiver.archivedData(withRootObject: row, requiringSecureCoding: false)
        let item = NSPasteboardItem()
        item.setData(data, forType: self.dragDropType)
        return item
    }

    public func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        guard let source = info.draggingSource as? NSTableView,
            source === tasksTableView
            else { return [] }
        
        if dropOperation == .above && tableView == tasksTableView {
            return .move
        }
        if dropOperation == .on && tableView == taskListsTableView && row > self.separatorIndex {
            return .move
        }
        return []
    }
    
    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard tableView === tasksTableView
        else { return false }
        
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
