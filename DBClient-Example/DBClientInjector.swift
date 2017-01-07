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

public struct DBClientInjector {

    public static var coreDataClient: DBClient = CoreDataDBClient(forModel: "Users")
    
    public static var realmClient: DBClient = {
        let realm = try! Realm()
        return RealmDBClient(realm: realm)
    }()

}

public protocol DBClientInjectable {}

extension DBClientInjectable {

    public var coreDataClient: DBClient {
        get {
            return DBClientInjector.coreDataClient
        }
    }

    public var realmClient: DBClient {
        get {
            return DBClientInjector.realmClient
        }
    }

}
