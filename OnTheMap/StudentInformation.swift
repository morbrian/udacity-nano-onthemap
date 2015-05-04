//
//  StudentLocation.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/23/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

typealias StudentIdentity = String

struct StudentInformation {
    
    let studentKey: StudentIdentity
    
    var objectId: String? = nil
    var latitude: Float? = nil
    var longitude: Float? = nil
    var nickname: String? = nil
    var firstname: String? = nil
    var lastname: String? = nil
    var mediaUrl: String? = nil
    var mapString: String? = nil
    var updatedAt: String? = nil
    var createdAt: String? = nil
    
    var fullname: String {
        var fullname = ""
        if let firstname = firstname {
            fullname += firstname + " "
        }
        if let lastname = lastname {
            fullname += lastname
        }
        return fullname
    }

    init?(udacityData data: [String:AnyObject]) {
        // set the required attributes
        studentKey = data[UdacityService.UdacityJsonKey.Key] as? String ?? ""
        nickname = data[UdacityService.UdacityJsonKey.Firstname] as? String
        firstname = data[UdacityService.UdacityJsonKey.Firstname] as? String
        lastname = data[UdacityService.UdacityJsonKey.Lastname] as? String

        if studentKey.isEmpty {
            return nil
        }
    }

    
    init?(parseData data: [String:AnyObject]) {

        // set the required attributes
        studentKey = data[OnTheMapParseService.ParseJsonKey.UniqueKey] as? String ?? ""
        objectId = data[OnTheMapParseService.ParseJsonKey.ObjectId] as? String
        latitude = data[OnTheMapParseService.ParseJsonKey.Latitude] as? Float
        longitude = data[OnTheMapParseService.ParseJsonKey.Longitude] as? Float
        firstname = data[OnTheMapParseService.ParseJsonKey.Firstname] as? String
        lastname = data[OnTheMapParseService.ParseJsonKey.Lastname] as? String
        mapString = data[OnTheMapParseService.ParseJsonKey.MapString] as? String
        updatedAt = data[OnTheMapParseService.ParseJsonKey.UpdatedAt] as? String
        createdAt = data[OnTheMapParseService.ParseJsonKey.CreateAt] as? String
        mediaUrl = data[OnTheMapParseService.ParseJsonKey.MediaUrl] as? String
        
        if studentKey.isEmpty {
            return nil
        }
    }

}
