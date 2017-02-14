//
//  DBClient.swift
//  DBClient
//
//  Created by Yury Grinenko on 03.11.16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import BoltsSwift

/// Protocol for transaction restrictions in `DBClient`.
/// Used for transactions of all type.
public protocol Stored {
    
    /// Primary key for an object.
    static var primaryKeyName: String? { get }
    
    /// Primary value for an instance
    var valueOfPrimaryKey: CVarArg? { get }
    
}

public extension Stored {
    
    static var primaryKeyName: String? { return nil }
    
    var valueOfPrimaryKey: CVarArg? { return nil }
    
}

/// Describes abstract database transactions, common for all engines.
public protocol DBClient {
    
    /// Executes given request and returns result wrapped in `Task`.
    ///
    /// - Parameter request: request to execute
    /// - Returns: `Task` with array of objects or error in case of failude.
    func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]>
    
    /// Creates observable request from given `FetchRequest`.
    ///
    /// - Parameter request: fetch request to be observed
    /// - Returns: observable of for given request.
    func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T>
    
    /// Inserts objects to database.
    ///
    /// - Parameter objects: list of objects to be inserted
    /// - Returns: `Task` with inserted objects or appropriate error in case of failure.
    @discardableResult
    func insert<T: Stored>(_ objects: [T]) -> Task<[T]>
    
    /// Updates changed performed with objects to database.
    ///
    /// - Parameter objects: list of objects to be updated
    /// - Returns: `Task` with updated objects or appropriate error in case of failure.
    @discardableResult
    func update<T: Stored>(_ objects: [T]) -> Task<[T]>
    
    /// Deletes objects from database.
    ///
    /// - Parameter objects: list of objects to be deleted
    /// - Returns: `Task` with appropriate error in case of failure.
    @discardableResult
    func delete<T: Stored>(_ objects: [T]) -> Task<Void>
    
    /// Iterates through given objects and updates existing in database instances or creates them
    ///
    /// - Parameter objects: objects to be worked with
    /// - Returns: A `Task` with inserted and updated instances
    @discardableResult
    func upsert<T : Stored>(_ objects: [T]) -> Task<(updated: [T], inserted: [T])>
    
}

public extension DBClient {
    
    /// Fetch all entities from database
    ///
    /// - Returns: Task with array of objects
    func fetchAll<T: Stored>() -> Task<[T]> {
        return execute(FetchRequest())
    }
    
    /// Finds first element with given value as primary.
    /// If no primary key specified for given type, or object with such value doesn't exist returns nil.
    ///
    /// - Parameters:
    ///   - type: type of object to search for
    ///   - primaryValue: the value of primary key field to search for
    ///   - predicate: predicate for request
    /// - Returns: `Task` with found object or nil.
    func findFirst<T: Stored>(_ type: T.Type, primaryValue: String, predicate: NSPredicate? = nil) -> Task<T?> {
        guard let primaryKey = type.primaryKeyName else {
            return Task(nil)
        }
        
        let primaryKeyPredicate = NSPredicate(format: "\(primaryKey) == %@", primaryValue)
        let fetchPredicate: NSPredicate
        if let predicate = predicate {
            fetchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [primaryKeyPredicate, predicate])
        } else {
            fetchPredicate = primaryKeyPredicate
        }
        let request = FetchRequest<T>(predicate: fetchPredicate, fetchLimit: 1)
        
        return execute(request).continueWithTask { task -> Task<T?> in
            return Task(task.result?.first)
        }
    }
    
    /// Inserts object to database.
    ///
    /// - Parameter object: object to be inserted
    /// - Returns: `Task` with inserted object or appropriate error in case of failure.
    @discardableResult func insert<T: Stored>(_ object: T) -> Task<T> {
        return convertArrayTaskToSingleObject(insert([object]))
    }
    
    /// Updates changed performed with object to database.
    ///
    /// - Parameter object: object to be updated
    /// - Returns: `Task` with updated object or appropriate error in case of failure.
    @discardableResult func update<T: Stored>(_ object: T) -> Task<T> {
        return convertArrayTaskToSingleObject(update([object]))
    }
    
    /// Deletes object from database.
    ///
    /// - Parameter object: object to be deleted
    /// - Returns: `Task` with appropriate error in case of failure.
    @discardableResult func delete<T: Stored>(_ object: T) -> Task<Void> {
        return delete([object])
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
