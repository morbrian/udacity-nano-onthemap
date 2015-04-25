//
//  AuthenticationService.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// MARK: - Class WebClient

// WebClient
// Base Class for general interactions with any Web Service API that produces JSON data.
public class WebClient {
    
    // optional data maniupation function
    // if set will modify the data before handing it off to the parser.
    // Common Use Case: some web services include extraneous content 
    //                  before or after the desired JSON content in response data.
    public var prepareData: ((NSData) -> NSData?)?
    
    // createHttpGetRequestForUrlString
    // Creates fully configured NSURLRequest for making HTTP GET requests.
    // urlString: properly formatted URL string
    // includeHeaders: field-name / value pairs for request headers.
    public func createHttpGetRequestForUrlString(var urlString: String,
        includeHeaders requestHeaders: [String:String]? = nil,
        includeParameters requestParameters: [String:AnyObject]? = nil) -> NSURLRequest {

            if let requestParameters = requestParameters {
                urlString = "\(urlString)?\(encodeParameters(requestParameters))"
            }

            // TODO: this should do something smarter if the urlString is malformed
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            request.HTTPMethod = WebClient.HttpGet
            if let requestHeaders = requestHeaders {
                request = addRequestHeaders(requestHeaders, toRequest: request)
            }
            return request
    }
    
    // createHttpPostRequestForUrlString
    // Creates fuly configured NSURLRequest for making HTTP POST requests.
    // urlString: properly formatted URL string
    // withBody: body of the post request, not necessarily JSON or any particular format.
    // includeHeaders: field-name / value pairs for request headers.
    public func createHttpPostRequestForUrlString(var urlString: String, withBody body: NSData,
        includeHeaders requestHeaders: [String:String]? = nil,
        includeParameters requestParameters: [String:AnyObject]? = nil) -> NSURLRequest {
            
            if let requestParameters = requestParameters {
                urlString = "\(urlString)?\(encodeParameters(requestParameters))"
            }
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            request.HTTPMethod = WebClient.HttpPost
            if let requestHeaders = requestHeaders {
                request = addRequestHeaders(requestHeaders, toRequest: request)
            }
            request.HTTPBody = body
            return request
    }
    
    // executeRequest
    // Execute the request in a background thread, and call completionHandler when done.
    // Performs the work of checking for general errors and then
    // turning raw data into JSON data to feed to completionHandler.
    public func executeRequest(request: NSURLRequest, completionHandler: (jsonData: AnyObject?, error: NSError?) -> Void) {
                            
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            // this is a general communication error
            if error != nil {
                Logger.debug(error.description)
                completionHandler(jsonData: nil, error: error)
                return
            }

            let (jsonData: AnyObject?, parsingError: NSError?) =
                self.parseJsonFromData(data)
            
            if let parsingError = parsingError {
                Logger.debug(parsingError.description)
                completionHandler(jsonData: nil, error: parsingError)
                return
            }
            
            completionHandler(jsonData: jsonData, error: nil)
        }
        task.resume()
    }
    
    // MARK: Private Helpers
    
    // Produces usable JSON object from the raw data.
    private func parseJsonFromData(data: NSData) -> (jsonData: AnyObject?, error: NSError?) {
        var mutableData = data
        var parsingError: NSError? = nil
        if let prepareData = prepareData,
            modifiedData = prepareData(data) {
                mutableData = modifiedData
        }
        let jsonData: AnyObject? = NSJSONSerialization.JSONObjectWithData(mutableData, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        return (jsonData, parsingError)
    }
    
    // helper function adds request headers to request
    private func addRequestHeaders(requestHeaders: [String:String], toRequest request: NSMutableURLRequest) -> NSMutableURLRequest {
        var request = request
        for (field, value) in requestHeaders {
            request.addValue(value, forHTTPHeaderField: field)
        }
        return request
    }
    
    // encodeParameters
    // convert dictionary to parameterized String appropriate for use in an HTTP URL
    private func encodeParameters(params: [String: AnyObject]) -> String {
        var queryItems = map(params) { NSURLQueryItem(name:$0, value:"\($1)")}
        var components = NSURLComponents()
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
}

// MARK: - Constants

extension WebClient {
    
    static let JsonContentType = "application/json"
    static let HttpHeaderAccept = "Accept"
    static let HttpHeaderContentType = "Content-Type"
    static let HttpPost = "POST"
    static let HttpGet = "GET"

}

