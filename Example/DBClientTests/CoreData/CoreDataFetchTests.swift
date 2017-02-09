//
//  CoreDataFetchTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
import BoltsSwift
import XCTest
@testable import Example

class CoreDataFetchTests: CoreDataTest {
    
    func testSingleFetch() {
        let user = User.createRandom()
        // save user to database
        execute { expectation in
            self.dbClient
                .save(user)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
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
        let randomUsers: [User] = (0...10)
            .map { _ in User.createRandom() }
            .sorted { $0.0.id.compare($0.1.id) == .orderedAscending }
        
        // save generated users to database
        execute { expectation in
            self.dbClient
                .save(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // check if generated users have been successfully saved
        let request: Task<[User]> = dbClient.fetchAll()
        execute { expectation in
            request
                .continueOnSuccessWith { fetchedUsers in
                    // use sort to match users order
                    XCTAssert(randomUsers == fetchedUsers.sorted { $0.0.id.compare($0.1.id) == .orderedAscending })
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testAsyncFetches() {
        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }
        let userIds: [String] = randomUsers.map { $0.id }
        var tasks: [Task<User?>] = []
        // save users to db
        execute { expectation in
            self.dbClient
                .save(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
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
