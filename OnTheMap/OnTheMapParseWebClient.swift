//
//  OnTheMapParseWebClient.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/22/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class OnTheMapParseWebClient: WebClient {
    func fetchStudentLocations(completionHandler: (data: NSData?, error: NSError?) -> Void) {
            
        let request = createHttpGetRequestForUrlString(OnTheMapParseWebService.StudentLocationUrl, includeHeaders: OnTheMapParseWebService.StandardHeaders)
        
            executeRequest(request)
                { jsonData, error in
                    if let error = error {
                        println("Uh oh, error...")
                    } else {
                        println(jsonData)
                    }
//                    if let userObject = jsonData?.valueForKey(UdacityJsonKey.User) as? NSDictionary {
//                        let key = userObject.valueForKey(UdacityJsonKey.Key) as? String
//                        let nickname = userObject.valueForKey(UdacityJsonKey.Nickname) as? String
//                        let firstname = userObject.valueForKey(UdacityJsonKey.Firstname) as? String
//                        let lastname = userObject.valueForKey(UdacityJsonKey.Lastname) as? String
//                        
//                        let userData = UserData(userIdentity: userIdentity, nickname: nickname,
//                            firstname: firstname, lastname: lastname, imageUrl: nil)
//                        
//                        completionHandler(userData: userData, error: nil)
//                    } else {
//                        completionHandler(userData: nil, error: self.produceErrorFromResponseData(jsonData))
//                    }
            }
    }
    
}

extension OnTheMapParseWebClient {
    
    struct OnTheMapParseError {
        static let Domain = "OnTheMapParseWebClient"
        static let SomeResponseDataCode = 1
        static let SomeResponseDataMessage = "some message"
    }
    
    struct OnTheMapParseWebService {
        
        static let BaseUrl = "https://api.parse.com/1/classes"
        static let StudentLocationApi = "/StudentLocation"
        static var StudentLocationUrl: String {
            return BaseUrl + StudentLocationApi
        }
        static var StandardHeaders: [String:String] {
            return [
                "X-Parse-Application-Id":"QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr",
                "X-Parse-REST-API-Key":"QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
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