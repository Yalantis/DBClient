//
//  CoreDataMigrationManager.swift
//  DBClient
//
//  Created by Roman Kyrylenko on 2/17/17.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import CoreData
import Foundation

final class CoreDataMigrationManager: NSObject, MigrationManager {
    
    weak var delegate: MigrationManagerDelegate? = nil
    var bundle: Bundle = .main
    
    func progressivelyMigrate(sourceStoreURL: URL, of type: String, to finalModel: NSManagedObjectModel) throws {
        let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: type,
            at: sourceStoreURL,
            options: nil
        )
        if finalModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) {
            return
        }
        guard let sourceModel = self.sourceModel(for: sourceMetadata) else {
            throw MigrationError.modelsNotFound
        }
        
        let data = try getDestinationModel(for: sourceModel)
        let destinationModel = data.0
        let mappingModel = data.1
        let modelName = data.2
        let mappingModels: [NSMappingModel]
        if let explicitMappingModels = delegate?.migrationManager(self, mappingModelsForSourceModel: sourceModel),
            !explicitMappingModels.isEmpty {
            mappingModels = explicitMappingModels
        } else {
            mappingModels = [mappingModel]
        }
        let destinationStoreURL = self.destinationStoreURL(with: sourceStoreURL, modelName: modelName)
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        manager.addObserver(self, forKeyPath: #keyPath(NSMigrationManager.migrationProgress), options: .new, context: nil)
        var migrated = false
        for mappingModel in mappingModels {
            do {
                try manager.migrateStore(
                    from: sourceStoreURL,
                    sourceType: type,
                    options: nil,
                    with: mappingModel,
                    toDestinationURL: destinationStoreURL,
                    destinationType: type,
                    destinationOptions: nil
                )
                migrated = true
            } catch {
                migrated = false
            }
        }
        manager.removeObserver(self, forKeyPath: #keyPath(NSMigrationManager.migrationProgress))
        
        if !migrated {
            return
        }
        // Migration was successful, move the files around to preserve the source in case things go bad
        try backup(sourceStoreAtURL: sourceStoreURL, movingDestinationStoreAtURL: destinationStoreURL)
        // We may not be at the "current" model yet, so recurse
        try self.progressivelyMigrate(sourceStoreURL: sourceStoreURL, of: type, to: finalModel)
    }
    
    func modelPaths() -> [String] {
        // Find all of the mom and momd files in the Resources directory
        var modelPaths: [String] = []
        let momdArray = bundle.paths(forResourcesOfType: "momd", inDirectory: nil)
        for path in momdArray {
            let resourceSubpath = (path as NSString).lastPathComponent
            let array = bundle.paths(forResourcesOfType: "mom", inDirectory: resourceSubpath)
            modelPaths.append(contentsOf: array)
        }
        let otherModels = bundle.paths(forResourcesOfType: "mom", inDirectory: nil)
        modelPaths.append(contentsOf: otherModels)

        return modelPaths
    }
    
    func sourceModel(for sourceMetadata: [String: Any]) -> NSManagedObjectModel? {
        return NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: sourceMetadata)
    }
    
    func getDestinationModel(for sourceModel: NSManagedObjectModel) throws -> (NSManagedObjectModel, NSMappingModel, String) {
        let modelPaths = self.modelPaths()
        if modelPaths.isEmpty {
            throw MigrationError.modelsNotFound
        }
        // See if we can find a matching destination model
        var model: NSManagedObjectModel? = nil
        var mapping: NSMappingModel? = nil
        var modelURL: URL? = nil
        for modelPath in modelPaths {
            let mURL = URL(fileURLWithPath: modelPath)
            modelURL = mURL
            model = NSManagedObjectModel(contentsOf: mURL)
            mapping = NSMappingModel(from: [bundle], forSourceModel: sourceModel, destinationModel: model)
            // If we found a mapping model then proceed
            if mapping != nil {
                break
            }
        }
        // We have tested every model, if nil here we failed
        if mapping == nil || mapping == nil || modelURL == nil {
            throw MigrationError.mappingModelNotFound
        }
        
        return (model!, mapping!, (modelURL!.lastPathComponent as NSString).deletingPathExtension)
    }
    
    func destinationStoreURL(with sourceStoreURL: URL, modelName: String) -> URL {
        // We have a mapping model, time to migrate
        let storeExtension = sourceStoreURL.pathExtension
        var storePath = sourceStoreURL.deletingPathExtension().path
        // Build a path to write the new store
        storePath = "\(storePath).\(modelName).\(storeExtension)"
        
        return URL(fileURLWithPath: storePath)
    }
    
    func backup(sourceStoreAtURL: URL, movingDestinationStoreAtURL: URL) throws {
        let guid = ProcessInfo.processInfo.globallyUniqueString
        let backupPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(guid)
        let fileManager = FileManager.default
        try fileManager.moveItem(at: sourceStoreAtURL, to: backupPath)
        // Move the destination to the source path
        do {
            try fileManager.moveItem(at: movingDestinationStoreAtURL, to: sourceStoreAtURL)
        } catch {
            // Try to back out the source move first, no point in checking it for errors
            try fileManager.moveItem(at: backupPath, to: sourceStoreAtURL)
            throw error
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "migrationProgress", let object = object as? NSMigrationManager {
            delegate?.migrationManager(self, updateMigrationProgress: object.migrationProgress)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
}
