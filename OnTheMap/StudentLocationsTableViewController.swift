//
//  MarkerListViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class StudentLocationsTableViewController: OnTheMapBaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func updateDisplayFromModel() {
        tableView.reloadData()
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
