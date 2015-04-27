//
//  StudentLocation.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/23/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

struct StudentLocation {
    
    let objectId: String
    let studentKey: String
    let latitude: Float
    let longitude: Float
    
    let firstname: String?
    let lastname: String?
    let mediaUrl: String?
    let mapString: String?
    let updatedAt: String?
    let createdAt: String?
    
    init?(data: [String:AnyObject]) {
        if let inObjectId = data[JsonKey.ObjectId] as? String,
            let inStudentKey = data[JsonKey.UniqueKey] as? String,
            let inLatitude = data[JsonKey.Latitude] as? Float,
            let inLongitude = data[JsonKey.Longitude] as? Float {
                
                // set the required attributes
                objectId = inObjectId
                studentKey = inStudentKey
                latitude = inLatitude
                longitude = inLongitude
        
                // set the optional attributes
                firstname = data[JsonKey.Firstname] as? String
                lastname = data[JsonKey.Lastname] as? String
                mapString = data[JsonKey.MapString] as? String
                updatedAt = data[JsonKey.UpdatedAt] as? String
                createdAt = data[JsonKey.CreateAt] as? String
                mediaUrl = data[JsonKey.MediaUrl] as? String
        } else {
            return nil
        }
    }
}

extension StudentLocation {
    struct JsonKey {
        static let ObjectId = "objectId"
        static let UniqueKey = "uniqueKey"
        static let CreateAt = "createdAt"
        static let UpdatedAt = "updatedAt"
        static let MapString = "mapString"
        static let MediaUrl = "mediaURL"
        static let Firstname = "firstName"
        static let Lastname = "lastName"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
}
