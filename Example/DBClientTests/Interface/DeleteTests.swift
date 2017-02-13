//
//  DeleteTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class DeleteTests: DBClientTest {
    
    func testSingleDeletion() {
        let randomUser = User.createRandom()
        // save user to db
        execute { expectation in
            self.dbClient
                .save(randomUser)
                .continueOnSuccessWith { savedUser in
                    XCTAssertEqual(randomUser, savedUser)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
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
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        
        // save user to db
        execute { expectation in
            self.dbClient
                .save(randomUsers)
                .continueOnSuccessWith { savedUsers in
                    XCTAssertEqual(randomUsers, savedUsers)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // remove user from db
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
            let request: Task<[User]> = self.dbClient.fetchAll()
            request
                .continueOnSuccessWith { users in
                    XCTAssert(users.isEmpty)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testAsyncDeletions() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        
        execute { expectation in
            self.dbClient
                .save(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        var tasks: [Task<User>] = []
        let expectation = self.expectation(description: "delete users")
        
        DispatchQueue.global(qos: .background).async {
            for user in randomUsers {
                tasks.append(self.dbClient.delete(user))
            }
            Task.whenAll(tasks)
                .continueOnSuccessWith { createdTasks in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        waitForExpectations(timeout: expectationTimeout) { (error) in
            XCTAssert(error == nil, "\(error)")
        }
    }
    
}

