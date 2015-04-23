//
//  UdacityWebService.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// MARK: Class UdacityWebClient

// UdacityWebClient
// Provids a simple interface for interacting with the Udacity web service.
class UdacityWebClient: WebClient {

    // authenticate with Udacity using a username and password.
    // the user's basic identity (userid) is returned as a UserIdentity in the completionHandler.
    func authenticateByUsername(username: String, withPassword password: String,
        completionHandler: (userIdentity: UserIdentity?, error: NSError?) -> Void) {
            
        let request = createHttpPostRequestForUrlString(UdacityWebService.SessionUrlString,
            withBody: buildUdacitySessionBody(username: username, password: password),
            includeHeaders: UdacityWebService.StandardHeaders)
        
        executeRequest(request)
        { jsonData, error in
            if let account = jsonData?.valueForKey(UdacityJsonKey.Account) as? NSDictionary,
                key = account[UdacityJsonKey.Key] as? String {
                    completionHandler(userIdentity: UserIdentity(key), error: nil)
            } else {
                completionHandler(userIdentity: nil, error: self.produceErrorFromResponseData(jsonData))
            }
        }
    }
    
    // fetch available data for the user identified by userIdentity.
    // For the logged in user, the service returns most of the available data on the user.
    // For any non-logged in user, this will return just the public data for the specified user.
    func fetchUserDataForUserIdentity(userIdentity: UserIdentity,
        completionHandler: (userData: UserData?, error: NSError?) -> Void) {
            
        let request = createHttpGetRequestForUrlString("\(UdacityWebService.UsersUrlString)/\(userIdentity)")
        
        executeRequest(request)
        { jsonData, error in
            if let userObject = jsonData?.valueForKey(UdacityJsonKey.User) as? NSDictionary {
                let key = userObject.valueForKey(UdacityJsonKey.Key) as? String
                let nickname = userObject.valueForKey(UdacityJsonKey.Nickname) as? String
                let firstname = userObject.valueForKey(UdacityJsonKey.Firstname) as? String
                let lastname = userObject.valueForKey(UdacityJsonKey.Lastname) as? String
                
                let userData = UserData(userIdentity: userIdentity, nickname: nickname,
                    firstname: firstname, lastname: lastname, imageUrl: nil)
                
                completionHandler(userData: userData, error: nil)
            } else {
                completionHandler(userData: nil, error: self.produceErrorFromResponseData(jsonData))
            }
        }
    }
    
    // MARK: Overrides
    
    // parseJsonFromData
    // Override in order to verify response length and to trim extraneous characters in the response,
    // specific to the Udacity Web Service.
    override func parseJsonFromData(data: NSData) -> (jsonData: AnyObject?, error: NSError?) {
        if let lengthError = validateUdacityLengthRequirement(data) {
            return (nil, lengthError)
        }
        return super.parseJsonFromData(data.subdataWithRange(NSMakeRange(5, data.length - 5)))
    }
    
    // MARK: Private Helpers
    
    // build the Session request body with username and password values.
    private func buildUdacitySessionBody(#username: String, password: String) -> NSData {
        return "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    // used when the json body is suspected to contain an error descrptor,
    // pulls out the error message based on the Udacity error format.
    private func produceErrorFromResponseData(jsonData: AnyObject?) -> NSError {
        var errorObject: NSError!
        
        if let errorMessage = jsonData?.valueForKey("error") as? String,
            errorCode = jsonData?.valueForKey("status") as? Int {
                errorObject = createErrorWithCode(errorCode, message: errorMessage, domain: UdacityError.Domain)
        } else {
            errorObject = createErrorWithCode(UdacityError.UnexpectedResponseDataCode,
                message: UdacityError.UnexpectedResponseDataMessage, domain: UdacityError.Domain)
        }
        
        return errorObject
    }
    
    // verify response data is sufficiently long enough to sub set the extraneous characters safely,
    // otherwise return an explanatory error message for why the request will appear to have failed.
    private func validateUdacityLengthRequirement(jsonData: NSData!) -> NSError? {
        if jsonData.length <= UdacityWebService.UdacityResponsePadding {
            let dataError = self.createErrorWithCode(UdacityError.InsufficientDataLengthCode,
                message: UdacityError.InsufficientDataLengthMessage, domain: UdacityError.Domain)
            return dataError
        } else {
            return nil
        }
    }

}

// MARK: - Constants

extension UdacityWebClient {
    
    struct UdacityError {
        static let Domain = "UdacityWebClient"
        static let UnexpectedResponseDataCode = 1
        static let UnexpectedResponseDataMessage = "Unexpected Response Data"
        static let InsufficientDataLengthCode = 2
        static let InsufficientDataLengthMessage = "Insufficient Data Length In Response"
    }
    
    struct UdacityWebService {
        static let BaseUrl = "https://www.udacity.com/api"
        static let SessionApi = "/session"
        static let UsersApi = "/users"
        static let UdacityResponsePadding = 5
        static var SessionUrlString: String {
            return BaseUrl + SessionApi
        }
        static var UsersUrlString: String {
            return BaseUrl + UsersApi
        }
        static var StandardHeaders: [String:String] {
            return [
                WebClientConstant.HttpHeaderAccept:WebClientConstant.JsonContentType,
                WebClientConstant.HttpHeaderContentType:WebClientConstant.JsonContentType
            ]
        }
    }
    
    struct UdacityJsonKey {
        static let Account = "account"
        static let User = "user"
        static let Key = "key"
        static let Nickname = "nickname"
        static let Firstname = "first_name"
        static let Lastname = "last_name"
    }

}