//
//  RealmDBClient.swift
//  DBClient
//
//  Created by Serhii Butenko on 19/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
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
    public func execute<T>(_ request: FetchRequest<T>, completion: @escaping (Result<[T]>) -> Void) {
        completion(execute(request))
    }
    
    /// Inserts new objects to database. If object with such `primaryKeyValue` already exists Realm'll throw an error
    public func insert<T>(_ objects: [T], completion: @escaping (Result<[T]>) -> Void) where T : Stored {
        completion(insert(objects))
    }
    
    /// Updates objects which are already in db.
    public func update<T>(_ objects: [T], completion: @escaping (Result<[T]>) -> Void) where T : Stored {
        completion(update(objects))
    }
    
    /// Removes objects by it `primaryKeyValue`s
    public func delete<T>(_ objects: [T], completion: @escaping (Result<()>) -> Void) where T : Stored {
        completion(delete(objects))
    }
    
    public func deleteAllObjects<T>(of type: T.Type, completion: @escaping (Result<()>) -> Void) where T: Stored {
        let type = checkType(T.self)
        
        let realmType = type.realmClass()
        
        do {
            let realmObjects = realm.objects(realmType)
            realm.beginWrite()
            realm.delete(realmObjects)
            try realm.commitWrite()
            
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    public func upsert<T>(_ objects: [T], completion: @escaping (Result<(updated: [T], inserted: [T])>) -> Void) where T : Stored {
        completion(upsert(objects))
    }
    
    public func observable<T>(for request: FetchRequest<T>) -> RequestObservable<T> {
        checkType(T.self)
        
        return RealmObservable(request: request, realm: realm)
    }
    
    public func execute<T>(_ request: FetchRequest<T>) -> Result<[T]> {
        let modelType = checkType(T.self)
        let neededType = modelType.realmClass()
        let objects = request
            .applyTo(realmObjects: realm.objects(neededType))
            .map { $0 }
            .slice(offset: request.fetchOffset, limit: request.fetchLimit)
            .compactMap { modelType.from($0) as? T }
        
        return .success(objects)
    }
    
    @discardableResult
    public func insert<T: Stored>(_ objects: [T]) -> Result<[T]> {
        checkType(T.self)
        
        let realmObjects = objects.compactMap { ($0 as? RealmModelConvertible)?.toRealmObject() }
        
        do {
            realm.beginWrite()
            realm.add(realmObjects)
            try realm.commitWrite()
            return .success(objects)
        } catch {
            return .failure(error)
        }
    }
    
    @discardableResult
    public func update<T: Stored>(_ objects: [T]) -> Result<[T]> {
        checkType(T.self)
        
        let realmObjects = separate(objects: objects)
            .present
            .compactMap { ($0 as? RealmModelConvertible)?.toRealmObject() }
        do {
            realm.beginWrite()
            realm.add(realmObjects, update: true)
            try realm.commitWrite()
            
            return .success(objects)
        } catch let error {
            return .failure(error)
        }
    }
    
    @discardableResult
    public func delete<T: Stored>(_ objects: [T]) -> Result<()> {
        let type = checkType(T.self)
        
        let realmType = type.realmClass()
        
        do {
            let primaryValues = objects.compactMap { $0.valueOfPrimaryKey }
            let realmObjects = primaryValues.compactMap { realm.object(ofType: realmType, forPrimaryKey: $0) }
            realm.beginWrite()
            realm.delete(realmObjects)
            try realm.commitWrite()
            
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    @discardableResult
    public func upsert<T : Stored>(_ objects: [T]) -> Result<(updated: [T], inserted: [T])> {
        checkType(T.self)
        
        let separatedObjects = separate(objects: objects)
        let realmObjects = objects.compactMap { ($0 as? RealmModelConvertible)?.toRealmObject() }
        do {
            realm.beginWrite()
            realm.add(realmObjects, update: true)
            try realm.commitWrite()
            return .success((updated: separatedObjects.present, inserted: separatedObjects.new))
        } catch {
            return .failure(error)
        }
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
    
    func applyTo<T>(realmObjects: Results<T>) -> Results<T> {
        var objects: Results<T> = realmObjects
        if let sortDescriptors = sortDescriptors?.compactMap(SortDescriptor.init), !sortDescriptors.isEmpty {
            objects = realmObjects.sorted(by: sortDescriptors)
        }
        if let predicate = predicate {
            objects = objects.filter(predicate)
        }
        
        return objects
    }
}

private extension SortDescriptor {
    
    init?(_ descriptor: NSSortDescriptor) {
        if let key = descriptor.key {
            self = SortDescriptor(keyPath: key, ascending: descriptor.ascending)
        } else {
            return nil
        }
    }
    
}

private extension Array {
    
    func slice<T: Stored>(offset: Int, limit: Int) -> [T] {
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
        
        return (off..<lim).compactMap { self[$0] as? T }
    }
}
