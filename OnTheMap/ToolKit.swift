//
//  ToolKit.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

// ToolKit
// catch all class for general purpose useful functions
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
    static func produceValidUrlFromString(string: String) -> NSURL? {
        var stringWithScheme = string
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
    
    // use the md5 hash of the input email string to produce the appropriate the Gravatar URL
    static func produceGravatarUrlFromEmailString(email: String) -> NSURL? {
        return NSURL(string: "https://www.gravatar.com/avatar/\(email.md5)")
    }
    
    // turn the search text into a Bing search query URL
    static func produceBingUrlFromSearchString(searchString: String) -> NSURL? {
        let bingUrlString = "https://www.bing.com/search"
        let encodedSearch = WebClient.encodeParameters(["q":searchString])
        let queryString = encodedSearch.stringByReplacingOccurrencesOfString("%20", withString: "+")
        return NSURL(string: "\(bingUrlString)?\(queryString)")
    }
}

// extend String with a property to get its md5 hash
//
// Thank you StackOverflow!
// http://stackoverflow.com/questions/24123518/how-to-use-cc-md5-method-in-swift-language
//
extension String  {
    var md5: String! {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        
        var hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format: hash as String)
    }
}
