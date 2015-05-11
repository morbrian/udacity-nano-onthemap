//
//  Constants.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/30/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

struct Constants {
    
    static let UdacitySignupUrlString = "https://www.udacity.com/account/auth#!/signup"
    
    static let SuccessfulLoginSegue = "SuccessfulLoginSegue"
    static let StudentLocationCell = "StudentLocationCell"
    static let UserLocationCell = "UserLocationCell"
    static let StudentLocationAnnotationReuseIdentifier = "StudentLocationAnnotationReuseIdentifier"
    
    static let DeviceiPhone5Height = 568.0
    
    struct DateFormat {
        static let ISO8601 = "yyyy-MM-dd'T'HH:mm:ss.SZZZZZ"
    }
    
    struct Locale {
        static let EN_US_POSIX = "en_US_POSIX"
    }
}
