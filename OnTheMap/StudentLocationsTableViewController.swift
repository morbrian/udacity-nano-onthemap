//
//  MarkerListViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class StudentLocationsTableViewController: UIViewController {
    
    // how many items we request at a time
    private let FetchLimit = 100
    
    // how close we can get to end of list before fetching more items
    private let PreFetchTrigger = 60
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataManager: StudentDataAccessManager?
    
    var preFetchEnabled = true
    
    override func viewDidLoad() {
        if let tabBarController = self.tabBarController as? ManagingTabBarController {
            self.dataManager = tabBarController.dataManager
            println("on load locs are \(self.dataManager?.studentLocationCount)")
            fetchNextPage()
        }
    }
    
    private func fetchNextPage() {
        if !preFetchEnabled {
            return
        }
        
        let start = dataManager?.studentLocationCount ?? 0
        let end = start + FetchLimit
        let oldCount = start
        dataManager?.preFetchStudentLocationSubset(start..<end) {
            success, error in
            if let newCount = self.dataManager?.studentLocationCount where newCount > 0 {
                self.preFetchEnabled = newCount - oldCount > self.PreFetchTrigger
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let currentCount = dataManager?.studentLocationCount
            where indexPath.item == currentCount - PreFetchTrigger {
                fetchNextPage()
        }
    }
    
}

// MARK: - UITableViewDelegate
extension StudentLocationsTableViewController: UITableViewDelegate {
    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        //handleSelectionEventForMemeAtIndex(indexPath.item)
//    }
    
//    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        handleDeselectionEventForMemeAtIndex(indexPath.item)
//    }
    
//    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if (editingStyle == UITableViewCellEditingStyle.Delete) {
//            deleteSingleMemeAtIndex(indexPath.item)
//        }
//    }
}

// MARK: - UITableViewDataSource
extension StudentLocationsTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager?.studentLocationCount ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var studentLocationData = dataManager?.studentLocationAtIndex(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier("StudentLocationCell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = studentLocationData?.firstname
        return cell
    }
}
