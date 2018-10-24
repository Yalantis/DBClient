//
//  CoreDataDeleteTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
@testable import Example

final class CoreDataDeleteTests: DBClientCoreDataTest {
    
    func test_SyncSingleDeletion_WhenSuccessful_ReturnsNil() {
        let randomUser = User.createRandom()
        
        let result = dbClient.insert(randomUser)
        let removalResult = dbClient.delete(result.require())
        
        XCTAssertNotNil(removalResult.value)
    }
    
    func test_SyncBulkDeletion_WhenSuccessful_ReturnsNil() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        
        let insertionResult = dbClient.insert(randomUsers)
        let removalResult = dbClient.delete(insertionResult.require())
        
        XCTAssertNotNil(removalResult.value)
    }
    
    func test_SingleDeletion_WhenSuccessful_ReturnsNil() {
        let randomUser = User.createRandom()
        let expectationHit = expectation(description: "Object")
        var isDeleted = false
        
        dbClient.insert(randomUser) { result in
            if let object = result.value {
                self.dbClient.delete(object) { result in
                    isDeleted = result.value != nil
                    expectationHit.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(isDeleted)
        }
    }
    
    func test_BulkDeletion_WhenSuccessful_ReturnsNil() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        let expectationHit = expectation(description: "Object")
        var isDeleted = false
        
        dbClient.insert(randomUsers) { result in
            if let objects = result.value {
                self.dbClient.delete(objects) { result in
                    isDeleted = result.value != nil
                    expectationHit.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(isDeleted)
        }
    }
}
