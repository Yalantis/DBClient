//
//  RealmDBClient.swift
//  ArchitectureGuideTemplate
//
//  Created by Serhii Butenko on 19/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import BoltsSwift
import RealmSwift

/**
  Describes protocol to be implemented by model for `RealmDBClient`
*/
public protocol RealmModelConvertible: Stored {

  /**
    Returns type of object for model
  */
  static func realmClass() -> Object.Type

  /**
    Executes mapping from `Realm.Object` instance
    
    - Parameter realmObject: Object to be mapped from
     
    - Returns: Fulfilled model instance
  */
  static func from(_ realmObject: Object) -> Stored

  /**
    Executes backward mapping from `Realm.Object`
  */
  func toRealmObject() -> Object
  
}

/**
  Implementation of database client for Realm storage type.
  Model for this client must conform `RealmModelConverible` protocol or error will be raised.
*/
public class RealmDBClient {
  
  let realm: Realm
  
  public init(realm: Realm) {
    self.realm = realm
  }

}

extension RealmDBClient: DBClient {
  
  public func save<T: Stored>(_ objects: [T]) -> Task<[T]> {
    let taskCompletionSource = TaskCompletionSource<[T]>()
    
    let realmObjects = objects.flatMap { $0 as? RealmModelConvertible }.map { $0.toRealmObject() }
    do {
      try realm.write {
        realm.add(realmObjects, update: true)
      }
      taskCompletionSource.set(result: objects)
    } catch let error {
      taskCompletionSource.set(error: error)
    }
    
    return taskCompletionSource.task
  }
  
  public func update<T: Stored>(_ objects: [T]) -> Task<[T]> {
    return save(objects)
  }
  
  public func delete<T: Stored>(_ objects: [T]) -> Task<[T]> {
    let taskCompletionSource = TaskCompletionSource<[T]>()
    
    do {
      let realmObjects = objects.flatMap { $0 as? RealmModelConvertible }.map { $0.toRealmObject() }
      try realm.write {
        realm.delete(realmObjects)
        taskCompletionSource.set(result: objects)
      }
    } catch let error {
      taskCompletionSource.set(error: error)
    }
    
    return taskCompletionSource.task
  }
  
  public func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]> {
    guard let modelType = T.self as? RealmModelConvertible.Type else {
        fatalError("RealmDBClient can manage only types which conform to RealmModelConvertible")
    }
    if let predicate = request.predicate {
      print("RealmDBClient doesn't support `predicate` property of FetchRequest")
    }
    let taskCompletionSource = TaskCompletionSource<[T]>()
    let neededType = modelType.realmClass()
    do {
      var objects = realm
        .objects(neededType)
        .get(offset: request.fetchOffset, limit: request.fetchLimit)
      if let descriptor = request.sortDescriptor {
        let order: ComparisonResult = descriptor.ascending ? .orderedAscending : .orderedDescending
        objects = objects.sorted(by: { (lhs, rhs) -> Bool in
          return descriptor.compare(lhs, to: rhs) == order
        })
      }
      let mappedObjects = objects.flatMap { modelType.from($0) as? T }
      taskCompletionSource.set(result: mappedObjects)
    } catch let error {
        taskCompletionSource.set(error: error)
    }

    return taskCompletionSource.task
  }
  
  public func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T>{
//    return RealmObservable(request: request, realm: realm)
    return RequestObservable(request: request)
  }

}

extension Results {

  func get<T: Object>(offset: Int, limit: Int) -> [T] {
    var lim = 0
    var off = 0
    var l: [T] = []
    let count = self.count

    if off <= offset && offset < count - 1 {
      off = offset
    }
    if limit > count || limit == 0 {
      lim = count
    } else {
      lim = limit
    }

    for i in off..<lim {
      let dog = self[i] as! T
      l.append(dog)
    }

    return l
  }
}
