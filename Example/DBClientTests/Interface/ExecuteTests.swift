//
//  ExecuteTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
import DBClient
@testable import Example

final class ExecuteTests: DBClientTest {
    
    func testNakedExecute() {
        let user = createRandomUser()
        
        let request = FetchRequest<User>()
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    XCTAssertEqual(users.count, 1)
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
                .continueWith { task in
                    guard let users = task.result else {
                        XCTFail("\(task.error)")
                        return
                    }
                    
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
        let arg = "1"
        let predicate = NSPredicate(format: "SELF.id ENDSWITH %@", arg)

        let randomUsers = createRandomUsers(10).filter {
            $0.id.hasSuffix(arg)
        }
        
        let request = FetchRequest<User>(predicate: predicate)
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
    
    func testOffsetWithOrder() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let order: ComparisonResult = sortDescriptor.ascending ? .orderedAscending : .orderedDescending

        let randomUsers = createRandomUsers(10)
        let offset = 5
        let limit = 2
        let sortedUsers = randomUsers.sorted { $0.0.name.compare($0.1.name) == order }
        let shiftedUsers = Array(sortedUsers[offset..<offset + limit])
        
        let request = FetchRequest<User>(sortDescriptor: sortDescriptor, fetchOffset: offset, fetchLimit: limit)
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { users in
                    XCTAssertEqual(shiftedUsers, users)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    func testCombinedRequest() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let order: ComparisonResult = sortDescriptor.ascending ? .orderedAscending : .orderedDescending

        let arg = "1"
        let predicate = NSPredicate(format: "SELF.id BEGINSWITH %@", arg)

        let randomUsers = createRandomUsers(50)
        let offset = 2
        let limit = 5
        var users = randomUsers.filter { $0.id.hasPrefix(arg) }
        users = users.sorted { $0.0.name.compare($0.1.name) == order }
        users = Array(users[offset..<offset + limit])
        
        let request = FetchRequest<User>(
            predicate: predicate,
            sortDescriptor: sortDescriptor,
            fetchOffset: offset,
            fetchLimit: limit
        )
        execute { expectation in
            self.dbClient
                .execute(request)
                .continueOnSuccessWith { fetchedUsers in
                    XCTAssertEqual(users, fetchedUsers)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}
