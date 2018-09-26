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

let storageType: StorageType = .realm

class DBClientTest: XCTestCase {
    
    lazy var dbClient: DBClient = {
        switch storageType {
        case .realm:
            let realm = try! Realm()
            return RealmDBClient(realm: realm)
            
        case .coreData:
            return CoreDataDBClient(forModel: "Users")
        }
    }()
    
    override func setUp() {
        super.setUp()
        
        cleanUpDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
        
        cleanUpDatabase()
    }
    
    // removes all objects from the database
    func cleanUpDatabase() {
        print("[DBClientTest]: Cleaning database")
        let expectationDeleletion = expectation(description: "Deletion")
        var isDeleted = false
        
        dbClient.findAll { (result: Result<[User]>) in
            if let objects = result.value {
                self.dbClient.delete(objects, completion: { result in
                    isDeleted = true
                    expectationDeleletion.fulfill()
                })
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(isDeleted)
        }
    }
    
}
