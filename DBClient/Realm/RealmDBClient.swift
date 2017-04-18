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

extension RealmModelConvertible {
    
    func realmClassForInstance() -> Object.Type {
        return Self.realmClass()
    }
    
}

/// Implementation of database client for Realm storage type.
/// Model for this client must conform to `RealmModelConverible` protocol or error will be raised.
public class RealmDBClient {
    
    let realm: Realm
    
    public init(realm: Realm) {
        self.realm = realm
    }
    
}

// MARK: DBClient

extension RealmDBClient: DBClient {
    
    /// Executes given request. Fetches all entities and then applies all given restrictions
    public func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]> {
        let modelType = checkType(T.self)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        let neededType = modelType.realmClass()
        do {
            let objects = request
                .applyTo(realmObjects: realm.objects(neededType))
                .map { $0 }
                .get(offset: request.fetchOffset, limit: request.fetchLimit)
                .flatMap { modelType.from($0) as? T }
            taskCompletionSource.set(result: objects)
        } catch let error {
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
    
    /// Inserts new objects to database. If object with such `primaryKeyValue` already exists Realm'll throw an error
    public func insert<T: Stored>(_ objects: [T]) -> Task<[T]> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        
        let realmObjects = objects.flatMap { ($0 as? RealmModelConvertible)?.toRealmObject() }
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
    
    /// Updates objects which are already in db.
    public func update<T: Stored>(_ objects: [T]) -> Task<[T]> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        let realmObjects = separate(objects: objects)
            .present
            .flatMap { ($0 as? RealmModelConvertible)?.toRealmObject() }
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
    
    /// Removes objects by it `primaryKeyValue`s
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
        
        let taskCompletionSource = TaskCompletionSource<(updated: [T], inserted: [T])>()
        let separatedObjects = separate(objects: objects)
        let realmObjects = objects.flatMap { ($0 as? RealmModelConvertible)?.toRealmObject() }
        do {
            realm.beginWrite()
            realm.add(realmObjects, update: true)
            try realm.commitWrite()
            taskCompletionSource.set(result: (updated: separatedObjects.present, inserted: separatedObjects.new))
        } catch let error {
            taskCompletionSource.set(error: error)
        }
        
        return taskCompletionSource.task
    }
    
    public func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T> {
        checkType(T)
        
        return RealmObservable(request: request, realm: realm)
    }
    
}

private extension RealmDBClient {
    
    @discardableResult
    func checkType<T>(_ inputType: T) -> RealmModelConvertible.Type {
        switch inputType {
        case let type as RealmModelConvertible.Type:
            return type
            
        default:
            let model = String(describing: RealmDBClient.self)
            let prot = String(describing: RealmModelConvertible.self)
            let given = String(describing: inputType)
            fatalError("`\(model)` can manage only types which conform to `\(prot)`. `\(given)` given.")
        }
    }
    
    func separate<T: Stored>(objects: [T]) -> (present: [T], new: [T]) {
        var presentObjects: [T] = []
        var notPresentObjects: [T] = []
        objects.forEach { object in
            guard let convertedObject = object as? RealmModelConvertible,
                let primaryValue = convertedObject.valueOfPrimaryKey else {
                    return
            }
            
            let entry = self.realm.object(ofType: convertedObject.realmClassForInstance(), forPrimaryKey: primaryValue)
            if entry != nil {
                presentObjects.append(object)
            } else {
                notPresentObjects.append(object)
            }
        }
        
        return (present: presentObjects, new: notPresentObjects)
    }
    
}

internal extension FetchRequest {
    
    func applyTo<T: Object>(realmObjects: Results<T>) -> Results<T> {
        var objects: Results<T> = realmObjects
        if let sortDescriptor = sortDescriptor, let key = sortDescriptor.key {
            objects = realmObjects.sorted(byProperty: key, ascending: sortDescriptor.ascending)
        }
        if let predicate = predicate {
            objects = objects.filter(predicate)
        }
        
        return objects
    }
    
}

private extension Array {
    
    func get<T: Stored>(offset: Int, limit: Int) -> [T] {
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
        
        return (off..<lim).flatMap { self[$0] as? T }
    }
    
}
