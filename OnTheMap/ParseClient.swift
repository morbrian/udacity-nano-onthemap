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
        whereClause: String? = nil,
        completionHandler: (resultsArray: [[String:AnyObject]]?, error: NSError?) -> Void) {
            
            var parameterList: [String:AnyObject] = [ParseParameter.Limit:limit, ParseParameter.Skip: skip, ParseParameter.Order: orderedBy]
            if let whereClause = whereClause {
                parameterList[ParseParameter.Where] = whereClause
            }
            let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: "\(ParseClient.ObjectUrl)/\(className)",
                includeHeaders: StandardHeaders,
                includeParameters: parameterList)
            
            webClient.executeRequest(request) { jsonData, error in
                
                if let resultsArray = jsonData?.valueForKey(ParseJsonKey.Results) as? [[String:AnyObject]] {
                    completionHandler(resultsArray: resultsArray, error: nil)
                } else {
                    completionHandler(resultsArray: nil, error: ParseClient.errorForCode(.ResponseContainedNoResultObject))
                }
            }
    }
    
    // className: the object model classname of the data type on Parse
    public func createObjectOfClassName(className: String, withProperties properties: [String:AnyObject],
        completionHandler: (objectId: String?, createdAt: String?, error: NSError?) -> Void) {
            
            var bodyError = performHttpMethod(WebClient.HttpPost, ofClassName: className, withProperties: properties)
                { jsonData, error in
                    if let objectId = jsonData?.valueForKey(ParseJsonKey.ObjectId) as? String,
                        createdAt = jsonData?.valueForKey(ParseJsonKey.CreateAt) as? String {
                            completionHandler(objectId: objectId, createdAt: createdAt, error: nil)
                    } else if error != nil {
                        completionHandler(objectId: nil, createdAt: nil, error: error)
                    } else {
                        var responseError = ParseClient.errorForCode(.ResponseForCreateIsMissingExpectedValues)
                        completionHandler(objectId: nil, createdAt: nil, error: responseError)
                    }
            }
            
            if let bodyError = bodyError {
                // there was an error preparing the request
                completionHandler(objectId: nil, createdAt: nil, error: bodyError)
            }
    }
    
    // className: the object model classname of the data type on Parse
    public func deleteObjectOfClassName(className: String, withProperties properties: [String:AnyObject], objectId: String? = nil,
        completionHandler: (something: String?, error: NSError?) -> Void) {
            
            var bodyError = performHttpMethod(WebClient.HttpDelete, ofClassName: className, withProperties: properties, objectId: objectId)
                { jsonData, error in
                    Logger.info("Received back: \(jsonData) or \(error)")
//                    if let objectId = jsonData?.valueForKey(ParseJsonKey.ObjectId) as? String,
//                        createdAt = jsonData?.valueForKey(ParseJsonKey.CreateAt) as? String {
//                            completionHandler(something: nil, error: nil)
//                    } else if error != nil {
//                        completionHandler(something: nil, error: error)
//                    } else {
//                        var responseError = ParseClient.errorForCode(.ResponseForCreateIsMissingExpectedValues)
//                        completionHandler(something: nil, error: responseError)
//                    }
            }
            
            if let bodyError = bodyError {
                // there was an error preparing the request
                completionHandler(something: nil, error: bodyError)
            }
    }
    
    public func updateObjectOfClassName(className: String, withProperties properties: [String:AnyObject], objectId: String? = nil,
        completionHandler: (updatedAt: String?, error: NSError?) -> Void) {
            println("Raw Data: \(properties)")
            var bodyError = performHttpMethod(WebClient.HttpPut, ofClassName: className, withProperties: properties, objectId: objectId)
            { jsonData, error in
                if let updatedAt = jsonData?.valueForKey(ParseJsonKey.UpdatedAt) as? String {
                    completionHandler(updatedAt: updatedAt, error: nil)
                } else if error != nil {
                    completionHandler(updatedAt: nil, error: error)
                } else {
                    var responseError = ParseClient.errorForCode(.ResponseForUpdateIsMissingExpectedValues)
                    completionHandler(updatedAt: nil, error: responseError)
                }
        }
        
        if let bodyError = bodyError {
            // there was an error preparing the request
            completionHandler(updatedAt: nil, error: bodyError)
        }
    }
    
    // return true if the requests gets prepared and handed off to client thread
    private func performHttpMethod(method: String, ofClassName className: String, withProperties properties: [String:AnyObject], objectId: String? = nil,
                requestHandler: (jsonData: AnyObject?, error: NSError?) -> Void ) -> NSError? {
        var bodyError: NSError?
        if let body = NSJSONSerialization.dataWithJSONObject(properties, options: nil, error: &bodyError)
            where bodyError == nil {
                Logger.debug("have a body and objectId \(objectId)")
                var targetUrlString = "\(ParseClient.ObjectUrl)/\(className)"
                if let objectId = objectId {
                    targetUrlString += "/\(objectId)"
                }
                Logger.info("Sending \(method) to \(targetUrlString)")
                let request = webClient.createHttpRequestUsingMethod(method, forUrlString: targetUrlString,
                    withBody: body,
                    includeHeaders: StandardHeaders)
                
                webClient.executeRequest(request, completionHandler: requestHandler)
                return nil
        } else {
            Logger.debug("we have no body")
            return bodyError
        }
    }

}

// MARK: - Constants

extension ParseClient {
    
    static let BaseUrl = "https://api.parse.com"
    static let BasePath = "/1/classes"
    static let ObjectUrl = BaseUrl + BasePath
    
    // use reverse-sort by Updated time as default
    static let DefaultSortOrder = "-\(ParseJsonKey.UpdatedAt)"
    
    struct ParseParameter {
        static let Limit = "limit"
        static let Skip = "skip"
        static let Order = "order"
        static let Where = "where"
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
        case ResponseForCreateIsMissingExpectedValues
        case ResponseForUpdateIsMissingExpectedValues
        
        var description: String {
            switch self {
            case ResponseContainedNoResultObject: return "Response data did not provide a results object."
            case ResponseForCreateIsMissingExpectedValues: return "Response for Creating Object did not return an error but did not contain expected properties either."
            case ResponseForUpdateIsMissingExpectedValues: return "Response for Updating Object did not return an error but did not contain expected properties either."
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