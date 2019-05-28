//
//  FetchRequest.swift
//  DBClient
//
//  Created by Serhii Butenko on 15/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

/// Describes a fetch request to get objects from a database.
public struct FetchRequest<T: Stored> {
    
    public let sortDescriptor: NSSortDescriptor?
    public let predicate: NSPredicate?
    public let fetchOffset: Int
    public let fetchLimit: Int
    
    /// - Parameters:
    ///   - predicate: Predicate for objects filtering; nil by default.
    ///   - sortDescriptor: Sort descriptor; nil by default.
    ///   - fetchOffset: Offset of data for request; 0 by default (no offset).
    ///   - fetchLimit: Amount of objects to be fetched; no limit if zero given; 0 by default.
    public init(predicate: NSPredicate? = nil, sortDescriptor: NSSortDescriptor? = nil, fetchOffset: Int = 0, fetchLimit: Int = 0) {
        self.predicate = predicate
        self.sortDescriptor = sortDescriptor
        self.fetchOffset = fetchOffset
        self.fetchLimit = fetchLimit
    }
}

// MARK: - Filtering

public extension FetchRequest {
    
    /**
     Filters all objects with given predicate
     
     - Returns: New instance
     */
    func filtered(with predicate: NSPredicate) -> FetchRequest<T> {
        return request(withPredicate: predicate)
    }
    
    /**
     Filters all objects to match `key`=`value`.
     
     - Returns: New intance
     */
    func filtered(with key: String, equalTo value: String) -> FetchRequest<T> {
        return request(withPredicate: NSPredicate(format: "\(key) == %@", value))
    }
    
    /**
     Removes any object with value of `key` property not from given array of values from request.
     
     - Returns: New instance
     */
    func filtered(with key: String, in value: [String]) -> FetchRequest<T> {
        return request(withPredicate: NSPredicate(format: "\(key) IN %@", value))
    }
    
    /**
     Removes any object with value of `key` property from given array of values from request.
     
     - Returns: New instance
     */
    func filtered(with key: String, notIn value: [String]) -> FetchRequest<T> {
        return request(withPredicate: NSPredicate(format: "NOT (\(key) IN %@)", value))
    }
}

// MARK: - Sorting

public extension FetchRequest {
    
    func sorted(with sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        return request(withSortDescriptor: sortDescriptor)
    }
    
    func sorted(with key: String?, ascending: Bool, comparator cmptr: @escaping Comparator) -> FetchRequest<T> {
        return request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, comparator: cmptr))
    }
    
    func sorted(with key: String?, ascending: Bool) -> FetchRequest<T> {
        return request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending))
    }
    
    func sorted(with key: String?, ascending: Bool, selector: Selector) -> FetchRequest<T> {
        return request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, selector: selector))
    }
}

// MARK: - Private

private extension FetchRequest {
    
    func request(withPredicate predicate: NSPredicate) -> FetchRequest<T> {
        return FetchRequest<T>(predicate: predicate, sortDescriptor: sortDescriptor, fetchOffset: fetchOffset, fetchLimit: fetchLimit)
    }
    
    func request(withSortDescriptor sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        return FetchRequest<T>(predicate: predicate, sortDescriptor: sortDescriptor, fetchOffset: fetchOffset, fetchLimit: fetchLimit)
    }
}
