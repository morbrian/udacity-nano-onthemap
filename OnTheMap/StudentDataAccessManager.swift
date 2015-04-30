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
    // this can be set by calling APIs
    var fetchLimit = 100
    
    private var udacityClient: UdacityService!
    private var onTheMapClient: OnTheMapParseService!
    
    private var currentUser: StudentInformation?
    
    // read only access to the logged in user data reference
    var loggedInUser: StudentInformation? { return currentUser }
    
    var itemCache = ItemCache()
    
    init() {
        udacityClient = UdacityService()
        onTheMapClient = OnTheMapParseService()
    }
    
    // return true if the user has authenticated
    var authenticated: Bool {
        return currentUser != nil
    }
    
    // number of items downloaded so far
    var studentLocationCount: Int {
        return itemCache.itemCount
    }
    
    // return the student location for the specified index
    func studentLocationAtIndex(index: Int) -> StudentLocation? {
        return itemCache.itemAtIndex(index)
    }
    
    // return the entire list of student locations
    var studentLocations: [StudentLocation] {
        return itemCache.items
    }
    
    // authenticate the user by username and password with the Udacity service.
    func authenticateByUsername(username: String, withPassword password: String,
        completionHandler: (success: Bool, error: NSError?) -> Void) {
        udacityClient.authenticateByUsername(username, withPassword: password) {
            userIdentity, error in
            if let userIdentity = userIdentity {
                self.udacityClient.fetchInformationForStudentIdentity(userIdentity) {
                    userData, error in
                    self.currentUser = userData
                    completionHandler(success: true, error: nil)
                }
            } else {
                completionHandler(success: false, error: error)
            }
        }
            
    }
    
    // fetch the requested range of data from the OnTheMap Parse Web Service
    func preFetchStudentLocationSubset(subset: Range<Int>, completionHandler: (success: Bool, error: NSError?) -> Void) {
        let skip = subset.startIndex
        let limit = subset.endIndex - skip
        onTheMapClient.fetchStudentLocations(limit: limit, skip: skip) {
            studentLocations, error in
            if let newLocations = studentLocations {
                //let pageRange = subset.startIndex..<(skip + newLocations.count)
                self.itemCache.storeItems(newLocations)
                Logger.info("asked for items \(skip) - \(subset.endIndex) and found \(newLocations.count)")
                completionHandler(success: true, error: nil)
            } else {
                completionHandler(success: false, error: error)
            }
        }
    }
    
    private var lastSuccessfulRange: Range<Int>?
    // fetch the next set of data starting from where the last successful query left off.
    // this essentially pages through new data, without discarding previously downloaded data pages.
    func fetchNextPage(completionHandler: (success: Bool, error: NSError?) -> Void) {
        let start = lastSuccessfulRange?.endIndex ?? 0
        let end = start + fetchLimit
        let attemptRange = start..<end
        preFetchStudentLocationSubset(attemptRange) {
            success, error in
            if success {
                self.lastSuccessfulRange = attemptRange
            }
            completionHandler(success: success, error: error)
        }
    }
    
}

// MARK: - ItemCache

// ItemCache
// Simple structure for storing and accessing previously downloaded data items.
struct ItemCache {
    
    private var items = [StudentLocation]()
    
    var itemCount: Int {
        return items.count
    }
    
    func itemAtIndex(var index: Int) -> StudentLocation? {
        if index >= 0 && index < items.count {
            return items[index]
        } else {
            return nil
        }
    }
    
    mutating func storeItems(newItems: [StudentLocation]) {
        // TODO: keep the array sorted... smartly, but some parameterized sorting option to match the query used.
        items.extend(newItems)
    }
    
}
