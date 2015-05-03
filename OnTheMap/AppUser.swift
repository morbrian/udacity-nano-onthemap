//
//  User.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

typealias StudentIdentity = String

// represents the current user of our application.
// only the useridentifier is required as the user may not have set other information.
struct StudentInformation {
    
    // name or id identifying this user to the remote system
    var studentIdentity: StudentIdentity
    
    // nickname
    var nickname: String?
    
    // user first name
    var firstname: String?
    
    // user last name
    var lastname: String?
    
    // produce either gravatar or robohash
    var imageUrl: NSURL?
    
}

// getting gravatar
// md5 -s morbrian@me.com
// produces hash of email
// use hash for getting image
// http://gravatar.com/avatar/184f2c6ec61c195cb40e1ae6de07bf7f

//nickname = Brian;
//"first_name" = Brian;
//"last_name" = Moriarty;
//"_image_url" = "//robohash.org/udacity-u294215.png";
//    "key": "u294215",

