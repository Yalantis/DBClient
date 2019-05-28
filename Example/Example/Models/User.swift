//
//  User.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 1/6/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import DBClient

class User {
    
    var name: String
    var id: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    func mutate() {
        name = String(name.reversed())
    }
}

extension User: Stored {

    public static var primaryKeyName: String? {
        return "id"
    }
    
    public var valueOfPrimaryKey: CVarArg? {
        return id
    }
}

extension User {
    
    static func createRandom() -> User {
        let id = arc4random()
        let user = User(id: "\(id)", name: "User #\(id)")
        
        return user
    }
}
