//
//  RealmUpsertTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/15/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
@testable import Example

final class RealmUpsertTests: DBClientRealmTest {
    
    func test_UpsertUsers_WhenSuccessful_ReturnsUpsertedUsers() {
        let newUsers: [User] = (0...5).map { _ in User.createRandom() }
        let savedUsers: [User] = (0...5).map { _ in User.createRandom() }
        let expectationObjects = expectation(description: "Object")
        var expectedUsers = [User]()
        let combinedUsers = savedUsers + newUsers
        
        self.dbClient.insert(savedUsers) { _ in
            self.dbClient.upsert(combinedUsers) { result in
                expectedUsers = result.require().updated + result.require().inserted
                expectationObjects.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedUsers, combinedUsers)
        }
    }
    
}
