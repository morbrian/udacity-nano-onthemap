//
//  OnTheMapBaseViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/29/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class OnTheMapBaseViewController: UIViewController {
    
    let FetchLimit = 100
    let PreFetchTrigger = 20

    var dataManager: StudentDataAccessManager?
    
    var preFetchEnabled = true
    
    override func viewDidLoad() {
        if let tabBarController = self.tabBarController as? ManagingTabBarController {
            dataManager = tabBarController.dataManager
            if let dm = dataManager {
                dm.fetchLimit = FetchLimit
                if dm.studentLocationCount == 0 {
                    fetchNextPage()
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
    
    // MARK: Subclass Should Override
    
    // perform work that must be done to keep display in sync with model
    // basically an abstract method that should be implemented by subclasses
    func updateDisplayFromModel() {}
    
    // MARK: Base Functionality
    
    func fetchNextPage() {
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
                        self.updateDisplayFromModel()
                    }
                } else if success {
                    // if we received no new data, we are likely at the end of the stream and shouldn't ask again
                    // until the user explicitly asks us to with a refresh.
                    self.preFetchEnabled = false
                }
            }
        }
    }
    
    func refreshAction(sender: AnyObject!) {
        fetchNextPage()
    }
    
    func addLocationAction(sender: AnyObject!) {
        performSegueWithIdentifier("ReverseGeocodeSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? ReverseGeocodeViewController {
            destination.dataManager = dataManager
        }
    }
}
