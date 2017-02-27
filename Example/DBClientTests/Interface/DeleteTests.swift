//
//  DeleteTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class DeleteTests: DBClientTest {
    
    func testSingleDeletion() {
        let randomUser = createRandomUser()
        // remove user from db
        execute { expectation in
            self.dbClient
                .delete(randomUser)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // check if it has been removed
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: randomUser.id)
                .continueOnSuccessWith { user in
                    XCTAssert(user == nil)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testBulkDeletions() {
        let randomUsers: [User] = createRandomUsers(100)
        // remove users from db
        execute { expectation in
            self.dbClient
                .delete(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // check if they have been removed
        execute { expectation in
            let request: Task<[User]> = self.dbClient.findAll()
            request
                .continueOnSuccessWith { users in
                    XCTAssert(users.isEmpty)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testAsyncDeletions() {
        let randomUsers: [User] = createRandomUsers(100)
        
        var tasks: [Task<Void>] = []
        
        execute { expectation in
            for user in randomUsers {
                tasks.append(self.dbClient.delete(user))
            }
            Task.whenAll(tasks)
                .continueOnSuccessWith { createdTasks in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}

