//
//  RealmDBClient.swift
//  DBClient
//
//  Created by Serhii Butenko on 19/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import BoltsSwift
import RealmSwift

/// Describes protocol to be implemented by model for `RealmDBClient`
public protocol RealmModelConvertible: Stored {
    
    /// - Returns: type of object for model
    static func realmClass() -> Object.Type
    
    /// Executes mapping from `Realm.Object` instance
    ///
    /// - Parameter realmObject: Object to be mapped from
    /// - Returns: Fulfilled model instance
    static func from(_ realmObject: Object) -> Stored
    
    /// Executes backward mapping from `Realm.Object`
    func toRealmObject() -> Object
    
}


/// Implementation of database client for Realm storage type.
/// Model for this client must conform to `RealmModelConverible` protocol or error will be raised.
public class RealmDBClient {
    
    let realm: Realm
    
    public init(realm: Realm) {
        self.realm = realm
    }
    
}

extension RealmDBClient: DBClient {
    
    @discardableResult
    fileprivate func checkType<T>(_ inputType: T) -> RealmModelConvertible.Type {
        guard let modelType = T.self as? RealmModelConvertible.Type else {
            fatalError("`\(String(describing: RealmDBClient.self))` can manage only types which conform to `\(String(describing: RealmModelConvertible.self))`")
        }
        
        return modelType
    }
    
    public func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]> {
        let modelType = checkType(T.self)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        let neededType = modelType.realmClass()
        do {
            var objects: [Object] = realm
                .objects(neededType)
                .map { $0 }
            if let descriptor = request.sortDescriptor {
                let order: ComparisonResult = descriptor.ascending ? .orderedAscending : .orderedDescending
                objects = objects.sorted(by: { (lhs, rhs) -> Bool in
                    return descriptor.compare(lhs, to: rhs) == order
                })
            }
            if let predicate = request.predicate {
                objects = objects.filter { predicate.evaluate(with: $0) }
            }
            let mappedObjects = objects
                .get(offset: request.fetchOffset, limit: request.fetchLimit)
                .flatMap { modelType.from($0) as? T }
            taskCompletionSource.set(result: mappedObjects)
        } catch let error {
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
    
    public func insert<T: Stored>(_ objects: [T]) -> Task<[T]> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        
        let realmObjects = objects.flatMap { $0 as? RealmModelConvertible }.map { $0.toRealmObject() }
        do {
            realm.beginWrite()
            realm.add(realmObjects)
            try realm.commitWrite()
            taskCompletionSource.set(result: objects)
        } catch let error {
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
    
    public func update<T: Stored>(_ objects: [T]) -> Task<[T]> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        
        let realmObjects = objects.flatMap { $0 as? RealmModelConvertible }.map { $0.toRealmObject() }
        do {
            realm.beginWrite()
            realm.add(realmObjects, update: true)
            try realm.commitWrite()
            taskCompletionSource.set(result: objects)
        } catch let error {
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
    
    public func delete<T: Stored>(_ objects: [T]) -> Task<Void> {
        let type = checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<Void>()
        let realmType = type.realmClass()
        
        do {
            let primaryValues = objects.flatMap { $0.valueOfPrimaryKey }
            let realmObjects = primaryValues.flatMap { realm.object(ofType: realmType, forPrimaryKey: $0) }
            realm.beginWrite()
            realm.delete(realmObjects)
            try realm.commitWrite()
            taskCompletionSource.set(result: ())
        } catch let error {
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
    
    public func upsert<T : Stored>(_ objects: [T]) -> Task<(updated: [T], inserted: [T])> {
        checkType(T)
        
        fatalError("Not implemented")
    }
    
    public func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T> {
        checkType(T)
        
        return RealmObservable(request: request, realm: realm)
    }
    
}

extension Array {
    
    func get<T: Object>(offset: Int, limit: Int) -> [T] {
        var lim = 0
        var off = 0
        let count = self.count
        
        if off <= offset && offset < count - 1 {
            off = offset
        }
        if limit > count || limit == 0 {
            lim = count
        } else {
            lim = offset + limit
        }
        
        return (off..<lim).map { self[$0] as! T }
    }
    
}
