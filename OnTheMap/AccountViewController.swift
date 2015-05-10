//
//  AccountViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/9/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class AccountViewController: OnTheMapBaseViewController {
    
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
extension AccountViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let item = dataManager?.userLocationAtIndex(indexPath.item),
            updatedAt = item.updatedAt {
                Logger.info("Student Updated At: \(NSDate(timeIntervalSince1970: updatedAt))")
        }
    }
    
    //    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    //        handleDeselectionEventForMemeAtIndex(indexPath.item)
    //    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        Logger.debug("called editing method...")
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            //deleteSingleMemeAtIndex(indexPath.item)
            Logger.debug("could call delete")
            if let studentInformation = dataManager?.userLocationAtIndex(indexPath.item) {
                dataManager?.deleteStudentInformation(studentInformation)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension AccountViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Logger.debug("table view has \(dataManager?.userLocationCount ?? 0) items")
        return dataManager?.userLocationCount ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var userLocationData = dataManager?.userLocationAtIndex(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.UserLocationCell, forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = userLocationData?.mapString
        cell.detailTextLabel?.text = userLocationData?.objectId
        Logger.debug("UserLocationObject: \(userLocationData?.rawData)")
        return cell
    }
}