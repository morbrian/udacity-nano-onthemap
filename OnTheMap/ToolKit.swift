//
//  ToolKit.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class ToolKit {
    
    // informs user of error status
    static func showErrorAlert(#viewController: UIViewController, title: String, message: String) {
        var alert = UIAlertController(
            title: title,
            message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default) {
            action -> Void in
            // nothing to do
            })
        dispatch_async(dispatch_get_main_queue()) {
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
