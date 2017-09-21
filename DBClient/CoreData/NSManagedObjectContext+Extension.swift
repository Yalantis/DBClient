//
//  NSManagedObjectContext+Extension.swift
//  DBClient
//
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    func save(includingParent: Bool) throws {
        guard hasChanges else {
            return
        }
        
        try save()
        
        if includingParent, let parent = parent {
            try parent.safePerformAndWait {
                try parent.save(includingParent: true)
            }
        }
    }
    
    func safePerformAndWait(_ block:  @escaping () throws -> Void) throws {
        var outError: Error?
        
        performAndWait {
            do {
                try block()
            } catch {
                outError = error
            }
        }
        
        // fake rethrowing
        if let outError = outError {
            throw outError
        }
    }
    
}
