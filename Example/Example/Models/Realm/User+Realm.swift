//
//  User+Realm.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 01/06/17.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import DBClient
import RealmSwift

extension User: RealmModelConvertible {
    
    static func from(_ realmObject: Object) -> Stored {
        guard let objectUser = realmObject as? ObjectUser else {
            fatalError("Can't create `User` from \(realmObject)")
        }
        
        return User(id: objectUser.id, name: objectUser.name)
    }

    static func realmClass() -> Object.Type {
        return ObjectUser.self
    }

    func toRealmObject() -> Object {
        let user = ObjectUser()
        user.id = id
        user.name = name
        
        return user
    }

}
