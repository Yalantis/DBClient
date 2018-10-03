//
//  ManagedUser+CoreDataProperties.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 01/06/17.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import CoreData

extension ManagedUser {

    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ManagedUser> {
        return NSFetchRequest<ManagedUser>(entityName: User.entityName)
    }

    @NSManaged var id: String?
    @NSManaged var name: String?
    
}
