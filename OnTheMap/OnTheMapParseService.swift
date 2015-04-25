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
    
    func fetchStudentLocations(limit: Int = 50, skip: Int = 0,
        completionHandler: (studentLocations: [StudentLocation]?, error: NSError?) -> Void) {
            parseClient.fetchResultsForClassName(OnTheMapParseService.StudentLocationClassName, limit: limit, skip: skip) {
            resultsArray, error in
            completionHandler(studentLocations: self.parseResults(resultsArray), error: error)
        }
    }
    
    // MARK: - Data Parsers
    
    private func parseResults(resultsArray: [[String:AnyObject]]?) -> [StudentLocation]? {
        if let resultsArray = resultsArray {
            let optionalStudentLocations = resultsArray.map(){StudentLocation(data: $0)}
            var studentLocations = [StudentLocation]()
            for item in optionalStudentLocations {
                if let location = item {
                    studentLocations.append(location)
                }
            }
            return studentLocations
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
