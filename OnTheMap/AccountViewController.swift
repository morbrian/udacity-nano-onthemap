//
//  AccountViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/9/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// Account ViewController
// Displays the locations specific to the current user,
// optionally allows current user to change setting allow
// multiple locations to be entered
class AccountViewController: OnTheMapBaseViewController {
    
    @IBOutlet weak var fullNameTextField: UILabel!
    @IBOutlet weak var studentAvatarImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var multipleEntriesToggle: UISwitch!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fullNameTextField.text = dataManager?.loggedInUser?.fullname
        multipleEntriesToggle.on = dataManager?.userAllowedMultiplentries ?? false
        showUserAvatar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: Overrides from OnTheMapBaseViewController
    
    override func updateDisplayFromModel() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    // MARK: IBActions
    
    @IBAction func changedMultipleEntries(sender: UISwitch) {
        dataManager?.userAllowedMultiplentries = sender.on
    }
    
    
    // MARK: Base Capability
    
    // get the users Gravatar image and display it
    private func showUserAvatar() {
        networkActivity(true)
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            if let loggedInUser = self.dataManager?.loggedInUser, email = loggedInUser.email,
                url = ToolKit.produceGravatarUrlFromEmailString(email), imageData = NSData(contentsOfURL: url) {
                    self.networkActivity(false)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.studentAvatarImageView.image = UIImage(data: imageData)
                        self.studentAvatarImageView.backgroundColor = nil
                    }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension AccountViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            networkActivity(true)
            if let studentInformation = dataManager?.userLocationAtIndex(indexPath.item) {
                dataManager?.deleteStudentInformation(studentInformation) { success, error in
                    self.networkActivity(false)
                    if success {
                        dispatch_async(dispatch_get_main_queue()) {
                            if let objectId = studentInformation.objectId {
                                self.dataManager?.clearUserLocationWithId(objectId)
                            }
                            tableView.reloadData()
                        }
                    } else if let error = error {
                        ToolKit.showErrorAlert(viewController: self, title: "Delete Failed", message: error.localizedDescription)
                    } else {
                        Logger.error("Delete Failed, But Error Not Specified")
                         ToolKit.showErrorAlert(viewController: self, title: "Delete Failed", message: "")
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension AccountViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager?.userLocationCount ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var userLocationData = dataManager?.userLocationAtIndex(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.UserLocationCell, forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = userLocationData?.mapString
        cell.detailTextLabel?.text = userLocationData?.objectId
        return cell
    }
}