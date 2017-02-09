//
//  CoreDataUpdateTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class CoreDataUpdateTests: CoreDataTest {
    
    func testSingleUpdate() {
        let randomUser = User.createRandom()
        let userId = randomUser.id
        let userName = "named \(randomUser.name)"
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
        // update user's name
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: userId)
                .continueOnSuccessWithTask { user -> Task<User> in
                    XCTAssert(user != nil)
                    user?.name = userName
                    return self.dbClient.update(user!)
                }
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // check it
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: userId)
                .continueOnSuccessWith { user in
                    XCTAssert(user != nil)
                    XCTAssert(user!.name == userName)
                    expectation.fulfill()
            }
        }
    }
    
    func testPrimaryValueUpdate() {
        // todo:
    }
    
//    func testBulkUpdates() {
//        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }
//        let userNames: [String] = randomUsers.map { "awesome \($0.name)" }
//        
//        // save users
//        execute { expectation in
//            self.dbClient
//                .save(randomUsers)
//                .continueOnSuccessWith { _ in
//                    expectation.fulfill()
//                }
//                .waitUntilCompleted()
//        }
//        
//        // fetch and update them
//        execute { expectation in
//            let task: Task<[User]> = self.dbClient.fetchAll()
//            task
//                .continueOnSuccessWithTask { users -> Task<[User]> in
//                    let sortedUsers = users.sorted { $0.0.id.compare($0.1.id) == .orderedAscending }
//                    let updatedUsers = (0..<users.count).map { index -> User in
//                        let user = sortedUsers[index]
//                        user.name = userNames[index]
//                        return user
//                    }
//                    
//                    return self.dbClient.save(updatedUsers)
//                }
//                .continueOnSuccessWith { _ in
//                    expectation.fulfill()
//                }
//                .waitUntilCompleted()
//        }
//        
//        // check
//        execute { expectation in
//            let task: Task<[User]> = self.dbClient.fetchAll()
//            task
//                .continueOnSuccessWith { users in
//                    let fetchedUserNames = users
//                        .sorted { $0.0.id.compare($0.1.name) == .orderedAscending }
//                        .map { $0.name }
//                    XCTAssertEqual(userNames, fetchedUserNames)
//                    expectation.fulfill()
//                }
//                .waitUntilCompleted()
//        }
//    }
    
}
