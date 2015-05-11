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
    var pinImage: UIImage!
    
    override func viewDidLoad() {
        pinImage = UIImage(named: "Pin")
        super.viewDidLoad()
    }
    
    override func updateDisplayFromModel() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension StudentLocationsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = dataManager?.studentLocationAtIndex(indexPath.item),
            urlString = item.mediaUrl {
            self.sendToUrlString(urlString)
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
        cell.imageView?.image = pinImage
        return cell
    }
}
