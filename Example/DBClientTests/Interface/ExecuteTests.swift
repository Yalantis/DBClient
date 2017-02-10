//
//  ExecuteTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
import DBClient
@testable import Example

final class ExecuteTests: DBClientTest {
    
    @discardableResult private func createRandomUser() -> User {
        let randomUser = User.createRandom()
        execute { expectation in
            self.dbClient
                .save(randomUser)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        return randomUser
    }
    
    @discardableResult private func createRandomUsers(_ count: Int) -> [User] {
        let randomUsers = (0..<count).map { _ in User.createRandom() }
        execute { expectation in
            self.dbClient
                .save(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        return randomUsers
    }
    
    func testNakedExecute() {
        let user = createRandomUser()
        
        let request = FetchRequest<User>()
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    XCTAssert(users.count == 1)
                    XCTAssertEqual(user, users.first!)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testOffset() {
        let randomUsers = createRandomUsers(10)
        let offset = 5
        let shiftedUsers = Array(randomUsers[offset..<randomUsers.count])
        
        let request = FetchRequest<User>(fetchOffset: offset)
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    // check only count of arrays beacause we haven't specified sorting
                    XCTAssertEqual(shiftedUsers.count, users.count)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testLimit() {
        createRandomUsers(10)
        let limit = 3
        
        let request = FetchRequest<User>(fetchLimit: limit)
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    XCTAssertEqual(limit, users.count)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testOrder() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let order: ComparisonResult = sortDescriptor.ascending ? .orderedAscending : .orderedDescending
        
        let randomUsers = createRandomUsers(10).sorted { $0.0.name.compare($0.1.name) == order }
        
        let request = FetchRequest<User>(sortDescriptor: sortDescriptor)
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    XCTAssertEqual(randomUsers, users)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testPredicate() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let order: ComparisonResult = sortDescriptor.ascending ? .orderedAscending : .orderedDescending
        
        let randomUsers = createRandomUsers(10).sorted { $0.0.name.compare($0.1.name) == order }
        
        let request = FetchRequest<User>(sortDescriptor: sortDescriptor)
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    XCTAssertEqual(randomUsers, users)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}
