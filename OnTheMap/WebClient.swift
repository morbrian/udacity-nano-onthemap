//
//  AuthenticationService.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class WebClient {
    
    let JsonContentType = "application/json"
    let HttpHeaderAccept = "Accept"
    let HttpHeaderContentType = "Content-Type"
    let HttpPost = "POST"
    let HttpGet = "GET"
 
    func createHttpGetRequestForUrlString(urlString: String) -> NSURLRequest {
        return NSURLRequest(URL: NSURL(string: urlString)!)
    }
    
    func createHttpPostRequestForUrlString(urlString: String, withBody body: NSData) -> NSURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.HTTPMethod = HttpPost
        request.addValue(JsonContentType, forHTTPHeaderField: HttpHeaderAccept)
        request.addValue(JsonContentType, forHTTPHeaderField: HttpHeaderContentType)
        request.HTTPBody = body
        return request
    }
    
    func parseJsonFromData(data: NSData) -> (jsonData: AnyObject?, error: NSError?) {
        var parsingError: NSError? = nil
        let jsonData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        return (jsonData, parsingError)
    }
    
    func createErrorWithCode(code: Int, message: String, domain: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
    
    func executeRequest(request: NSURLRequest,
        dataValidator: ((jsonData: NSData!) -> NSError?)?,
        completionHandler: (jsonData: AnyObject?, error: NSError?) -> Void) {
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request) { data, response, error in
                // this is a general communication error
                if error != nil {
                    completionHandler(jsonData: nil, error: error)
                    return
                }
                
                if let dataValidator = dataValidator,
                    dataError = dataValidator(jsonData: data) {
                    completionHandler(jsonData: nil, error: dataError)
                    return
                }

                let (jsonData: AnyObject?, parsingError: NSError?) = self.parseJsonFromData(data.subdataWithRange(NSMakeRange(5, data.length - 5)))
                
                if let parsingError = parsingError {
                    completionHandler(jsonData: nil, error: parsingError)
                    return
                }
                
                completionHandler(jsonData: jsonData, error: nil)
            }
            task.resume()
    }

}
