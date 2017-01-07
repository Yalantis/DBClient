//
//  ManagedUser+CoreDataProperties.swift
//  YChat
//
//  Created by Roman Kyrylenko on 01/06/17.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import CoreData

extension ManagedUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedUser> {
        return NSFetchRequest<ManagedUser>(entityName: User.entityName)
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    
}
