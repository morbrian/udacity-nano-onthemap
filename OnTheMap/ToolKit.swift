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
    
    // try to manipulate the given string into a valid URL, or return nil if it can't be done.
    // for example, "www.google.com" would produce the URL "http://www.google.com"
    static func produceValidUrlFromString(string: String) -> NSURL? {
        var stringWithScheme: String
        if !string.lowercaseString.hasPrefix(WebClient.HttpScheme) || !string.lowercaseString.hasPrefix(WebClient.HttpsScheme) {
            stringWithScheme = "\(WebClient.HttpScheme)://\(string)"
        } else {
            stringWithScheme = string
        }
        
        if let url = NSURL(string: stringWithScheme),
            scheme = url.scheme,
            hostname = url.host
            where !hostname.isEmpty
        &&  (scheme.lowercaseString == WebClient.HttpScheme || scheme.lowercaseString == WebClient.HttpsScheme) {
                return url
        } else {
            return nil
        }
    }
    
}
