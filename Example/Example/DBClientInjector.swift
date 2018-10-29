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
    
    static let coreDataClient: DBClient = CoreDataDBClient(forModel: "Users")
    static let realmClient: DBClient = RealmDBClient(realm: try! Realm())
}

protocol DBClientInjectable {}

extension DBClientInjectable {
    
    var dbClient: DBClient {
        //            return DBClientInjector.coreDataClient
        return DBClientInjector.realmClient
    }
}
