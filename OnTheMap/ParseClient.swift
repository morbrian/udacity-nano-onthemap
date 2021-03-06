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
    
    // Initialize with app specific keys and id
    // client: insteance of a WebClient
    // applicationId: valid ID provided to this App for use with the Parse service.
    // restApiKey: a developer API Key provided by registering with the Parse service.
    public init(client: WebClient, applicationId: String, restApiKey: String) {
        self.webClient = client
        self.applicationId = applicationId
        self.restApiKey = restApiKey
    }
    
    // Fetch a list of objects from the Parse service for the specified class type.
    // className: the object model classname of the data type on Parse
    // limit: maximum number of objects to fetch
    // skip: number of objects to skip before fetching the limit.
    // orderedBy: name of an attribute on the object model to sort results by.
    // whereClause: Parse formatted query where clause to constrain query results.
    public func fetchResultsForClassName(className: String, limit: Int = 50, skip: Int = 0, orderedBy: String = ParseJsonKey.UpdatedAt,
        whereClause: String? = nil,
        completionHandler: (resultsArray: [[String:AnyObject]]?, error: NSError?) -> Void) {
            
            var parameterList: [String:AnyObject] = [ParseParameter.Limit:limit, ParseParameter.Skip: skip, ParseParameter.Order: orderedBy]
            if let whereClause = whereClause {
                parameterList[ParseParameter.Where] = whereClause
            }
            
            if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: "\(ParseClient.ObjectUrl)/\(className)",
                includeHeaders: StandardHeaders,
                includeParameters: parameterList) {
            
                webClient.executeRequest(request) { jsonData, error in
                    if let resultsArray = jsonData?.valueForKey(ParseJsonKey.Results) as? [[String:AnyObject]] {
                        completionHandler(resultsArray: resultsArray, error: nil)
                    } else if let error = error {
                        completionHandler(resultsArray: nil, error: error)
                    } else if let errorMessage = jsonData?.valueForKey(ParseJsonKey.Error) as? String {
                        completionHandler(resultsArray: nil, error: ParseClient.errorForCode(.ParseServerError, message: errorMessage))
                    } else {
                        completionHandler(resultsArray: nil, error: ParseClient.errorForCode(.ResponseContainedNoResultObject))
                    }
                }
            } else {
                completionHandler(resultsArray: nil, error: WebClient.errorForCode(.UnableToCreateRequest))
            }
    }
    
    // Create an object of the specified class type.
    // PRE: properties MUST NOT already contain an objectId, createdAt, or updatedAt properties.
    // className: the object model classname of the data type on Parse
    // withProperties: key value pair attributes of the new object.
    // completionHandler - objectId: the ID of the newly create object
    // completionHandler - createdAt: the time of creation for newly created object.
    public func createObjectOfClassName(className: String, withProperties properties: [String:AnyObject],
        completionHandler: (objectId: String?, createdAt: String?, error: NSError?) -> Void) {
            
            performHttpMethod(WebClient.HttpPost, ofClassName: className, withProperties: properties) { jsonData, error in
                    if let objectId = jsonData?.valueForKey(ParseJsonKey.ObjectId) as? String,
                        createdAt = jsonData?.valueForKey(ParseJsonKey.CreateAt) as? String {
                            completionHandler(objectId: objectId, createdAt: createdAt, error: nil)
                    } else if let error = error {
                        completionHandler(objectId: nil, createdAt: nil, error: error)
                    } else if let errorMessage = jsonData?.valueForKey(ParseJsonKey.Error) as? String {
                        completionHandler(objectId: nil, createdAt: nil, error: ParseClient.errorForCode(.ParseServerError, message: errorMessage))
                    } else {
                        let responseError = ParseClient.errorForCode(.ResponseForCreateIsMissingExpectedValues)
                        completionHandler(objectId: nil, createdAt: nil, error: responseError)
                    }
            }
    }
    
    // Delete an object of the specified class type with the given objectId
    // className: the object model classname of the data type on Parse
    public func deleteObjectOfClassName(className: String, objectId: String? = nil, completionHandler: (error: NSError?) -> Void) {
        performHttpMethod(WebClient.HttpDelete, ofClassName: className, objectId: objectId) { jsonData, error in
                completionHandler(error: error)
        }
    }
    
    // Update an object of the specified class type and objectId with the new properties.
    // className: the object model classname of the data type on Parse
    // withProperties: key value pair attributes to update the object.
    // objectId: the unique id of the object to update.
    // completionHandler - updatedAt: the time object is updated when update successful
    public func updateObjectOfClassName(className: String, withProperties properties: [String:AnyObject], objectId: String? = nil,
        completionHandler: (updatedAt: String?, error: NSError?) -> Void) {
            print("Raw Data: \(properties)")
            performHttpMethod(WebClient.HttpPut, ofClassName: className, withProperties: properties, objectId: objectId) { jsonData, error in
                if let updatedAt = jsonData?.valueForKey(ParseJsonKey.UpdatedAt) as? String {
                    completionHandler(updatedAt: updatedAt, error: nil)
                } else if error != nil {
                    completionHandler(updatedAt: nil, error: error)
                } else {
                    let responseError = ParseClient.errorForCode(.ResponseForUpdateIsMissingExpectedValues)
                    completionHandler(updatedAt: nil, error: responseError)
                }
        }
    }
    
    // Perform an HTTP/HTTPS request with the specified configuration and content.
    // method: the HTTP method to use
    // ofClassName: the PARSE classname targeted by the request.
    // withProperties: the data properties
    // objectId: the objectId targeted by the request
    // requestHandler - jsonData: the parsed body content of the response
    private func performHttpMethod(method: String, ofClassName className: String, withProperties properties: [String:AnyObject] = [String:AnyObject](),
        objectId: String? = nil, requestHandler: (jsonData: AnyObject?, error: NSError?) -> Void ) {
        
        do {
            let body = try NSJSONSerialization.dataWithJSONObject(properties, options: NSJSONWritingOptions.PrettyPrinted)
            var targetUrlString = "\(ParseClient.ObjectUrl)/\(className)"
            if let objectId = objectId {
                targetUrlString += "/\(objectId)"
            }
            if let request = webClient.createHttpRequestUsingMethod(method, forUrlString: targetUrlString,
                withBody: body, includeHeaders: StandardHeaders) {
                    webClient.executeRequest(request, completionHandler: requestHandler)
            } else {
                requestHandler(jsonData: nil, error: WebClient.errorForCode(.UnableToCreateRequest))
            }
        } catch {
            requestHandler(jsonData: nil, error: ParseClient.errorForCode(ErrorCode.ParseServerError))
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
    
    
    struct DateFormat {
        static let ISO8601 = "yyyy-MM-dd'T'HH:mm:ss.SZZZZZ"
    }
    
    struct Locale {
        static let EN_US_POSIX = "en_US_POSIX"
    }
    
    static var DateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: ParseClient.Locale.EN_US_POSIX)
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = ParseClient.DateFormat.ISO8601
        return dateFormatter
    }
    
    struct ParseParameter {
        static let Limit = "limit"
        static let Skip = "skip"
        static let Order = "order"
        static let Where = "where"
    }

    struct ParseJsonKey {
        static let Results = "results"
        static let Error = "error"
        static let Count = "count"
        static let ObjectId = "objectId"
        static let CreateAt = "createdAt"
        static let UpdatedAt = "updatedAt"
    }
    
    struct Logic {
        static let LessThan = "lt"
        static let GreaterThan = "gt"
    }
}

// MARK: - Errors {

extension ParseClient {
    
    private static let ErrorDomain = "ParseClient"
    
    private enum ErrorCode: Int, CustomStringConvertible {
        case ResponseContainedNoResultObject = 1
        case ResponseForCreateIsMissingExpectedValues
        case ResponseForUpdateIsMissingExpectedValues
        case ParseServerError
        
        var description: String {
            switch self {
            case ResponseContainedNoResultObject: return "Server did not send any results."
            case ResponseForCreateIsMissingExpectedValues: return "Response for Creating Object did not return an error but did not contain expected properties either."
            case ResponseForUpdateIsMissingExpectedValues: return "Response for Updating Object did not return an error but did not contain expected properties either."
            default: return "Unknown Error"
            }
        }
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    private static func errorForCode(code: ErrorCode, var message: String? = nil) -> NSError {
        if message == nil {
            message = code.description
        }
        let userInfo = [NSLocalizedDescriptionKey : message!]
        return NSError(domain: ParseClient.ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}