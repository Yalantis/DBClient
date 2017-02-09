//
//  CoreDataTest.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import DBClient
import BoltsSwift
@testable import Example

class CoreDataTest: DBClientTest {
    
    var dbClient: CoreDataDBClient = CoreDataDBClient(forModel: "Users")
    
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
        print("[CoreDataTest]: Cleaning database")
        let request: Task<[User]> = dbClient.fetchAll()
        execute { (expectation) in
            request
                .continueOnSuccessWithTask { users -> Task<[User]> in
                    return self.dbClient.delete(users)
                }
                .continueOnSuccessWith { objects in
                    print("[CoreDataTest]: Removed \(objects.count) objects")
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}
