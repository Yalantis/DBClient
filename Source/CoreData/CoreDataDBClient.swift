//
//  CoreDataDBClient.swift
//  ArchitectureGuideTemplate
//
//  Created by Yury Grinenko on 03.11.16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import CoreData
import BoltsSwift

/**
  Describes type of model for CoreData database client.
  Model should conform to CoreDataModelConvertible protocol
  for ability to be fetched/saved/updated/deleted in CoreData
*/
public protocol CoreDataModelConvertible: Stored {

  /**
    Returns type of object for model.
  */
  static func managedObjectClass() -> NSManagedObject.Type

  /**
    Executes mapping from `NSManagedObject` instance.
    
    - Parameter managedObject: Object to be mapped from
     
    - Returns: Mapped object.
  */
  static func from(_ managedObject: NSManagedObject) -> Stored

  /**
    Executes backward mapping to `NSManagedObject` from given context
     
    - Parameter context: Context, where object should be created.
     
    - Returns: Created instance
  */
  func toManagedObject(in context: NSManagedObjectContext) -> NSManagedObject

  static var entityName: String { get }
  
}

extension NSManagedObject: Stored {}

// TODO: If it is possible, need some way to avoid calling DBClient functions with objects
// which don't conform to CoreDataModelConvertible protocol - generate compile time error

/** 
  Implementation of database client for CoreData storage type.
*/
public class CoreDataDBClient {

  private var modelName: String
  private var bundle: Bundle

  public init(forModel modelName: String = "CoreData", in bundle: Bundle = Bundle.main) {
    self.modelName = modelName
    self.bundle = bundle
  }

  // MARK: - CoreData stack

  fileprivate lazy var applicationDocumentsDirectory: URL = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.count - 1]
  }()

  fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = self.bundle.url(forResource: self.modelName, withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()

  fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.appendingPathComponent("\(self.modelName).sqlite")
    do {
      try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    } catch {
      var dict = [String: AnyObject]()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
      var failureReason = "There was an error creating or loading the application's saved data."
      dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

      dict[NSUnderlyingErrorKey] = error as NSError
      let wrappedError = NSError(domain: "com.Yalantis.DBClient", code: 9999, userInfo: dict)
      NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
      abort()
    }

    return coordinator
  }()

  fileprivate lazy var managedObjectContext: NSManagedObjectContext = {
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()

  fileprivate func performBackgroundTask(closure: @escaping (NSManagedObjectContext) -> Void) {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.parent = managedObjectContext
    context.perform {
      closure(context)
    }
  }

  fileprivate func fetchRequest(for entity: CoreDataModelConvertible.Type) -> NSFetchRequest<NSFetchRequestResult> {
    return NSFetchRequest(entityName: entity.entityName)
  }
  
}

// MARK: - DBClient methods

extension CoreDataDBClient: DBClient {
  
  public func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]> {
    guard let coreDataModelType = T.self as? CoreDataModelConvertible.Type else {
      fatalError("CoreDataDBClient can manage only types which conform to CoreDataModelConvertible")
    }
    
    let taskCompletionSource = TaskCompletionSource<[T]>()
    
    performBackgroundTask { context in
      let fetchRequest = self.fetchRequest(for: coreDataModelType)
      fetchRequest.predicate = request.predicate
      fetchRequest.sortDescriptors = [request.sortDescriptor].flatMap { $0 }
      fetchRequest.fetchLimit = request.fetchLimit
      fetchRequest.fetchOffset = request.fetchOffset
      do {
        let result = try context.fetch(fetchRequest) as! [NSManagedObject]
        let resultModels = result.map { coreDataModelType.from($0) as! T }
        taskCompletionSource.set(result: resultModels)
      } catch let error {
        taskCompletionSource.set(error: error)
      }
    }

    return taskCompletionSource.task
  }

  public func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T> {
    return CoreDataObservable(request: request, context: managedObjectContext)
  }
  
  public func save<T: Stored>(_ objects: [T]) -> Task<[T]> {
    // For each element in collection:
    // 1. Cast T object to CoreDataModelConvertible if it is possible
    // 2. Convert CoreDataModelConvertible object to CoreData object in given context
    // After all inserts/updates try to save context
    
    let taskCompletionSource = TaskCompletionSource<[T]>()
    performBackgroundTask { context in
      for object in objects {
        if let coreDataConvertibleObject = object as? CoreDataModelConvertible {
          let _ = coreDataConvertibleObject.toManagedObject(in: context)
        }
      }
      do {
        try context.save()
        taskCompletionSource.set(result: objects)
      } catch let error {
        taskCompletionSource.set(error: error)
      }
    }
    return taskCompletionSource.task
  }
  
  public func update<T: Stored>(_ objects: [T]) -> Task<[T]> {
    // For each element in collection:
    // 1. Cast T object to CoreDataModelConvertible if it is possible
    // 2. Convert CoreDataModelConvertible object to CoreData object in given context
    // After all inserts/updates try to save context

    // The same logic as for Save actions
    return save(objects)
  }
  
  public func delete<T: Stored>(_ objects: [T]) -> Task<[T]> {
    // For each element in collection:
    // 1. Cast T object to CoreDataModelConvertible if it is possible
    // 2. Convert CoreDataModelConvertible object to CoreData object in given context
    // 3. Delete CoreData object from context
    // After all deletes try to save context

    let taskCompletionSource = TaskCompletionSource<[T]>()
    performBackgroundTask { context in
      for object in objects {
        if let coreDataConvertibleObject = object as? CoreDataModelConvertible {
          let coreDataObject = coreDataConvertibleObject.toManagedObject(in: context)
          context.delete(coreDataObject)
        }
      }
      do {
        try context.save()
        taskCompletionSource.set(result: objects)
      } catch let error {
        taskCompletionSource.set(error: error)
      }
    }
    return taskCompletionSource.task
  }

}
