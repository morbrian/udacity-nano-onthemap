//
//  StudentInformationDataAccessManager.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/26/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

class StudentDataAccessManager {
    
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
                let pageRange = subset.startIndex..<(skip + newLocations.count)
                self.pageCache.storePage(Page(pageRange: pageRange, pagedItems: newLocations))
                Logger.info("asked for items \(skip) - \(subset.endIndex) and found \(newLocations.count)")
                completionHandler(success: true, error: nil)
            } else {
                completionHandler(success: false, error: error)
            }
        }
    }
    
}

struct Page {
    let pageRange: Range<Int>
    var pagedItems:[StudentLocation]
}

struct PageCache {
    
    private var itemReferences = [String:[Page]]()
    private let maxPages = 6
    
    private var pages = [Page]()
    
    var pageItemCount: Int {
        return pages.reduce(0) {return $0 + $1.pagedItems.count}
    }
    
    func pageItemAtIndex(var index: Int) -> StudentLocation? {
        // pages may not be the same size, so we have to do a small iteration
        for page in pages {
            if index >= 0 && index < page.pagedItems.count {
                return page.pagedItems[index]
            } else {
                index -= page.pagedItems.count
            }
        }
        return nil
    }
    
    mutating func storePage(var page: Page) {
        if pages.count == 0 || page.pageRange.startIndex < pages[0].pageRange.startIndex {
            pages.insert(page, atIndex: 0)
        } else {
            pages.append(page)
        }
    }
    
}
