//
//  DBClientInjector.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 1/6/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import DBClient
import RealmSwift

private struct DBClientInjector {

    static var coreDataClient: DBClient = CoreDataDBClient(forModel: "Users")

    static var realmClient: DBClient = {
        let realm = try! Realm()
        return RealmDBClient(realm: realm)
    }()

}

protocol DBClientInjectable {}

extension DBClientInjectable {

    var dbClient: DBClient {
        get {
            return DBClientInjector.coreDataClient
//            return DBClientInjector.realmClient
        }
    }
}
