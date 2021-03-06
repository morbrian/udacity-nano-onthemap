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
class UdacityService {

    private var webClient: WebClient!
    
    init() {
        webClient = WebClient()
        webClient.prepareData = prepareDataForParsing
    }
    
    // authenticate with Udacity using a username and password.
    // the user's basic identity (userid) is returned as a UserIdentity in the completionHandler.
    // username: udacity username
    // withPassword: udacity password
    // completionHandler - userIdentity: the udacity user key uniquely identifying this user if login successful
    func authenticateByUsername(username: String, withPassword password: String,
        completionHandler: (userIdentity: StudentIdentity?, error: NSError?) -> Void) {
            // first check the basic requirements
            if username.isEmpty {
                completionHandler(userIdentity: nil, error: UdacityService.errorForCode(.UsernameRequired))
                return
            }
            if password.isEmpty {
                completionHandler(userIdentity: nil, error: UdacityService.errorForCode(.PasswordRequired))
                return
            }
            
            let httpBody =  buildUdacitySessionBody(username: username, password: password)
            authenticateUsingHttpBody(httpBody, completionHandler: completionHandler)
    }
    
    // authenticate with Udacity using a username and password.
    // the user's basic identity (userid) is returned as a UserIdentity in the completionHandler.
    // token: facebook token from facebook authentication
    // completionHandler - userIdentity: the udacity user key uniquely identifying this user if login successful
    func authenticateByFacebookToken(token: String,
        completionHandler: (userIdentity: StudentIdentity?, error: NSError?) -> Void) {
            // first check the basic requirements
            if token.isEmpty {
                completionHandler(userIdentity: nil, error: UdacityService.errorForCode(.MissingFacebookToken))
                return
            }
            let httpBody = buildUdacitySessionBody(facebookToken: token)
            authenticateUsingHttpBody(httpBody, completionHandler: completionHandler)
    }
    
    // authenticate with udacity using prepared body content containing authentication credentials
    private func authenticateUsingHttpBody(httpBody: NSData,
        completionHandler: (userIdentity: StudentIdentity?, error: NSError?) -> Void) {
            if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpPost, forUrlString: UdacityService.SessionUrlString,
                withBody: httpBody, includeHeaders: UdacityService.StandardHeaders) {
            
                webClient.executeRequest(request)
                    { jsonData, error in
                        if let account = jsonData?.valueForKey(UdacityJsonKey.Account) as? NSDictionary,
                            key = account[UdacityJsonKey.Key] as? String {
                                completionHandler(userIdentity: StudentIdentity(key), error: nil)
                        } else if let error = error {
                            completionHandler(userIdentity: nil, error: error)
                        } else {
                            completionHandler(userIdentity: nil, error: self.produceErrorFromResponseData(jsonData))
                        }
                }
            } else {
                completionHandler(userIdentity: nil, error: WebClient.errorForCode(.UnableToCreateRequest))
            }
    }
    
    // fetch available data for the user identified by userIdentity.
    // For the logged in user, the service returns most of the available data on the user.
    // For any non-logged in user, this will return only the public data for the specified user.
    func fetchInformationForStudentIdentity(studentIdentity: StudentIdentity,
        completionHandler: (studentInformation: StudentInformation?, error: NSError?) -> Void) {
            
        if let request = webClient.createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: "\(UdacityService.UsersUrlString)/\(studentIdentity)") {
        
            webClient.executeRequest(request)
            { jsonData, error in
                if let userObject = jsonData?.valueForKey(UdacityJsonKey.User) as? [String:AnyObject] {
                    completionHandler(studentInformation: translateToStudentInformationFromUdacityData(userObject), error: nil)
                } else {
                    completionHandler(studentInformation: nil, error: self.produceErrorFromResponseData(jsonData))
                }
            }
        } else {
            completionHandler(studentInformation: nil, error: WebClient.errorForCode(.UnableToCreateRequest))
        }
    }
    
    // MARK: Private Helpers
    
    // Verify response length and to trim extraneous characters in the response,
    // specific to the Udacity Web Service.
    private func prepareDataForParsing(data: NSData) -> NSData? {
        if validateUdacityLengthRequirement(data) != nil {
            Logger.error("Data length is to short to be parsed.")
            return nil
        }
        return data.subdataWithRange(NSMakeRange(5, data.length - 5))
    }
    
    // build the Session request body with username and password values.
    private func buildUdacitySessionBody(username username: String, password: String) -> NSData {
        return "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    // build the Session request body with username and password values.
    private func buildUdacitySessionBody(facebookToken facebookToken: String) -> NSData {
        return "{\"facebook_mobile\": {\"access_token\": \"\(facebookToken)\"}}".dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    // used when the json body is suspected to contain an error descrptor,
    // pulls out the error message based on the Udacity error format.
    private func produceErrorFromResponseData(jsonData: AnyObject?) -> NSError {
        if let errorMessage = jsonData?.valueForKey("error") as? String,
            errorCode = jsonData?.valueForKey("status") as? Int {
                return UdacityService.errorWithMessage(errorMessage, code: errorCode)
        } else {
            return UdacityService.errorForCode(.UnexpectedResponseData)
        }
    }
    
    // verify response data is sufficiently long enough to sub set the extraneous characters safely,
    // otherwise return an explanatory error message for why the request will appear to have failed.
    private func validateUdacityLengthRequirement(jsonData: NSData!) -> NSError? {
        if jsonData.length <= UdacityService.UdacityResponsePadding {
            return UdacityService.errorForCode(.InsufficientDataLength)
        } else {
            return nil
        }
    }

}

// MARK: - Constants

extension UdacityService {
    
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
            WebClient.HttpHeaderAccept:WebClient.JsonContentType,
            WebClient.HttpHeaderContentType:WebClient.JsonContentType
        ]
    }

    struct UdacityJsonKey {
        static let Account = "account"
        static let User = "user"
        static let Key = "key"
        static let Nickname = "nickname"
        static let Firstname = "first_name"
        static let Lastname = "last_name"
        static let Email = "email"
        static let Address = "address"
    }

}

// MARK: - Errors {

extension UdacityService {
    
    private static let ErrorDomain = "UdacityWebClient"
    
    private enum ErrorCode: Int, CustomStringConvertible {
        case UnexpectedResponseData, InsufficientDataLength, UsernameRequired, PasswordRequired, MissingFacebookToken

        
        var description: String {
            switch self {
            case UnexpectedResponseData: return "Unexpected Response Data"
            case InsufficientDataLength: return "Insufficient Data Length In Response"
            case UsernameRequired: return "Must specify a username"
            case PasswordRequired: return "Must specify a password"
            case MissingFacebookToken: return "Facebook Has Not Authenticated User"
            }
        }
    }
    
    // createErrorWithCode
    // helper function to simplify creation of error object
    private static func errorForCode(code: ErrorCode) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : code.description]
        return NSError(domain: UdacityService.ErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    private static func errorWithMessage(message: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : message]
        return NSError(domain: UdacityService.ErrorDomain, code: code, userInfo: userInfo)
    }
}