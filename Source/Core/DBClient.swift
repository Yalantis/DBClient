//
//  DBClient.swift
//  ArchitectureGuideTemplate
//
//  Created by Yury Grinenko on 03.11.16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import BoltsSwift

/**
  Protocol for transaction restrictions in `DBClient`.
  Used for transactions of all type.
*/
public protocol Stored {

  /// Primary key for an object.
  static var primaryKey: String? { get }

}

public extension Stored {

  public static var primaryKey: String? { return nil }

}

/// Describes abstract database transactions, common for all engines.
public protocol DBClient {

  /**
    Executes given request and returns result wrapped in `Task`.
    
    - Parameter request: request to execute.
    
    - Returns: task with result or error in appropriate state. 
  */
  func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]>

  /**
    Creates observable request from given `FetchRequest`.
    
    - Parameter request: fetch request to be observed
     
    - Returns: observable of for given request.
  */
  func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T>

  // TODO: remove
  func fetch<T: Stored>(id: String) -> Task<[T]>
  func fetch<T: Stored>(with predicate: NSPredicate?) -> Task<[T]>

  /**
    Saves objects to database.
    
    - Parameter objects: list of objects to be saved
     
    - Returns: `Task` with saved objects or appropriate error in case of failure.
  */
  func save<T: Stored>(_ objects: [T]) -> Task<[T]>

  /**
    Updates changed performed with objects to database.
     
    - Parameter objects: list of objects to be updated
     
    - Returns: `Task` with updated objects or appropriate error in case of failure.
  */
  func update<T: Stored>(_ objects: [T]) -> Task<[T]>

  /**
    Deletes objects from database.
     
    - Parameter objects: list of objects to be deleted
     
    - Returns: `Task` with deleted objects or appropriate error in case of failure.
  */
  func delete<T: Stored>(_ objects: [T]) -> Task<[T]>

}

public extension DBClient {

  /**
    Finds first element with given value as primary.
    If no primary key specified for given type, or object with such value doesn't exist returns nil.
     
    - Parameters:
        - type: Type of object to search for
        - primaryValue: The value of primary key field to search for
     
    - Returns: `Task` with found object or nil.
  */
  func findFirst<T: Stored>(_ type: T.Type, primaryValue: String) -> Task<T?> {
    guard let primaryKey = type.primaryKey else {
      return Task(nil)
    }
    
    let predicate = NSPredicate(format: "\(primaryKey) == %@", primaryValue)
    let request = FetchRequest<T>(predicate: predicate, fetchLimit: 1)
    if let first = execute(request).result?.first {
      return Task(first)
    }
    return Task(nil)
  }

  /**
   Deletes object from database.

   - Parameter object: object to be deleted

   - Returns: `Task` with deleted object or appropriate error in case of failure.
   */
  func delete<T: Stored>(_ object: T) -> Task<T> {
    return convertArrayTaskToSingleObject(delete([object]))
  }

  /**
   Updates changed performed with object to database.

   - Parameter object: object to be updated

   - Returns: `Task` with updated object or appropriate error in case of failure.
   */
  func update<T: Stored>(_ object: T) -> Task<T> {
    return convertArrayTaskToSingleObject(update([object]))
  }

  /**
   Saves object to database.

   - Parameter object: object to be saved

   - Returns: `Task` with saved object or appropriate error in case of failure.
   */
  func save<T: Stored>(_ object: T) -> Task<T> {
    return convertArrayTaskToSingleObject(save([object]))
  }

  private func convertArrayTaskToSingleObject<T>(_ task: Task<[T]>) -> Task<T> {
    return task.continueWithTask { task -> Task<T> in
      if let objects = task.result, let object = objects.first {
        return Task<T>(object)
      } else if let error = task.error {
        return Task<T>(error: error)
      } else { // no objects returned
        return Task<T>.cancelledTask()
      }
    }
  }

}
