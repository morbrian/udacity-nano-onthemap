//
//  StudentInformationDataAccessManager.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class StudentDataAccessManager {
    
    // how many items we request at a time
    var fetchLimit = 100
    
    var udacityClient: UdacityService!
    var onTheMapClient: OnTheMapParseService!
    
    private var currentUser: StudentInformation?
    
    // read only access to the logged in user data reference
    var loggedInUser: StudentInformation? { return currentUser }
    
    var pageCache = PageCache()
    
    init() {
        udacityClient = UdacityService()
        onTheMapClient = OnTheMapParseService()
    }
    
    var authenticated: Bool {
        return currentUser != nil
    }
    
    var studentLocationCount: Int {
        return pageCache.pageItemCount
    }
    
    func studentLocationAtIndex(index: Int) -> StudentLocation? {
        return pageCache.pageItemAtIndex(index)
    }
    
    var studentLocations: [StudentLocation] {
        return pageCache.pagedItems
    }
    
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
    
    func preFetchStudentLocationSubset(subset: Range<Int>, completionHandler: (success: Bool, error: NSError?) -> Void) {
        let skip = subset.startIndex
        let limit = subset.endIndex - skip
        onTheMapClient.fetchStudentLocations(limit: limit, skip: skip) {
            studentLocations, error in
            if let newLocations = studentLocations {
                //let pageRange = subset.startIndex..<(skip + newLocations.count)
                self.pageCache.storeItems(newLocations)
                Logger.info("asked for items \(skip) - \(subset.endIndex) and found \(newLocations.count)")
                completionHandler(success: true, error: nil)
            } else {
                completionHandler(success: false, error: error)
            }
        }
    }
    
    private var lastSuccessfulRange: Range<Int>?
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

struct PageCache {
    
    private var pagedItems = [StudentLocation]()
    
    var pageItemCount: Int {
        return pagedItems.count
    }
    
    func pageItemAtIndex(var index: Int) -> StudentLocation? {
        if index >= 0 && index < pagedItems.count {
            return pagedItems[index]
        } else {
            return nil
        }
    }
    
    mutating func storeItems(items: [StudentLocation]) {
        // TODO: keep the array sorted... smartly, but some parameterized sorting option to match the query used.
        // TODO: requires parsing the data strings since I like to use Last Updated Time.
        pagedItems.extend(items)
    }
    
}
