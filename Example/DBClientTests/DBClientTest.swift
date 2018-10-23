//
//  DBClientTest.swift
//  DBClientTests
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import DBClient
import RealmSwift
@testable import Example

enum StorageType {
    
    case realm
    case coreData
}

let storageType: StorageType = .coreData

class DBClientTest: XCTestCase {
    
    var dbClient: DBClient!
    
    override func setUp() {
        super.setUp()
        
        switch storageType {
        case .realm:
            let realm = try! Realm()
            dbClient = RealmDBClient(realm: realm)
            
        case .coreData:
            dbClient = CoreDataDBClient(forModel: "Users")
        }
        cleanUpDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
        
        cleanUpDatabase()
    }
    
    // removes all objects from the database
    func cleanUpDatabase() {
        let expectationDeleletion = expectation(description: "Deletion")
        var isDeleted = false
        
        dbClient.findAll { (result: Result<[User]>) in
            guard let objects = result.value else {
                expectationDeleletion.fulfill()
                return
            }
            self.dbClient.delete(objects) { _ in
                isDeleted = true
                expectationDeleletion.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(isDeleted)
        }
    }
}
