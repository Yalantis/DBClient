//
//  DBClientRealmTest.swift
//  DBClientTests
//
//  Created by Roman Kyrylenko on 10/23/18.
//  Copyright © 2018 Yalantis. All rights reserved.
//

import XCTest
import DBClient
import RealmSwift

class DBClientRealmTest: DBClientTest {
    
    private let client = RealmDBClient(realm: try! Realm())
    override var dbClient: DBClient! {
        return client
    }
}
