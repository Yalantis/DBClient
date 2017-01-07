//
//  User+Realm.swift
//  YChat
//
//  Created by Roman Kyrylenko on 01/06/17.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import DBClient
import RealmSwift

extension User: RealmModelConvertible {

    /**
     Executes mapping from `Realm.Object` instance
     
     - Parameter realmObject: Object to be mapped from
     
     - Returns: Fulfilled model instance
     */
    public static func from(_ realmObject: Object) -> Stored {
        guard let objectUser = realmObject as? ObjectUser else {
            fatalError("Can't create `User` from \(realmObject)")
        }
        return User(id: objectUser.id, name: objectUser.name)
    }

    /**
     Returns type of object for model
     */
    public static func realmClass() -> Object.Type {
        return ObjectUser.self
    }

    /**
     Executes backward mapping from `Realm.Object`
     */
    public func toRealmObject() -> Object {
        let user = ObjectUser()
        user.id = id
        user.name = name
        return user
    }

}
