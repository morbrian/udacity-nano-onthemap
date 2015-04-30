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
            dataManager?.fetchLimit = FetchLimit
            // only fetch on load if we are empty
            if let count = dataManager?.studentLocationCount where count == 0 {
                fetchNextPage()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        preFetchEnabled = true
    }
    
    // perform work that must be done to keep display in sync with model
    // basically an abstract method that should be implemented by subclasses
    func updateDisplayFromModel() {}
    
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
    
}
