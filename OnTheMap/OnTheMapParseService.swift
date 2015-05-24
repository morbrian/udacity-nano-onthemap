//
//  OnTheMapParseWebClient.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/22/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class OnTheMapParseService {
    
    private var parseClient: ParseClient!
    
    init() {
        parseClient = ParseClient(client: WebClient(), applicationId: AppDelegate.ParseApplicationId, restApiKey: AppDelegate.ParseRestApiKey)
    }
    
    func fetchStudents(limit: Int = 50, skip: Int = 0, orderedBy: String = ParseClient.DefaultSortOrder,
        olderThan: NSTimeInterval? = nil, newerThan: NSTimeInterval? = nil,
        completionHandler: (studentInformation: [StudentInformation]?, error: NSError?) -> Void) {
            
            func createUpdatedAtQueryWithValue(value: NSTimeInterval?, usingLogic logic: String) -> String? {
                if var value = value {
                    if "gt" == logic {
                        // increment a little to avoid repeatedly getting the most recent one
                        value++
                    }
                    return "{\"\(ParseClient.ParseJsonKey.UpdatedAt)\":{\"$\(logic)\":\"\(ParseClient.DateFormatter.stringFromDate(NSDate(timeIntervalSince1970: value)))\"}}"
                } else {
                    return nil
                }
            }
            
            let olderThanQuery = createUpdatedAtQueryWithValue(olderThan, usingLogic: "lt")
            let newerThanQuery = createUpdatedAtQueryWithValue(newerThan, usingLogic: "gt")

            // fetch items that are older than the last one we retrieved, or newer than the most recent
            // for example: {"$or":[{"updatedAt":{"$lt":"2015-03-10T20:23:49.5-07:00"}},{"updatedAt":{"$gt":"2015-05-23T23:55:13.6-07:00"}}]}]
            var whereClause: String?
            switch (olderThanQuery, newerThanQuery) {
            case let (older, nil): whereClause = older
            case let (nil, newer): whereClause = newer
            case let (older, newer): whereClause = "{\"$or\":[\(older!),\(newer!)]}"
            default: whereClause = nil
            }

            parseClient.fetchResultsForClassName(OnTheMapParseService.StudentLocationClassName,
                limit: limit, skip: skip, orderedBy: orderedBy, whereClause: whereClause) {
            resultsArray, error in
            completionHandler(studentInformation: self.parseResults(resultsArray), error: error)
        }
    }
    
    func fetchStudentInformationForKey(key: String,
        completionHandler: (studentInformation: [StudentInformation]?, error: NSError?) -> Void) {
            parseClient.fetchResultsForClassName(OnTheMapParseService.StudentLocationClassName,
                whereClause: "{\"\(ParseJsonKey.UniqueKey)\":\"\(key)\"}") {
                resultsArray, error in
                completionHandler(studentInformation: self.parseResults(resultsArray), error: error)
            }
    }
    
    func createStudentInformation(studentInformation: StudentInformation,
        completionHandler: (studentInformation: StudentInformation?, error: NSError?) -> Void) {
     
            parseClient.createObjectOfClassName(OnTheMapParseService.StudentLocationClassName,
                withProperties: studentInformation.rawData) {
                    objectId, createdAt, error in
                    Logger.info("Retrieved back [objectId=\(objectId)][createdAt=\(createdAt)][error=\(error)]")
                    if let objectId = objectId, createdAt = createdAt {
                        var updatedInfo = studentInformation.rawData
                        updatedInfo[ParseJsonKey.ObjectId] = objectId
                        updatedInfo[ParseJsonKey.CreateAt] = createdAt
                        updatedInfo[ParseJsonKey.UpdatedAt] = createdAt
                        completionHandler(studentInformation: StudentInformation(parseData: updatedInfo), error: nil)
                    } else {
                        Logger.error("Create StudentInformation Failed")
                        completionHandler(studentInformation: nil, error: error)
                    }
            }
    }
    
    func updateStudentInformation(studentInformation: StudentInformation,
        completionHandler: (studentInformation: StudentInformation?, error: NSError?) -> Void) {
            
            parseClient.updateObjectOfClassName(OnTheMapParseService.StudentLocationClassName,
                withProperties: studentInformation.rawData, objectId: studentInformation.objectId) {
                    updatedAt, error in
                    Logger.info("Retrieved back [updatedAt=\(updatedAt)][error=\(error)]")
                    if let updatedAt = updatedAt {
                        var updatedInfo = studentInformation.rawData
                        updatedInfo[ParseJsonKey.UpdatedAt] = updatedAt
                        completionHandler(studentInformation: StudentInformation(parseData: updatedInfo), error: nil)
                    } else {
                        Logger.error("Create StudentInformation Failed")
                        completionHandler(studentInformation: nil, error: error)
                    }
            }
    }
    
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
}

// MARK: - Errors {

extension OnTheMapParseService {
    
    private static let ErrorDomain = "OnTheMapParseWebClient"

    private enum ErrorCode: Int, Printable {
        case ResponseContainedNoResultObject = 1, ParseClientApiFailure
        
        var description: String {
            switch self {
            case ResponseContainedNoResultObject: return "Response data did not provide a results object."
            case ParseClientApiFailure: return "Parse Client failed to find data but also failed to provide a valid error object."
            default: return "Unknown Error"
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

extension OnTheMapParseService {
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

