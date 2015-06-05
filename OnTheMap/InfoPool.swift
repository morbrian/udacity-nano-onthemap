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
    typealias GroupType = T.GroupType
    typealias OrderByType = T.OrderByType
    
    private var infoItems = [T]()
    private var infoGroupToIndexMap = [GroupType:[Int]]()
    private var infoIdToIndexMap = [IdType:Int]()
    
    // count the number of total items it the list, or matching the filter if filter specified
    public func count(filter: ((infoItem: T) -> Bool)? = nil) -> Int {
        if let filter = filter {
            return infoItems.reduce(0) { count, student in
                return filter(infoItem: student) ? count + 1 : count
            }
        } else {
            return infoItems.count
        }
    }
    
    // get the info item at the specified index from the stored list, or from the filtered list if filter specified
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
    
    // get the last infor item in the list, or in the filtered list if filter specifed
    public func lastInfoItem(filter: ((infoItem: T) -> Bool)? = nil) -> T? {
        return infoAtIndex(count(filter: filter) - 1, filter: filter)
    }
    
    // get a copy of the list, or of a subset of the list if filter specified
    public func infoItemsAsArray(filter: ((infoItem: T) -> Bool)? = nil) -> [T] {
        if let filter = filter {
           return infoItems.filter(filter)
        } else {
            return infoItems
        }
    }
    
    // delete the specified item from the list
    public mutating func deleteInfoItem(infoItem: T) {
        if let index = infoIdToIndexMap[infoItem.id] {
            infoItems.removeAtIndex(index)
            organizeInfoItems()
        }
    }
    
    // store the new item in the list
    public mutating func storeInfoItem(newInfoItem: T) {
        //if infoIdToIndexMap
        if let idIndex = infoIdToIndexMap[newInfoItem.id] {
            infoItems[idIndex] = newInfoItem
        } else {
            infoItems.append(newInfoItem)
        }
        organizeInfoItems()
    }
    
    // store multiple info items into the list
    public mutating func storeInfoItems(newInfoItems: [T]) {
        infoItems.extend(newInfoItems)
        organizeInfoItems()
    }
    
    // true if the list contains at least one item for the specified group
    public func infoExistsForGroup(group: GroupType) -> Bool {
        return infoGroupToIndexMap.indexForKey(group) != nil
    }
    
    // true if an item with the specified id exists
    public func infoExistsForId(id: IdType) -> Bool {
        return infoIdToIndexMap.indexForKey(id) != nil
    }
    
    // list of indices for items in the specified group
    public func indicesOfInfoGroupedBy(group: GroupType) -> [Int]? {
        return infoGroupToIndexMap[group]
    }
    
    // index of the info item with the specified ID
    public func indexOfInfoIdentifiedBy(id: IdType) -> Int? {
        return infoIdToIndexMap[id]
    }
    
    // resort and reindex the list, typically called after an add or delete
    // we resort everything, but this could be optimized later for larger datasets
    private mutating func organizeInfoItems() {
        infoItems.sort() { $0.0.orderBy > $0.1.orderBy }
        // enforce uniqueness
        infoItems.reduce([T]()) { (list, item) in
            if list.count == 0 || list.last!.id != item.id {
                var newList = [T]()
                newList.extend(list)
                newList.append(item)
                return list
            } else {
                return list
            }
        }
        remapIndices()
    }
    
    // remap all indeces to sync up with changes in the list contents
    private mutating func remapIndices() {
        infoGroupToIndexMap.removeAll(keepCapacity: true)
        infoIdToIndexMap.removeAll(keepCapacity: true)
        for (index: Int, item: T) in enumerate(infoItems) {
            mapGroup(item.group, toIndex: index)
            mapId(item.id, toIndex: index)
        }
    }
    
    // add an index to the list of indices associated with the group
    private mutating func mapGroup(group: GroupType, toIndex index: Int) {
        var indices: [Int] = infoGroupToIndexMap[group] ?? [Int]()
        indices.append(index)
        infoGroupToIndexMap.updateValue(indices, forKey: group)
    }
    
    // associate the index with the item id
    private mutating func mapId(id: IdType, toIndex index: Int) {
        infoIdToIndexMap.updateValue(index, forKey: id)
    }
}

// MARK: - InfoItem

// all info items must have at least an ID, Group, and attribute value to sort by
public protocol InfoItem {
    
    // must be unique value among all other info items in the pool
    typealias IdType: Hashable, Comparable
    var id: IdType { get }

    // info items with equal group values are considered part of the same group.
    typealias GroupType: Hashable, Comparable
    var group: GroupType { get }
    
    // the pool is managed as a sorted list and this value is used to sort the info items.
    typealias OrderByType: Comparable
    var orderBy: OrderByType { get }
    
}

