//
//  ObjectUser.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 1/6/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import RealmSwift

class ObjectUser: Object {

    override class func primaryKey() -> String? {
        return #keyPath(ObjectUser.id)
    }

    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""

}
