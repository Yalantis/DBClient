//
//  CoreDataDBClient.swift
//  DBClient
//
//  Created by Yury Grinenko on 03.11.16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import CoreData
import BoltsSwift

public enum ConverterMode {
    case insertNewIgnoreExisted, updateExistedIgnoreNew, updateExistedInsertNew
}

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
    func upsertManagedObject(in context: NSManagedObjectContext, existedInstance: NSManagedObject?) -> NSManagedObject
    
    
    static var entityName: String { get }
    
}

extension NSManagedObject: Stored {}

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
        guard let modelURL = self.bundle.url(forResource: self.modelName, withExtension: "momd"),
            let objectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Can't find managedObjectModel")
        }
        
        return objectModel
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
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    private lazy var rootContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        let parentContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        parentContext.persistentStoreCoordinator = coordinator
        
        return parentContext
    }()
    
    fileprivate lazy var mainContext: NSManagedObjectContext = {
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = self.rootContext
        
        return mainContext
    }()
    
    private lazy var readManagedContext: NSManagedObjectContext = {
        let fetchContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        fetchContext.parent = self.mainContext
        
        return fetchContext
    }()
    
    private lazy var writeManagedContext: NSManagedObjectContext = {
        let fetchContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        fetchContext.parent = self.mainContext
        
        return fetchContext
    }()
    
    fileprivate func performWriteTask(_ closure: @escaping (NSManagedObjectContext, (() throws -> ())) -> ()) {
        let context = writeManagedContext
        context.perform {
            closure(context) {
                try context.save()
                try self.mainContext.save()
                try self.rootContext.save()
            }
        }
    }
    
    fileprivate func performReadTask(closure: @escaping (NSManagedObjectContext) -> ()) {
        let context = readManagedContext
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
    
    @discardableResult
    fileprivate func checkType<T>(_ inputType: T) -> CoreDataModelConvertible.Type {
        switch inputType {
        case let type as CoreDataModelConvertible.Type:
            return type

        default:
            let model = String(describing: CoreDataDBClient.self)
            let prot = String(describing: CoreDataModelConvertible.self)
            let given = String(describing: inputType)
            fatalError("`\(model)` can manage only types which conform to `\(prot)`. `\(given)` given.")
        }
    }
    
    public func observable<T: Stored>(for request: FetchRequest<T>) -> RequestObservable<T> {
        return CoreDataObservable(request: request, context: mainContext)
    }
    
    public func execute<T: Stored>(_ request: FetchRequest<T>) -> Task<[T]> {
        let coreDataModelType = checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        
        performReadTask { context in
            let fetchRequest = self.fetchRequest(for: coreDataModelType)
            fetchRequest.predicate = request.predicate
            fetchRequest.sortDescriptors = [request.sortDescriptor].flatMap { $0 }
            fetchRequest.fetchLimit = request.fetchLimit
            fetchRequest.fetchOffset = request.fetchOffset
            do {
                let result = try context.fetch(fetchRequest) as! [NSManagedObject]
                let resultModels = result.flatMap { coreDataModelType.from($0) as? T }
                taskCompletionSource.set(result: resultModels)
            } catch let error {
                taskCompletionSource.set(error: error)
            }
        }
        
        return taskCompletionSource.task
    }
    
    /// Insert given objects into context and save it
    ///
    /// If appropriate object already exists in DB it will be ignored and nothing will be inserted
    public func insert<T: Stored>(_ objects: [T]) -> Task<[T]> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        performWriteTask { context, savingClosure in
            var insertedObjects = [T]()
            objects.forEach { object in
                if self.find(objects: [object], in: context)?.first != nil {
                    return
                }
                
                let convertedObject = self.convert(objects: [object])[0]
                let managedObject = convertedObject.upsertManagedObject(in: context, existedInstance: nil)
                insertedObjects.append(object)
            }
            
            do {
                try savingClosure()
                taskCompletionSource.set(result: insertedObjects)
            } catch let error {
                taskCompletionSource.set(error: error)
            }
        }
        return taskCompletionSource.task
    }
    
    /// Method to update existed in DB objects
    /// if there is no such object in db nothing will happened
    public func update<T: Stored>(_ objects: [T]) -> Task<[T]> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<[T]>()
        performWriteTask { context, savingClosure in
            var updatedObjects = [T]()
            
            for object in objects {
                guard let storedObject = self.find(objects: [object], in: context)?.first else {
                    continue
                }
                
                let convertedObject = self.convert(objects: [object])[0]
                convertedObject.upsertManagedObject(in: context, existedInstance: storedObject)
                updatedObjects.append(object)
            }
            
            do {
                try savingClosure()
                taskCompletionSource.set(result: updatedObjects)
            } catch let error {
                taskCompletionSource.set(error: error)
            }
        }
        return taskCompletionSource.task
    }
    
    /// Update object if it exists or insert new one otherwise
    public func upsert<T: Stored>(_ objects: [T]) -> Task<(updated: [T], inserted: [T])> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<(updated: [T], inserted: [T])>()
        performWriteTask { context, savingClosure in
            var updatedObjects = [T]()
            var insertedObjects = [T]()
            
            for object in objects {
                let storedObject: NSManagedObject? = self.find(objects: [object], in: context)?.first
                let convertedObject = self.convert(objects: [object])[0]
                convertedObject.upsertManagedObject(in: context, existedInstance: storedObject)
                if storedObject == nil {
                    insertedObjects.append(object)
                } else {
                    updatedObjects.append(object)
                }
            }
            
            do {
                try savingClosure()
                taskCompletionSource.set(result: (updated: updatedObjects, inserted: insertedObjects))
            } catch let error {
                taskCompletionSource.set(error: error)
            }
        }
        
        return taskCompletionSource.task
    }
    
    /// For each element in collection:
    /// After all deletes try to save context
    public func delete<T: Stored>(_ objects: [T]) -> Task<Void> {
        checkType(T)
        
        let taskCompletionSource = TaskCompletionSource<Void>()
        performWriteTask { context, savingClosure in
            guard let foundObjects = self.find(objects: objects, in: context) else {
                taskCompletionSource.set(result: ())
                return
            }
            
            foundObjects.forEach { context.delete($0) }
            
            do {
                try savingClosure()
                taskCompletionSource.set(result: ())
            } catch let error {
                taskCompletionSource.set(error: error)
            }
        }
        
        return taskCompletionSource.task
    }
    
}

private extension CoreDataDBClient {
    
    func find<T: Stored>(objects: [T], in context: NSManagedObjectContext) -> [NSManagedObject]? {
        let coreDataModelType = checkType(T)
        guard let primaryKeyName = T.primaryKeyName else {
            return nil
        }
        
        let ids = objects.flatMap { $0.valueOfPrimaryKey }
        let fetchRequest = self.fetchRequest(for: coreDataModelType)
        fetchRequest.predicate = NSPredicate(format: "\(primaryKeyName) IN %@", ids)
        guard let result = try? context.fetch(fetchRequest) as? [NSManagedObject] else {
            return nil
        }
        
        return result
    }
    
    func convert<T: Stored>(objects: [T]) -> [CoreDataModelConvertible] {
        checkType(T)
        
        return objects.flatMap { $0 as? CoreDataModelConvertible }
    }
    
}
