//
//  ParseClient.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/24/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

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
    
    public init(client: WebClient, applicationId: String, restApiKey: String) {
        self.webClient = client
        self.applicationId = applicationId
        self.restApiKey = restApiKey
    }
    
    public func fetchResultsForClassName(className: String, limit: Int = 50, skip: Int = 0,
        completionHandler: (resultsArray: [[String:AnyObject]]?, error: NSError?) -> Void) {
            let request = webClient.createHttpGetRequestForUrlString("\(ParseClient.ObjectUrl)/\(className)",
                includeHeaders: StandardHeaders,
                includeParameters: [ParseParameter.Limit:limit, ParseParameter.Skip: skip])
            
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
    
    struct ParseParameter {
        static let Limit = "limit"
        static let Skip = "skip"
    }

    struct ParseJsonKey {
        static let Results = "results"
        static let Count = "count"
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