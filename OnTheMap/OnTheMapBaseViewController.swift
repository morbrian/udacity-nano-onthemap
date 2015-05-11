//
//  OnTheMapBaseViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/29/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// OnTheMapBaseViewController
// Base class for each view of the On The Map TabBar Controller.
// Configures top-bar buttons, and provides basic data loading capabilities to child view controllers.
class OnTheMapBaseViewController: UIViewController {
    
    // default max number of items per fetch
    let FetchLimit = 100
    let PreFetchTrigger = 20

    // access point for all data loading and in memory cache
    var dataManager: StudentDataAccessManager?
    
    // decides whether requests should be made for additional data
    var preFetchEnabled = true
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        if let tabBarController = self.tabBarController as? ManagingTabBarController {
            dataManager = tabBarController.dataManager
            if let dm = dataManager {
                dm.fetchLimit = FetchLimit
                if dm.studentLocationCount == 0 {
                    fetchNextPage()
                }
                if let loggedInUser = dm.loggedInUser {
                    fetchCurrentUserLocationData()
                }
                var refreshButton = produceRefreshButton()
                var addLocationButton = produceAddLocationButton()
                addLocationButton.enabled = dm.authenticated
                navigationItem.rightBarButtonItems = [refreshButton, addLocationButton]
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        preFetchEnabled = true
    }
    
    // MARK: UIBarButonItem Producers
    
    // return configured Add Location button
    private func produceAddLocationButton() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage(named: "Pin"), style: UIBarButtonItemStyle.Plain, target: self, action: "addLocationAction:")
    }
    
    // return configured Refresh button
    private func produceRefreshButton() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refreshAction:")
    }
    
    // MARK: Methods for Subclass to Override
    
    // perform work that must be done to keep display in sync with model
    // basically an abstract method that should be implemented by subclasses
    func updateDisplayFromModel() {}
    
    // provide basic status bar activity indicator.
    // subclasses can call super, then perform any additional work as appropriate.
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
        }
    }
    
    // MARK: Base Functionality
    
    // fetch all items created by the currently logged in user
    // this helps us get items for the current user that may not
    // be in the top 100.
    func fetchCurrentUserLocationData() {
        networkActivity(true)
        dataManager?.fetchDataForCurrentUser() { success, error in
            self.networkActivity(false)
        }
    }
    
    // Make another fetch request for the next available data
    // TODO: this will not detect DELETE operations made by other users after initial load.
    func fetchNextPage() {
        if !preFetchEnabled {
            return
        }
        
        let oldCount = self.dataManager?.studentLocationCount ?? 0
        networkActivity(true)
        dataManager?.fetchNextPage() {
            success, error in
            self.networkActivity(false)
            if let newCount = self.dataManager?.studentLocationCount {
                if newCount - oldCount > 0 {
                    // if we received any new data, update the table
                    self.updateDisplayFromModel()
                } else if success {
                    // if we received no new data, we are likely at the end of the stream and shouldn't ask again
                    // until the user explicitly asks us to with a refresh.
                    self.preFetchEnabled = false
                } else if let error = error {
                    self.showErrorAlert(title: "Failed to Fetch Data", message: error.localizedDescription)
                } else {
                    // this message should never occur, we think we differentiate all errors with a non-nil error object.
                    self.showErrorAlert(title: "Uh Oh, Spaghettios!", message: "An unspecified error occurred, Please take a moment to 'Like' us on Facebook.")
                }
            }
        }
    }
    
    // fetch additional data, includes recent updates or data older than
    func refreshAction(sender: AnyObject!) {
        fetchNextPage()
    }
    
    // informs user of error status
    func showErrorAlert(#title: String, message: String) {
        var alert = UIAlertController(
            title: title,
            message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default) {
            action -> Void in
            // nothing to do
        })
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func sendToUrlString(urlString: String) {
        dataManager?.validateUrlString(urlString) { success, errorMessage in
            if success {
                UIApplication.sharedApplication().openURL(NSURL(string: urlString)!)
            } else if let errorMessage = errorMessage {
                self.showErrorAlert(title: "URL Inaccessible", message: errorMessage)
            } else {
                self.showErrorAlert(title: "URL Inaccessible", message: "Unidentified Failure Connecting To \(urlString)")
            }
        }
    }
    
    // action when "Add Location" button is tapped
    // pop up Alert dialog if user needs to confirm overwriting old data.
    func addLocationAction(sender: AnyObject!) {
        if let dataManager = dataManager where dataManager.loggedInUserDoesHaveLocation() {
            var alert = UIAlertController(title: "Add Study Location", message: "Would you like to overwrite your previously entered location?", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) {
                action -> Void in
                    // nothing to do
                })
            alert.addAction(UIAlertAction(title: "Continue", style: .Default) {
                action -> Void in
                    self.performSegueWithIdentifier("ReverseGeocodeSegue", sender: self)
                })
            presentViewController(alert, animated: true, completion: nil)
        } else {
            performSegueWithIdentifier("ReverseGeocodeSegue", sender: self)
        }
        
    }
    
    // segue to GeocodeViewController to ad new location
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? GeocodeViewController {
            destination.dataManager = dataManager
        }
    }
}
