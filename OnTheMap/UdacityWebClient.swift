//
//  UdacityWebService.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/19/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class UdacityWebClient: WebClient {
    
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
        static var SessionMethod: String {
            return BaseUrl + SessionApi
        }
        static var UsersMethod: String {
            return BaseUrl + UsersApi
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

    private func UdacitySessionBody(#username: String, password: String) -> NSData {
        return "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
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
    
    private func validateUdacityLengthRequirement(jsonData: NSData!) -> NSError? {
        if jsonData.length <= 5 {
            let dataError = self.createErrorWithCode(UdacityError.InsufficientDataLengthCode,
                message: UdacityError.InsufficientDataLengthMessage, domain: UdacityError.Domain)
            return dataError
        } else {
            return nil
        }
    }
    
    func authenticateByUsername(username: String, withPassword password: String,
        completionHandler: (userIdentity: UserIdentity?, error: NSError?) -> Void) {
            
        let request = createHttpPostRequestForUrlString(UdacityWebService.SessionMethod, withBody: UdacitySessionBody(username: username, password: password))
        
        executeRequest(request, dataValidator: validateUdacityLengthRequirement)
        { jsonData, error in
            if let account = jsonData?.valueForKey(UdacityJsonKey.Account) as? NSDictionary,
                key = account[UdacityJsonKey.Key] as? String {
                    completionHandler(userIdentity: UserIdentity(key), error: nil)
            } else {
                completionHandler(userIdentity: nil, error: self.produceErrorFromResponseData(jsonData))
            }
        }
    }
    
    func fetchUserDataForUserIdentity(userIdentity: UserIdentity,
        completionHandler: (userData: UserData?, error: NSError?) -> Void) {
            
        let request = createHttpGetRequestForUrlString("\(UdacityWebService.UsersMethod)/\(userIdentity)")
        
        executeRequest(request,dataValidator: validateUdacityLengthRequirement)
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

}