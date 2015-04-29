//
//  MarkerListViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class StudentLocationsTableViewController: UIViewController {
    
    let FetchLimit = 100
    let PreFetchTrigger = 20
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataManager: StudentDataAccessManager?
    
    var preFetchEnabled = true
    
    override func viewDidLoad() {
        if let tabBarController = self.tabBarController as? ManagingTabBarController {
            dataManager = tabBarController.dataManager
            dataManager?.fetchLimit = FetchLimit
            println("on load locs are \(self.dataManager?.studentLocationCount)")
            fetchNextPage()
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let currentCount = dataManager?.studentLocationCount
            where indexPath.item == currentCount - PreFetchTrigger {
                fetchNextPage()
        }
    }
    
    private func fetchNextPage() {
        if !preFetchEnabled {
            return
        }
        
        let oldCount = self.dataManager?.studentLocationCount ?? 0
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        dataManager?.fetchNextPage() {
            success, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let newCount = self.dataManager?.studentLocationCount {
                if newCount - oldCount > 0 {
                    // if we received any new data, update the table
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                } else if success {
                    // if we received no new data, we are likely at the end of the stream and shouldn't ask again
                    // until the user explicitly asks us to with a refresh.
                    self.preFetchEnabled = false
                }
            }
        }
    }
    
}

// MARK: - UITableViewDelegate
extension StudentLocationsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = dataManager?.studentLocationAtIndex(indexPath.item),
            updatedAt = item.updatedAt {
                Logger.info("Student Updated At: " + updatedAt)
        }
    }
    
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
 
        cell.textLabel?.text = studentLocationData?.fullname
        return cell
    }
}
