//
//  CoreDataFetchTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import XCTest
import DBClient
@testable import Example

class CoreDataFetchTests: DBClientCoreDataTest {
    
    func test_SyncFetch_WhenSuccessful_ReturnObject() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Inserting object")
        
        self.dbClient.insert(randomUser) { _ in expectationObject.fulfill() }
        
        waitForExpectations(timeout: 1) { _ in
            let result = self.dbClient.execute(FetchRequest<User>(predicate: NSPredicate(format: "id == %@", randomUser.id)))
            XCTAssertEqual(result.require().count, 1)
            let object = result.require().first
            XCTAssertEqual(object, randomUser)
        }
    }
    
    func test_SingleFetch_WhenSuccessful_ReturnsObject() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Object")
        var expectedObject: User?
        
        self.dbClient.insert(randomUser) { result in
            self.dbClient.findFirst(User.self, primaryValue: randomUser.id) { result in
                expectedObject = result.require()
                expectationObject.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5) { _ in
            XCTAssertNotNil(expectedObject)
        }
    }
    
    func test_BulkFetch_WhenSuccessful_ReturnsBulk() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        
        let expectationObjects = expectation(description: "Objects")
        var expectedObjectsCount = 0
        
        self.dbClient.insert(randomUsers) { result in
            self.dbClient.findAll { (result: Result<[User]>) in
                expectedObjectsCount = result.value?.count ?? 0
                expectationObjects.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedObjectsCount, randomUsers.count)
        }
    }
}
