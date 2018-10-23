//
//  RealmCreateTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
@testable import Example

final class RealmCreateTests: DBClientRealmTest {
    
    func test_SingleInsertion_WhenSuccessful_ReturnsObject() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Object")
        var expectedObject: User?
        
        self.dbClient.insert(randomUser) { result in
            expectedObject = result.value
            expectationObject.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNotNil(expectedObject)
        }
    }
    
    func test_BulkInsertion_WhenSuccessful_ReturnsBulk() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }

        let expectationObjects = expectation(description: "Objects")
        var expectedObjectsCount = 0

        self.dbClient.insert(randomUsers) { result in
            expectedObjectsCount = result.value?.count ?? 0
            expectationObjects.fulfill()
        }

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedObjectsCount, randomUsers.count)
        }
    }

}
