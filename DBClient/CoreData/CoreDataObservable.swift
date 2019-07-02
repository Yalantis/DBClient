//
//  CoreDataObservable.swift
//  DBClient
//
//  Created by Serhii Butenko on 15/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import CoreData

class CoreDataObservable<T: Stored, U: NSManagedObject>: RequestObservable<T> {
    
    var observer: ((ObservableChange<T>) -> Void)?
    
    let fetchRequest: NSFetchRequest<U>
    let fetchedResultsController: NSFetchedResultsController<U>
    
    private let fetchedResultsControllerDelegate: FetchedResultsControllerDelegate<U>
    
    init(request: FetchRequest<T>, context: NSManagedObjectContext) {
        guard let coreDataModelType = T.self as? CoreDataModelConvertible.Type else {
            fatalError("CoreDataDBClient can manage only types which conform to CoreDataModelConvertible")
        }
        
        fetchRequest = {
            let fetchRequest = NSFetchRequest<U>(entityName: coreDataModelType.entityName)
            if let predicate = request.predicate {
                fetchRequest.predicate = predicate
            }
            if let sortDescriptors = request.sortDescriptors {
                fetchRequest.sortDescriptors = sortDescriptors
            } else {
                guard let primaryKeyName = coreDataModelType.primaryKeyName else {
                    fatalError("Fetch request shoud have sortDescriptor or core data model need implement primaryKeyName")
                }
                let defaultSortDescriptor = NSSortDescriptor(key: primaryKeyName, ascending: true)
                fetchRequest.sortDescriptors = [defaultSortDescriptor]
            }
            fetchRequest.fetchLimit = request.fetchLimit
            fetchRequest.fetchOffset = request.fetchOffset
            
            return fetchRequest
        }()
        
        fetchedResultsControllerDelegate = FetchedResultsControllerDelegate()
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = fetchedResultsControllerDelegate
        
        super.init(request: request)
    }
    
    override func observe(_ closure: @escaping (ObservableChange<T>) -> Void) {
        assert(observer == nil, "Observable can be observed only once")
        
        guard let coreDataModelType = T.self as? CoreDataModelConvertible.Type else {
            fatalError("CoreDataDBClient can manage only types which conform to CoreDataModelConvertible")
        }
        
        do {
            let initial = try fetchedResultsController.managedObjectContext.fetch(fetchRequest)
            let mapped = initial.map { coreDataModelType.from($0) as! T }
            closure(.initial(mapped))
            observer = closure
            
            fetchedResultsControllerDelegate.observer = { [unowned self] (change: ObservableChange<U>) in
                guard case .change(let change) = change else { return }
                let mappedInsertions = change.insertions.map { ($0, coreDataModelType.from($1) as! T) }
                let mappedModifications = change.modifications.map { ($0, coreDataModelType.from($1) as! T) }
                let mappedObjects = change.objects.map { coreDataModelType.from($0) as! T }
                let mappedChange: ObservableChange<T>.ModelChange = (
                    objects: mappedObjects,
                    deletions: change.deletions,
                    insertions: mappedInsertions,
                    modifications: mappedModifications
                )
                self.observer?(.change(mappedChange))
            }
            
            try fetchedResultsController.performFetch()
        } catch let error {
            closure(.error(error))
        }
    }
    
}

/// A separate class to avoid inherintace from NSObject
private class FetchedResultsControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    var observer: ((ObservableChange<T>) -> Void)?
    private var batchChanges: [CoreDataChange<T>] = []
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let object = anObject as? T else {
            return
        }
        
        switch type {
        case .delete:
            batchChanges.append(.delete(indexPath!.row, object))
            
        case .insert:
            batchChanges.append(.insert(newIndexPath!.row, object))
            
        case .update, .move:
            batchChanges.append(.update(indexPath!.row, object))
            
        @unknown
        default:
            assertionFailure("trying to handle unknown case \(type)")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        batchChanges = []
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let deleted: [Int] = batchChanges.filter { $0.isDeletion }.map { $0.index() }
        let inserted: [(index: Int, element: T)] = batchChanges.filter { $0.isInsertion }.map { (index: $0.index(), element: $0.object()) }
        let updated: [(index: Int, element: T)] = batchChanges.filter { $0.isUpdate }.map { (index: $0.index(), element: $0.object()) }
        let objects: [T] = controller.fetchedObjects as? [T] ?? []
        let mappedChange: ObservableChange<T>.ModelChange = (
            objects: objects,
            deletions: deleted,
            insertions: inserted,
            modifications: updated
        )
        if let observer = observer {
            observer(.change(mappedChange))
        }
        batchChanges = []
    }
    
}
