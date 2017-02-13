//
//  CreateTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class CreateTests: DBClientTest {
    
    func testSingleInsertion() {
        let randomUser = User.createRandom()
        execute { expectation in
            self.dbClient
                .insert(randomUser)
                .continueOnSuccessWith { savedUser in
                    XCTAssertEqual(randomUser, savedUser)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testBulkInsertions() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        execute { expectation in
            self.dbClient
                .insert(randomUsers)
                .continueOnSuccessWith { savedUsers in
                    XCTAssertEqual(randomUsers, savedUsers)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testAsyncInsertions() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        var tasks: [Task<User>] = []
        
        let expectation = self.expectation(description: "insert users")

        DispatchQueue.global(qos: .background).async {
            for user in randomUsers {
                tasks.append(self.dbClient.insert(user))
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

