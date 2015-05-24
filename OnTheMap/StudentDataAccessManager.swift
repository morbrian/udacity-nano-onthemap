//
//  StudentInformationDataAccessManager.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// StudentDataAccessManager
// Primary data model manager for the OnTheMap application.
// Provides basic authentication helper methods, data fetching methods,
// and query pagination and local data caching for the app.
class StudentDataAccessManager {
    
    // how many items we request at a time
    // this can be modified by users of the class
    var fetchLimit = 100
    
    // udacity service operations
    private var udacityClient: UdacityService!
    
    // application specific operations for OnTheMap Parse Service
    private var onTheMapClient: OnTheMapParseService!
    
    private var currentUser: StudentInformation?
    
    private var authType: AuthenticationType = .NotAuthenticated
    
    // read only access to the logged in user data reference
    var loggedInUser: StudentInformation? { return currentUser }
    
    var infoPool = InfoPool<StudentInformation>()
    
    func userFilter(infoItem: StudentInformation) -> Bool {
        var result = infoItem.studentKey == currentUser?.studentKey
        return result
    }
    
    init() {
        udacityClient = UdacityService()
        onTheMapClient = OnTheMapParseService()
    }
    
    // MARK: Authentication Methods
    
    // return true if the user has authenticated
    var authenticated: Bool {
        return currentUser != nil
    }
    
    var authenticationTypeUsed: AuthenticationType {
        return authType
    }
    
    // authenticate the user by username and password with the Udacity service.
    func authenticateByUsername(username: String, withPassword password: String,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
            udacityClient.authenticateByUsername(username, withPassword: password) {
                userIdentity, error in
                self.handleLoginResponse(userIdentity, authType: .UdacityUsernameAndPassword,
                    error: error, completionHandler: completionHandler)
            }
    }
    
    // authenticate with Udacity using the token provided by facebook login
    func authenticateByFacebookToken(token: String,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
            udacityClient.authenticateByFacebookToken(token) {
                userIdentity, error in
                self.handleLoginResponse(userIdentity, authType: .FacebookToken,
                    error: error, completionHandler: completionHandler)
            }
    }
    
    private func handleLoginResponse(userIdentity: StudentIdentity?, authType: AuthenticationType, error: NSError?,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
        if let userIdentity = userIdentity {
            self.udacityClient.fetchInformationForStudentIdentity(userIdentity) {
                userData, error in
                self.currentUser = userData
                self.authType = authType
                completionHandler(success: true, error: nil)
            }
        } else {
            completionHandler(success: false, error: error)
        }
    }
    
    // MARK: Access Data Owned by Logged In User
    
    var userLocationCount: Int {
        return infoPool.count(filter: userFilter)
    }
    
    // return the student location for the specified index
    func userLocationAtIndex(index: Int) -> StudentInformation? {
        return infoPool.infoAtIndex(index, filter: userFilter)
    }
    
    // return the entire list of student locations
    var userLocations: [StudentInformation] {
        return infoPool.infoItemsAsArray(filter: userFilter)
    }
    
    // if the location data currently associated with the current user
    // is deleted, we must reset those attributes.
    func clearUserLocationWithId(objectId: String) {
        if currentUser?.objectId == objectId {
            currentUser?.objectId = nil
            currentUser?.latitude = nil
            currentUser?.longitude = nil
            currentUser?.mapString = nil
            currentUser?.mediaUrl = nil
            currentUser?.createdAt = nil
            currentUser?.updatedAt = nil
        }
    }
    
    func loggedInUserDoesHaveLocation() -> Bool {
        if let identity = currentUser?.studentKey {
            return infoPool.infoExistsForGroup(identity)
        } else {
            return false
        }
    }
    
    // MARK: Access Data from All Students
    
    // number of items downloaded so far
    var studentLocationCount: Int {
        return infoPool.count()
    }
    
    // return the student location for the specified index
    func studentLocationAtIndex(index: Int) -> StudentInformation? {
        return infoPool.infoAtIndex(index)
    }
    
    // return the entire list of student locations
    var studentLocations: [StudentInformation] {
        return infoPool.infoItemsAsArray()
    }
    
    // MARK: Fetch and Manage Student Data
    
    // store student information item in the info pool and create or update the same change on server
    func storeStudentInformation(studentInformation: StudentInformation, completionHandler: (success: Bool, error: NSError?) -> Void) {
        func handleStorage(studentInformation: StudentInformation?, error: NSError?) {
            if let studentInformation = studentInformation {
                // this isn't always a super cheap operation, but we put it on the main thread to
                // make sure the UI isn't asking for indices while we're manipulating the data structure
                dispatch_async(dispatch_get_main_queue()) {
                    self.infoPool.storeInfoItem(studentInformation)
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        // back on background thread just in case the handler passed in is expensive
                        completionHandler(success: true, error: nil)
                    }
                }
            } else if error != nil {
                Logger.error(error!.description)
                completionHandler(success: false, error: error)
            } else {
                Logger.error("Failed to store student information, but error not handled properly.")
                completionHandler(success: false, error: nil)
            }
        }
        
        if infoPool.infoExistsForGroup(studentInformation.studentKey) {
           onTheMapClient.updateStudentInformation(studentInformation, completionHandler: handleStorage)
        } else {
           onTheMapClient.createStudentInformation(studentInformation, completionHandler: handleStorage)
        }
    }
    
    func deleteStudentInformation(studentInformation: StudentInformation, completionHandler: (success: Bool, error: NSError?) -> Void) {
        func handleStorage(studentInformation: StudentInformation?, error: NSError?) {
            if let studentInformation = studentInformation {
                // this isn't always a super cheap operation, but we put it on the main thread to
                // make sure the UI isn't asking for indices while we're manipulating the data structure
                dispatch_async(dispatch_get_main_queue()) {
                    // TODO: this handleStorage function is duplicated except for the actual stoarge operation
                    self.infoPool.deleteInfoItem(studentInformation)
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        // back on background thread just in case the handler passed in is expensive
                        completionHandler(success: true, error: nil)
                    }
                }
            } else if error != nil {
                Logger.error(error!.description)
                completionHandler(success: false, error: error)
            } else {
                Logger.error("Failed to store student information, but error not handled properly.")
                completionHandler(success: false, error: nil)
            }
        }
        onTheMapClient.deleteStudentInformation(studentInformation, completionHandler: handleStorage)
    }
    
    // fetch the requested range of data from the OnTheMap Parse Web Service
    func fetchNextStudentInformationSubset(completionHandler: (success: Bool, error: NSError?) -> Void) {
        var newestDate: NSTimeInterval? {
            return infoPool.count() > 0 ? infoPool.infoAtIndex(0)?.updatedAt : nil
        }
        var oldestDate: NSTimeInterval? {
            return infoPool.count() > 1 ? infoPool.lastInfoItem()?.updatedAt : nil
        }
        
        onTheMapClient.fetchStudents(limit: fetchLimit, newerThan: newestDate, olderThan: oldestDate) {
            students, error in
            if let newLocations = students {
                dispatch_async(dispatch_get_main_queue()) {
                    // manipulate the data store on the main thread
                    self.infoPool.storeInfoItems(newLocations)
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        // but we don't know how expensive the completion handler is, so put it on off the main thread
                        Logger.info("found \(newLocations.count) items")
                        completionHandler(success: true, error: nil)
                    }
                }
            } else {
                completionHandler(success: false, error: error)
            }
        }
    }
    
    func fetchDataForCurrentUser(completionHandler: (success: Bool, error: NSError?) -> Void) {
        if let studentKey = currentUser?.studentKey {
            Logger.debug("Will fetch student info for student: \(studentKey)")
            onTheMapClient.fetchStudentInformationForKey(studentKey) {
                students, error in
                if let newLocations = students {
                    dispatch_async(dispatch_get_main_queue()) {
                        // manipulate the data store on the main thread
                        if newLocations.count > 0 {
                            let defaultInfo = newLocations[0]
                            var test = self.currentUser?.objectId
                            self.currentUser?.objectId = defaultInfo.objectId
                            self.currentUser?.mediaUrl = defaultInfo.mediaUrl
                            self.currentUser?.mapString = defaultInfo.mapString
                            self.currentUser?.latitude = defaultInfo.latitude
                            self.currentUser?.longitude = defaultInfo.longitude
                            self.currentUser?.updatedAt = defaultInfo.updatedAt
                            self.currentUser?.createdAt = defaultInfo.createdAt
                        }
                        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                            completionHandler(success: true, error: nil)
                        }
                    }
                } else {
                    completionHandler(success: false, error: error)
                }
        
            }
        }
    }
    
    func validateUrlString(urlString: String, completionHandler: (success: Bool, errorMessage: String?) -> Void) {
        WebClient().pingUrl(urlString) { reply, error in
            if reply {
                completionHandler(success: true, errorMessage: nil)
            } else if let error = error {
                completionHandler(success: false, errorMessage: error.localizedDescription)
            } else {
                completionHandler(success: false, errorMessage: "Unspecified Error Connecting to \(urlString)")
            }
        }
    }
    
    
    
}

// MARK: - Data Translator

private func putValue(value: AnyObject?, var intoDictionary dictionary: [String:AnyObject], forKey key: String) -> [String:AnyObject] {
    if let value: AnyObject = value {
        dictionary[key] = value
    }
    return dictionary
}

func translateToStudentInformationFromUdacityData(udacityData: [String:AnyObject]) -> StudentInformation? {
    var parseData = Dictionary<String, AnyObject>()
    parseData = putValue(udacityData[UdacityService.UdacityJsonKey.Key], intoDictionary: parseData, forKey: OnTheMapParseService.ParseJsonKey.UniqueKey)
    parseData = putValue(udacityData[UdacityService.UdacityJsonKey.Firstname], intoDictionary: parseData, forKey: OnTheMapParseService.ParseJsonKey.Firstname)
    parseData = putValue(udacityData[UdacityService.UdacityJsonKey.Lastname], intoDictionary: parseData, forKey: OnTheMapParseService.ParseJsonKey.Lastname)
    
    var studentInformation = StudentInformation(parseData: parseData)
    
    if let emailBlock = udacityData[UdacityService.UdacityJsonKey.Email] as? [String:AnyObject],
        emailAddress = emailBlock[UdacityService.UdacityJsonKey.Address] as? String {
        
        studentInformation?.email = emailAddress
    }
    
    return studentInformation
}

// MARK: - Authentication Type

enum AuthenticationType {
    case NotAuthenticated
    case UdacityUsernameAndPassword
    case FacebookToken
}
