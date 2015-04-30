//
//  ParseClient.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/24/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation
// ParseClient
// Provides simple api layer on top of WebClient designed to encapsulate
// the common patterns associated with REST apis based on the Parse framework.
public class ParseClient {

    private var applicationId: String!
    private var restApiKey: String!
    
    private var StandardHeaders: [String:String] {
        return [
            "X-Parse-Application-Id":applicationId,
            "X-Parse-REST-API-Key":restApiKey
        ]
    }
    
    private var webClient: WebClient!
    
    // client: insteance of a WebClient
    // applicationId: valid ID provided to this App for use with the Parse service.
    // restApiKey: a developer API Key provided by registering with the Parse service.
    public init(client: WebClient, applicationId: String, restApiKey: String) {
        self.webClient = client
        self.applicationId = applicationId
        self.restApiKey = restApiKey
    }
    
    // className: the object model classname of the data type on Parse
    // limit: maximum number of objects to fetch
    // skip: number of objects to skip before fetching the limit.
    // orderedBy: name of an attribute on the object model to sort results by.
    public func fetchResultsForClassName(className: String, limit: Int = 50, skip: Int = 0, orderedBy: String = ParseJsonKey.UpdatedAt,
        completionHandler: (resultsArray: [[String:AnyObject]]?, error: NSError?) -> Void) {
            let request = webClient.createHttpGetRequestForUrlString("\(ParseClient.ObjectUrl)/\(className)",
                includeHeaders: StandardHeaders,
                includeParameters: [ParseParameter.Limit:limit, ParseParameter.Skip: skip, ParseParameter.Order: orderedBy])
            
            webClient.executeRequest(request) { jsonData, error in
                
                if let resultsArray = jsonData?.valueForKey(ParseJsonKey.Results) as? [[String:AnyObject]] {
                    completionHandler(resultsArray: resultsArray, error: nil)
                } else {
                    completionHandler(resultsArray: nil, error: ParseClient.errorForCode(.ResponseContainedNoResultObject))
                }
            }
    }
}

// MARK: - Constants

extension ParseClient {
    
    static let BaseUrl = "https://api.parse.com/1/"
    static let ObjectUrl = BaseUrl + "classes/"
    
    // use reverse-sort by Updated time as default
    static let DefaultSortOrder = "-\(ParseJsonKey.UpdatedAt)"
    
    struct ParseParameter {
        static let Limit = "limit"
        static let Skip = "skip"
        static let Order = "order"
    }

    struct ParseJsonKey {
        static let Results = "results"
        static let Count = "count"
        static let ObjectId = "objectId"
        static let CreateAt = "createdAt"
        static let UpdatedAt = "updatedAt"
    }
    
}

// MARK: - Errors {

extension ParseClient {
    
    private static let ErrorDomain = "ParseClient"
    
    private enum ErrorCode: Int, Printable {
        case ResponseContainedNoResultObject = 1
        
        var description: String {
            switch self {
            case ResponseContainedNoResultObject: return "Response data did not provide a results object."
            default: return "Unknown Error"
            }
        }
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    private static func errorForCode(code: ErrorCode) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : code.description]
        return NSError(domain: ParseClient.ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}