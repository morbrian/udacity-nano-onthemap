//
//  MarkerListViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// StudentLocationsTableViewController
// Displays all student locations in a table view
class StudentLocationsTableViewController: OnTheMapBaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func updateDisplayFromModel() {
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension StudentLocationsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        Logger.info("Tapped item at \(indexPath.item)")
        
        if let item = dataManager?.studentLocationAtIndex(indexPath.item) {
            Logger.info("\(item.rawData)")
            Logger.info("\(item.updatedAt)")
                //Logger.info("Student Updated At: \(NSDate(timeIntervalSince1970: updatedAt))")
                
                // TODO: open URL in Safari (assuming it's valid)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let currentCount = dataManager?.studentLocationCount
            where indexPath.item == currentCount - PreFetchTrigger {
                fetchNextPage()
        }
    }

}

// MARK: - UITableViewDataSource

extension StudentLocationsTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager?.studentLocationCount ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var studentLocationData = dataManager?.studentLocationAtIndex(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.StudentLocationCell, forIndexPath: indexPath) as! UITableViewCell
 
        cell.textLabel?.text = studentLocationData?.fullname
        return cell
    }
}
