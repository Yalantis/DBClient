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
protocol RealmModelConvertible: Stored {

  /**
    Returns type of object for model
  */
  static func realmClass() -> Object.Type

  /**
    Executes mapping from `Realm.Object` instance
    
    - Parameter realmObject: Object to be mapped from
     
    - Returns: Fulfilled model instance
  */
  static func from(_ realmObject: Object) -> Self

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
  
  public func fetch<T: Stored>(id: String) -> Task<[T]> {
    guard let realmModelType = T.self as? RealmModelConvertible.Type else {
      fatalError("CoreDataDBClient can manage only types which conform to CoreDataModelConvertible")
    }
    let result = realm.objects(realmModelType.realmClass())
    let objects = Array(result.map { realmModelType.from($0) as! T})
        
    return Task(objects)
  }
  
  public func fetch<T: Stored>(with predicate: NSPredicate?) -> Task<[T]> {
    guard let realmModelType = T.self as? RealmModelConvertible.Type else {
      fatalError("CoreDataDBClient can manage only types which conform to CoreDataModelConvertible")
    }
    
    var result = realm.objects(realmModelType.realmClass())
    if let predicate = predicate {
      result = result.filter(predicate)
    }
    let objects = Array(result.map { realmModelType.from($0) as! T})
    
    return  Task(objects)
  }
  
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
    return Task.cancelledTask()
  }
  
  public func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T>{
//    return RealmObservable(request: request, realm: realm)
    return RequestObservable(request: request)
  }
  
}
