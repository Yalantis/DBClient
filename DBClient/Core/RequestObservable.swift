//
//  RequestObservable.swift
//  DBClient
//
//  Created by Serhii Butenko on 15/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

/// Describes changes in database:
///
/// - initial: initial storred entities;
/// - update:
///         -- objects: all objects in current version of the collection;
///         -- deletions: the indices in the previous version of the collection which were removed from this one;
///         -- insertions: the indices in the new collection and object which was added in this version;
///         -- modifications: the indices of the objects in the new collection and objects inself which was modified in this version;
/// - error: an error occurred during fetch.
public enum ObservableChange<T: Stored> {
    
    public typealias ModelChange = (
        objects: [T],
        deletions: [Int],
        insertions: [(index: Int, element: T)],
        modifications: [(index: Int, element: T)]
    )
    
    case initial([T])
    case change(ModelChange)
    case error(Error)
}

public class RequestObservable<T: Stored> {
    
    let request: FetchRequest<T>
    
    init(request: FetchRequest<T>) {
        self.request = request
    }
    
    /// Starts observing with a given fetch request.
    ///
    /// - Parameter closure: gets called once any changes in database are occurred.
    /// - Warning: You cannot call the method only if you don't observe it now.
    public func observe(_ closure: @escaping (ObservableChange<T>) -> Void) {
        assertionFailure("The observe method must be overriden")
    }
}
