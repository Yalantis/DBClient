//
//  UpsertTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/15/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class UpsertTests: DBClientTest {
    
    func testUpsert() {
        let savedUsers = createRandomUsers(10)
        let newUsers: [User] = (0...5).map { _ in User.createRandom() }
        var combinedUsers = savedUsers
        combinedUsers.append(contentsOf: newUsers)
        
        execute { expectation in
            self.dbClient
                .upsert(combinedUsers)
                .continueOnSuccessWith { upsertions in
                    XCTAssertEqual(savedUsers.sorted(), upsertions.updated.sorted())
                    XCTAssertEqual(newUsers.sorted(), upsertions.inserted.sorted())
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}
