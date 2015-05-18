//
//  InfoPool.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/6/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// InfoPool
// Generic structure for storing and accessing data items.
public struct InfoPool<T: InfoItem> {
    typealias IdType = T.IdType
    typealias OwnerType = T.OwnerType
    typealias OrderByType = T.OrderByType
    
    private var infoItems = [T]()
    private var infoOwnerToIndexMap = [OwnerType:[Int]]()
    private var infoIdToIndexMap = [IdType:Int]()
    
    public func count(filter: ((infoItem: T) -> Bool)? = nil) -> Int {
        if let filter = filter {
            return infoItems.reduce(0) { count, student in
                return filter(infoItem: student) ? count + 1 : count
            }
        } else {
            return infoItems.count
        }
    }
    
    public func infoAtIndex(var index: Int, filter: ((infoItem: T) -> Bool)? = nil) -> T? {
        let itemList: [T]
        if let filter = filter {
            itemList = infoItems.filter(filter)
        } else {
            itemList = infoItems
        }
        if index >= 0 && index < itemList.count {
            return itemList[index]
        } else {
            return nil
        }
    }
    
    public func infoItemsAsArray(filter: ((infoItem: T) -> Bool)? = nil) -> [T] {
        if let filter = filter {
           return infoItems.filter(filter)
        } else {
            return infoItems
        }
    }
    
    public mutating func deleteInfoItem(infoItem: T) {
        if let index = infoIdToIndexMap[infoItem.id] {
            infoItems.removeAtIndex(index)
            organizeInfoItems()
        }
    }
    
    public mutating func storeInfoItem(newInfoItem: T) {
        //if infoIdToIndexMap
        if let idIndex = infoIdToIndexMap[newInfoItem.id] {
            infoItems[idIndex] = newInfoItem
        } else {
            infoItems.append(newInfoItem)
        }
        // we resort everything, could be optimized later for larger datasets
        organizeInfoItems()
    }
    
    public mutating func storeInfoItems(newInfoItems: [T]) {
        infoItems.extend(newInfoItems)
        organizeInfoItems()
    }
    
    public func infoExistsForOwner(owner: OwnerType) -> Bool {
        return infoOwnerToIndexMap.indexForKey(owner) != nil
    }
    
    public func infoExistsForId(id: IdType) -> Bool {
        return infoIdToIndexMap.indexForKey(id) != nil
    }
    
    public func indicesOfInfoOwnedBy(owner: OwnerType) -> [Int]? {
        return infoOwnerToIndexMap[owner]
    }
    
    public func indicesOfInfoIdentifiedBy(id: IdType) -> Int? {
        return infoIdToIndexMap[id]
    }
    
    private mutating func organizeInfoItems() {
        infoItems.sort() { $0.0.orderBy > $0.1.orderBy }
        remapIndices()
    }
    
    private mutating func remapIndices() {
        infoOwnerToIndexMap.removeAll(keepCapacity: true)
        infoIdToIndexMap.removeAll(keepCapacity: true)
        for (index: Int, item: T) in enumerate(infoItems) {
            mapOwner(item.owner, toIndex: index)
            mapId(item.id, toIndex: index)
        }
    }
    
    private mutating func mapOwner(owner: OwnerType, toIndex index: Int) {
        var indices: [Int] = infoOwnerToIndexMap[owner] ?? [Int]()
        indices.append(index)
        infoOwnerToIndexMap.updateValue(indices, forKey: owner)
    }
    
    private mutating func mapId(id: IdType, toIndex index: Int) {
        infoIdToIndexMap.updateValue(index, forKey: id)
    }
}

public protocol InfoItem {
    
    typealias IdType: Hashable, Comparable
    var id: IdType { get }

    typealias OwnerType: Hashable, Comparable
    var owner: OwnerType { get }
    
    typealias OrderByType: Comparable
    var orderBy: OrderByType { get }
    
}

