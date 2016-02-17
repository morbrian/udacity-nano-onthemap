//
//  OnTheMapParseWebClient.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/22/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// OnTheMapParseService
// Provides customized methods for accessing the Parse Service to perform operations tailored to the OnTheMap Application.
class OnTheMapParseService {
    
    private var parseClient: ParseClient!
    
    init() {
        parseClient = ParseClient(client: WebClient(), applicationId: AppDelegate.ParseApplicationId, restApiKey: AppDelegate.ParseRestApiKey)
    }
    
    // fetch a list of StudentInformation objects from the parse service, optionally constrained by several supported attributes.
    // limit: maximum number of student objects to return from service.
    // skip: number of items to skip before returning the remaining list.
    // orderedBy: the sort order of the objects to return.
    // olderThan: specifies items with updatedAt attributes older than the specified interval.
    // newerThan: specifies items with updatedAt more recent thatn the specified interval.
    // completionHandler - studentInformation: array of StudentInformation objects matching the query constraints.
    func fetchStudents(limit: Int = 50, skip: Int = 0, orderedBy: String = ParseClient.DefaultSortOrder,
        olderThan: NSTimeInterval? = nil, newerThan: NSTimeInterval? = nil,
        completionHandler: (studentInformation: [StudentInformation]?, error: NSError?) -> Void) {
            
            func createUpdatedAtQueryWithValue(value: NSTimeInterval?, usingLogic logic: String) -> String? {
                if var value = value {
                    if ParseClient.Logic.GreaterThan == logic {
                        // increment a little to avoid repeatedly getting the most recent one
                        value++
                    }
                    return "{\"\(ParseClient.ParseJsonKey.UpdatedAt)\":{\"$\(logic)\":\"\(ParseClient.DateFormatter.stringFromDate(NSDate(timeIntervalSince1970: value)))\"}}"
                } else {
                    return nil
                }
            }
            
            let olderThanQuery = createUpdatedAtQueryWithValue(olderThan, usingLogic: ParseClient.Logic.LessThan)
            let newerThanQuery = createUpdatedAtQueryWithValue(newerThan, usingLogic: ParseClient.Logic.GreaterThan)

            // fetch items that are older than the last one we retrieved, or newer than the most recent
            // for example: {"$or":[{"updatedAt":{"$lt":"2015-03-10T20:23:49.5-07:00"}},{"updatedAt":{"$gt":"2015-05-23T23:55:13.6-07:00"}}]}]
            var whereClause: String?
            switch (olderThanQuery, newerThanQuery) {
            case let (older, nil): whereClause = older
            case let (nil, newer): whereClause = newer
            case let (older, newer): whereClause = "{\"$or\":[\(older!),\(newer!)]}"
            }

            parseClient.fetchResultsForClassName(OnTheMapParseService.StudentLocationClassName,
                limit: limit, skip: skip, orderedBy: orderedBy, whereClause: whereClause) {
            resultsArray, error in
            completionHandler(studentInformation: self.parseResults(resultsArray), error: error)
        }
    }
    
    // fetch the StudentInformation object with the specified Student key.
    // key: unique student identity key.
    // completionHandler - studentInformation: array of all information objects for the specified key.
    func fetchStudentInformationForKey(key: String,
        completionHandler: (studentInformation: [StudentInformation]?, error: NSError?) -> Void) {
            parseClient.fetchResultsForClassName(OnTheMapParseService.StudentLocationClassName,
                whereClause: "{\"\(ParseJsonKey.UniqueKey)\":\"\(key)\"}") { resultsArray, error in
                    completionHandler(studentInformation: self.parseResults(resultsArray), error: error)
            }
    }
    
    // create new student information object
    // studentInformation: student object with new attribute values to create new object with.
    // completion-handler - studentInformation: the studentInformation object with the new objecId, createdAt, and updatedAt properties set.
    func createStudentInformation(studentInformation: StudentInformation,
        completionHandler: (studentInformation: StudentInformation?, error: NSError?) -> Void) {
     
            parseClient.createObjectOfClassName(OnTheMapParseService.StudentLocationClassName,
                withProperties: studentInformation.rawData) { objectId, createdAt, error in
                    if let objectId = objectId, createdAt = createdAt {
                        var updatedInfo = studentInformation.rawData
                        updatedInfo[ParseJsonKey.ObjectId] = objectId
                        updatedInfo[ParseJsonKey.CreateAt] = createdAt
                        updatedInfo[ParseJsonKey.UpdatedAt] = createdAt
                        completionHandler(studentInformation: StudentInformation(parseData: updatedInfo), error: nil)
                    } else {
                        completionHandler(studentInformation: nil, error: error)
                    }
            }
    }
    
    // update student information object
    // studentInformation: student object with new attribute values to update server object with same objectId.
    // completion-handler - studentInformation: the studentInformation object with the modified updatedAt property set.
    func updateStudentInformation(studentInformation: StudentInformation,
        completionHandler: (studentInformation: StudentInformation?, error: NSError?) -> Void) {
            
            parseClient.updateObjectOfClassName(OnTheMapParseService.StudentLocationClassName,
                withProperties: studentInformation.rawData, objectId: studentInformation.objectId) { updatedAt, error in
                    if let updatedAt = updatedAt {
                        var updatedInfo = studentInformation.rawData
                        updatedInfo[ParseJsonKey.UpdatedAt] = updatedAt
                        completionHandler(studentInformation: StudentInformation(parseData: updatedInfo), error: nil)
                    } else {
                        completionHandler(studentInformation: nil, error: error)
                    }
            }
    }
    
    // delete student information object on server
    // studentInformation: object with objectId to delete on server
    // completionHandler - studentInformation: copy of object that was just deleted on server.
    func deleteStudentInformation(studentInformation: StudentInformation,
        completionHandler: (studentInformation: StudentInformation?, error: NSError?) -> Void) {
            
            parseClient.deleteObjectOfClassName(OnTheMapParseService.StudentLocationClassName,
                objectId: studentInformation.objectId) { error in
                    if let error = error {
                        completionHandler(studentInformation: nil, error: error)
                    } else {
                        completionHandler(studentInformation: studentInformation, error: nil)
                    }
            }
    }

    
    // MARK: - Data Parsers
    
    // parse teh results array into a list of StudentInformation objects
    private func parseResults(resultsArray: [[String:AnyObject]]?) -> [StudentInformation]? {
        if let resultsArray = resultsArray {
            let optionalStudentLocations = resultsArray.map(){StudentInformation(parseData: $0)}
            let filteredStudents = optionalStudentLocations.filter() { $0 != nil }
            let students = filteredStudents.map() { $0! as StudentInformation }
            return students
        } else {
            return nil
        }
    }
}

// MARK: - Constants

extension OnTheMapParseService {
    static let StudentLocationClassName = "StudentLocation"
    
    struct ParseJsonKey {
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

// MARK: - Errors 

extension OnTheMapParseService {
    
    private static let ErrorDomain = "OnTheMapParseWebClient"

    private enum ErrorCode: Int, CustomStringConvertible {
        case ResponseContainedNoResultObject = 1, ParseClientApiFailure
        
        var description: String {
            switch self {
            case ResponseContainedNoResultObject: return "Response data did not provide a results object."
            case ParseClientApiFailure: return "Parse Client failed to find data but also failed to provide a valid error object."
            }
        }
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    private static func errorForCode(code: ErrorCode) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : code.description]
        return NSError(domain: OnTheMapParseService.ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}


