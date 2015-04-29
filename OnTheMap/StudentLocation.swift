//
//  StudentLocation.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/23/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class StudentLocation: NSObject {
    
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
    
    init?(data: [String:AnyObject]) {

        // set the required attributes
        objectId = data[JsonKey.ObjectId] as? String ?? ""
        studentKey = data[JsonKey.UniqueKey] as? String ?? ""
        latitude = data[JsonKey.Latitude] as? Float ?? Float.NaN
        longitude = data[JsonKey.Longitude] as? Float ?? Float.NaN

        // set the optional attributes
        firstname = data[JsonKey.Firstname] as? String
        lastname = data[JsonKey.Lastname] as? String
        mapString = data[JsonKey.MapString] as? String
        updatedAt = data[JsonKey.UpdatedAt] as? String
        createdAt = data[JsonKey.CreateAt] as? String
        mediaUrl = data[JsonKey.MediaUrl] as? String
        
        super.init()
        if !validState() {
            return nil
        }
    }
    
    private func validState() -> Bool {
        return !objectId.isEmpty
        && !studentKey.isEmpty
        && validLatitude(latitude)
        && validLongitude(longitude)
    }
    
    private func validLatitude(latitude: Float) -> Bool {
        return latitude <= 90.0 && latitude >= -90.0
    }
    
    private func validLongitude(longitude: Float) -> Bool {
        return longitude <= 180.0 && longitude >= -180.0
    }
}

extension StudentLocation {
    struct JsonKey {
        static let ObjectId = ParseClient.ParseJsonKey.ObjectId
        static let CreateAt = ParseClient.ParseJsonKey.CreateAt
        static let UpdatedAt = ParseClient.ParseJsonKey.UpdatedAt
        static let UniqueKey = "uniqueKey"
        static let MapString = "mapString"
        static let MediaUrl = "mediaURL"
        static let Firstname = "firstName"
        static let Lastname = "lastName"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
}
