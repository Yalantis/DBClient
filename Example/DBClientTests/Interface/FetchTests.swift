//
//  FetchTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import XCTest
import DBClient
@testable import Example

class FetchTests: DBClientTest {
    
    func test_SingleFetch_WhenSuccessful_ReturnsObject() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Object")
        var expectedObject: User?
        
        self.dbClient.insert(randomUser, completion: { result in
            self.dbClient.findFirst(User.self, primaryValue: randomUser.id, completion: { result in
                expectedObject = result.require()
                expectationObject.fulfill()
            })
        })
        
        waitForExpectations(timeout: 5) { _ in
            XCTAssertNotNil(expectedObject)
        }
    }
    
    func test_BulkFetch_WhenSuccessful_ReturnsBulk() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        
        let expectationObjects = expectation(description: "Objects")
        var expectedObjectsCount = 0
        
        self.dbClient.insert(randomUsers, completion: { result in
            self.dbClient.findAll { (result: Result<[User]>) in
                expectedObjectsCount = result.value?.count ?? 0
                expectationObjects.fulfill()
            }
        })
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedObjectsCount, randomUsers.count)
        }
    }
    
}
