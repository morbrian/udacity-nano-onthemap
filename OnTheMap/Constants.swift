//
//  Constants.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/30/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// Constants used Application wide
struct Constants {
    
    // MARK: Application Info
    
    static let UdacitySignupUrlString = "https://www.udacity.com/account/auth#!/signup"
    static let MapSpanDistanceMeters = 300000.0
    static let GravatarImageSize = 80.0
    
    
    // MARK: StoryBoard Identifiers
    
    static let SuccessfulLoginSegue = "SuccessfulLoginSegue"
    static let ReturnToLoginScreenSegue = "ReturnToLoginScreenSegue"
    static let GeocodeSegue = "GeocodeSegue"
    static let StudentLocationCell = "StudentLocationCell"
    static let StudentLocationCollectionItem = "StudentLocationCollectionItem"
    static let UserLocationCell = "UserLocationCell"
    static let StudentLocationAnnotationReuseIdentifier = "StudentLocationAnnotationReuseIdentifier"
    
    // MARK: Physical Device Info
    
    static let DeviceiPhone5Height = 568.0

}
