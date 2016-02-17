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
// type safe wrapper around simple name-value pairs representing Student data
struct StudentInformation {
    
    // name value property pairs
    private var data: [String:AnyObject]
    
    
    // student unique identifier
    let studentKey: StudentIdentity
    
    // unique identifier of the objects data
    var objectId: String?
    
    // student first name
    var firstname: String?
    
    // student last name
    var lastname: String?
    
    // any url, should be properly formed
    var mediaUrl: String?
    
    // place name
    var mapString: String?
    
    // geographic latitude degrees
    private var _latitude: Float?
    var latitude: Float? {
        get {
            return _latitude
        }
        set {
            _latitude = StudentInformation.validLatitude(newValue)
        }
    }
    
    // geographic longitude degrees
    var _longitude: Float?
    var longitude: Float? {
        get {
            return _longitude
        }
        set {
            _longitude = StudentInformation.validLongitude(newValue)
        }
    }
    
    // last time this object was updated
    var updatedAt: NSTimeInterval?
    
    // time this object was created
    var createdAt: NSTimeInterval?
    
    // student email, excluded form raw data
    var email: String?
    
    
    // firstname + lastname
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
    
    // formatter for Parse date properties on student data objects
    private let dateFormatter: NSDateFormatter
    
    init?(parseData data: [String:AnyObject]) {
        dateFormatter = ParseClient.DateFormatter
        
        self.data = data
        
        studentKey = data[OnTheMapParseService.ParseJsonKey.UniqueKey] as? String ?? ""
        objectId = data[OnTheMapParseService.ParseJsonKey.ObjectId] as? String
        firstname = data[OnTheMapParseService.ParseJsonKey.Firstname] as? String
        lastname = data[OnTheMapParseService.ParseJsonKey.Lastname] as? String
        mediaUrl = data[OnTheMapParseService.ParseJsonKey.MediaUrl] as? String
        mapString = data[OnTheMapParseService.ParseJsonKey.MapString] as? String
        latitude = data[OnTheMapParseService.ParseJsonKey.Latitude] as? Float
        longitude = data[OnTheMapParseService.ParseJsonKey.Longitude] as? Float
        updatedAt = dateFromString(data[OnTheMapParseService.ParseJsonKey.UpdatedAt] as? String)?.timeIntervalSince1970
        createdAt = dateFromString(data[OnTheMapParseService.ParseJsonKey.CreateAt] as? String)?.timeIntervalSince1970
        
        // dictionary must at least have a key
        if studentKey.isEmpty {
            return nil
        }
    }
    
    // the raw name-value-pair dictionary
    var rawData: [String:AnyObject] {
        var data = [String:AnyObject]()
        data = mapNonNilValue(studentKey, forPropertyName: OnTheMapParseService.ParseJsonKey.UniqueKey, inMap: data)
        data = mapNonNilValue(objectId, forPropertyName: OnTheMapParseService.ParseJsonKey.ObjectId, inMap: data)
        data = mapNonNilValue(firstname, forPropertyName: OnTheMapParseService.ParseJsonKey.Firstname, inMap: data)
        data = mapNonNilValue(lastname, forPropertyName: OnTheMapParseService.ParseJsonKey.Lastname, inMap: data)
        data = mapNonNilValue(mediaUrl, forPropertyName: OnTheMapParseService.ParseJsonKey.MediaUrl, inMap: data)
        data = mapNonNilValue(mapString, forPropertyName: OnTheMapParseService.ParseJsonKey.MapString, inMap: data)
        data = mapNonNilValue(StudentInformation.validLatitude(latitude), forPropertyName: OnTheMapParseService.ParseJsonKey.Latitude, inMap: data)
        data = mapNonNilValue(StudentInformation.validLongitude(longitude), forPropertyName: OnTheMapParseService.ParseJsonKey.Longitude, inMap: data)
        if let updatedAt = updatedAt {
            data = mapNonNilValue(dateFormatter.stringFromDate(NSDate(timeIntervalSince1970:updatedAt)), forPropertyName: OnTheMapParseService.ParseJsonKey.UpdatedAt, inMap: data)
        }
        if let createdAt = createdAt {
            data = mapNonNilValue(dateFormatter.stringFromDate(NSDate(timeIntervalSince1970:createdAt)), forPropertyName: OnTheMapParseService.ParseJsonKey.CreateAt, inMap: data)
        }

        return data
    }
    
    // include value for name only if value is non-nil
    private func mapNonNilValue(value: AnyObject?, forPropertyName key: String, var inMap map:[String:AnyObject]) -> [String:AnyObject] {
        if let value: AnyObject = value {
            map[key] = value
        }
        return map
    }
    
    // parse the string into a data object
    private func dateFromString(string: String?) -> NSDate? {
        if let string = string {
            return dateFormatter.dateFromString(string)
        } else {
            return nil
        }
    }
    
    // return a valid latitude or nil
    private static func validLatitude(latitude: Float?) -> Float? {
        if let latitude = latitude
            where latitude <= 90.0 && latitude >= -90.0 {
                return latitude
        } else {
            return nil
        }
    }
    
    // return a valid longitude or nil
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

    typealias GroupType = StudentIdentity
    var group: StudentIdentity { return studentKey }
    
    typealias OrderByType = NSTimeInterval
    var orderBy: NSTimeInterval { return updatedAt ?? NSDate(timeIntervalSince1970: 0).timeIntervalSince1970 }
    
}
