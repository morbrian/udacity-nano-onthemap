//
//  StudentLocation.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/23/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// MARK: - StudentIdentity

// identity type for student objects, aka "key" property
typealias StudentIdentity = String

// MARK: - StudentInformation

// StudentInformation
// type safe wrapper around basic name-value pairs representing Student data
// NOTES: the getter/setter approach here has room for optimization improvements,
// but is a design tradeoff for ease of access to the original dictionary structure.
struct StudentInformation {
    
    private var data: [String:AnyObject]
    
    private let dateFormatter: NSDateFormatter
    
    init?(parseData data: [String:AnyObject]) {
        self.data = data
        // dictionary must at least have a key
        var uniqueKey = data[OnTheMapParseService.ParseJsonKey.UniqueKey] as? String ?? ""
        if uniqueKey.isEmpty {
            return nil
        }
        dateFormatter = ParseClient.DateFormatter
    }
    
    var rawData: [String:AnyObject] {
        return data
    }
    
    var studentKey: StudentIdentity {
        return data[OnTheMapParseService.ParseJsonKey.UniqueKey] as? String ?? ""
    }
    
    var objectId: String? {
        get {
            return data[OnTheMapParseService.ParseJsonKey.ObjectId] as? String
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.ObjectId] = newValue
        }
    }
    
    var latitude: Float? {
        get {
            return StudentInformation.validLatitude(data[OnTheMapParseService.ParseJsonKey.Latitude] as? Float)
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.Latitude] = StudentInformation.validLatitude(newValue)
        }
    }

    
    var longitude: Float? {
        get {
            return StudentInformation.validLongitude(data[OnTheMapParseService.ParseJsonKey.Longitude] as? Float)
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.Longitude] = StudentInformation.validLongitude(newValue)
        }
    }

    var firstname: String? {
        get {
            return data[OnTheMapParseService.ParseJsonKey.Firstname] as? String
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.Firstname] = newValue
        }
    }

    var lastname: String? {
        get {
            return data[OnTheMapParseService.ParseJsonKey.Lastname] as? String
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.Lastname] = newValue
        }
    }

    var mediaUrl: String? {
        get {
            return data[OnTheMapParseService.ParseJsonKey.MediaUrl] as? String
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.MediaUrl] = newValue
        }
    }

    var mapString: String? {
        get {
            return data[OnTheMapParseService.ParseJsonKey.MapString] as? String
        }
        set {
            data[OnTheMapParseService.ParseJsonKey.MapString] = newValue
        }
    }

    var updatedAt: NSTimeInterval? {
        get {
            return dateFromString(data[OnTheMapParseService.ParseJsonKey.UpdatedAt] as? String)?.timeIntervalSince1970
        }
        set {
            if let newValue = newValue {
                data[OnTheMapParseService.ParseJsonKey.UpdatedAt] = dateFormatter.stringFromDate(NSDate(timeIntervalSince1970:newValue))
            } else {
                data.removeValueForKey(OnTheMapParseService.ParseJsonKey.UpdatedAt)
            }
        }
    }

    var createdAt: NSTimeInterval? {
        get {
            return dateFromString(data[OnTheMapParseService.ParseJsonKey.CreateAt] as? String)?.timeIntervalSince1970
        }
        set {
            if let newValue = newValue {
                data[OnTheMapParseService.ParseJsonKey.CreateAt] = dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: newValue))
            } else {
                data.removeValueForKey(OnTheMapParseService.ParseJsonKey.CreateAt)
            }
        }
    }

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
    
    private func dateFromString(string: String?) -> NSDate? {
        if let string = string {
            return dateFormatter.dateFromString(string)
        } else {
            return nil
        }
    }
    
    private static func validLatitude(latitude: Float?) -> Float? {
        if let latitude = latitude
            where latitude <= 90.0 && latitude >= -90.0 {
                return latitude
        } else {
            return nil
        }
    }
    
    private static func validLongitude(longitude: Float?) -> Float? {
        if let longitude = longitude
            where longitude <= 180.0 && longitude >= -180.0 {
                return longitude
        } else {
            return nil
        }
    }

}

// MARK: - StudentInformation: InfoItem

// implement the InfoItem requirements so we can store StudentInformation in an InfoPool
extension StudentInformation: InfoItem {

    typealias IdType = String
    var id: String { return objectId ?? "" }

    typealias OwnerType = StudentIdentity
    var owner: StudentIdentity { return studentKey }
    
    typealias OrderByType = NSTimeInterval
    var orderBy: NSTimeInterval { return updatedAt ?? NSDate(timeIntervalSince1970: 0).timeIntervalSince1970 }
    
}
