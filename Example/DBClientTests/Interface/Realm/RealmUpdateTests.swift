//
//  RealmUpdateTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
@testable import Example

final class RealmUpdateTests: DBClientRealmTest {
    
    func test_UpdateUserName_WhenSuccessful_SetsCorrectName() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Object")
        var expectedUser: User?
        
        self.dbClient.insert(randomUser) { result in
            randomUser.name = "Bob"
            self.dbClient.update(randomUser) { result in
                expectedUser = result.value
                expectationObject.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedUser?.name, "Bob")
        }
    }

}
