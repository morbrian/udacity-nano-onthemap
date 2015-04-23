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
    
    // createHttpGetRequestForUrlString
    // Creates fully configured NSURLRequest for making HTTP GET requests.
    // urlString: properly formatted URL string
    // includeHeaders: field-name / value pairs for request headers.
    public func createHttpGetRequestForUrlString(urlString: String, includeHeaders requestHeaders: [String:String]? = nil) -> NSURLRequest {
        // TODO: this should do something smarter if the urlString is malformed
        var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.HTTPMethod = WebClientConstant.HttpGet
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
    public func createHttpPostRequestForUrlString(urlString: String, withBody body: NSData, includeHeaders requestHeaders: [String:String]?) -> NSURLRequest {
        var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.HTTPMethod = WebClientConstant.HttpPost
        if let requestHeaders = requestHeaders {
            request = addRequestHeaders(requestHeaders, toRequest: request)
        }
        request.HTTPBody = body
        return request
    }
    
    // parseJsonFromData
    // Produces usable JSON object from the raw data.
    func parseJsonFromData(data: NSData) -> (jsonData: AnyObject?, error: NSError?) {
        var parsingError: NSError? = nil
        let jsonData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        return (jsonData, parsingError)
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    func createErrorWithCode(code: Int, message: String, domain: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
    
    // executeRequest
    // Execute the request in a background thread, and call completionHandler when done.
    // Performs the work of checking for general errors and then
    // turning raw data into JSON data to feed to completionHandler.
    func executeRequest(request: NSURLRequest, completionHandler: (jsonData: AnyObject?, error: NSError?) -> Void) {
                            
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
    
    // helper function adds request headers to request
    private func addRequestHeaders(requestHeaders: [String:String], toRequest request: NSMutableURLRequest) -> NSMutableURLRequest {
        var request = request
        for (field, value) in requestHeaders {
            request.addValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}

// MARK: - Constants

extension WebClient {
    struct WebClientConstant {
        static let JsonContentType = "application/json"
        static let HttpHeaderAccept = "Accept"
        static let HttpHeaderContentType = "Content-Type"
        static let HttpPost = "POST"
        static let HttpGet = "GET"
    }
}
