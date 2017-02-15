//
//  FetchTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import BoltsSwift
import XCTest
@testable import Example

class FetchTests: DBClientTest {
    
    func testSingleFetch() {
        let user = createRandomUser()
        // check if it has been successfully saved
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: user.id)
                .continueOnSuccessWith { fetchedUser in
                    XCTAssertEqual(user, fetchedUser)
                    expectation.fulfill()
            }
        }
    }
    
    func testBulkFetch() {
        let randomUsers: [User] = createRandomUsers(10).sorted()
        
        // check if generated users have been successfully saved
        let request: Task<[User]> = dbClient.fetchAll()
        execute { expectation in
            request
                .continueOnSuccessWith { fetchedUsers in
                    // use sort to match users order
                    XCTAssert(randomUsers == fetchedUsers.sorted())
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testAsyncFetches() {
        let randomUsers: [User] = createRandomUsers(100)
        let userIds: [String] = randomUsers.map { $0.id }
        var tasks: [Task<User?>] = []
        
        // async fetch them
        execute { expectation in
            for userId in userIds {
                tasks.append(self.dbClient.findFirst(User.self, primaryValue: userId))
            }
            Task.whenAll(tasks)
                .continueOnSuccessWith { 
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}
