//
//  User+CoreData.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 01/06/17.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import DBClient
import CoreData

extension User: CoreDataModelConvertible {
    
    public static var entityName: String {
        return String(describing: self)
    }
    
    public static func managedObjectClass() -> NSManagedObject.Type {
        return ManagedUser.self
    }
    
    public func upsertManagedObject(in context: NSManagedObjectContext, existedInstance: NSManagedObject?) -> NSManagedObject {
        var user: ManagedUser
        if let result = existedInstance as? ManagedUser { // fetch existing
            user = result
        } else { // or create new
            user = NSEntityDescription.insertNewObject(
                forEntityName: User.entityName,
                into: context
                ) as! ManagedUser
        }
        user.id = id
        user.name = name
        
        return user
    }
    
    public static func from(_ managedObject: NSManagedObject) -> Stored {
        guard let managedUser = managedObject as? ManagedUser else {
            fatalError("can't create User object from object \(managedObject)")
        }
        guard let id = managedUser.id,
            let name = managedUser.name else {
                fatalError("can't get required properties for user \(managedObject)")
        }
        
        return User(id: id, name: name)
    }
    
    func isPrimaryValueEqualTo(value: Any) -> Bool {
        if let value = value as? String {
            return value == id
        }
        
        return false
    }
    
}
