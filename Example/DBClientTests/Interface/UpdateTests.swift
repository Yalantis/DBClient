//
//  UpdateTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class UpdateTests: DBClientTest {
    
    func testSingleUpdate() {
        let randomUser = createRandomUser()
        let userId = randomUser.id
        let userName = "named \(randomUser.name)"
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
        let randomUser = createRandomUser()
        let userId = randomUser.id
        let newUserId = "n\(userId)"
        // update user's id
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: userId)
                .continueOnSuccessWithTask { user -> Task<User> in
                    XCTAssert(user != nil)
                    user?.id = newUserId
                    return self.dbClient.update(user!)
                }
                .continueWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // check if it exists
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: userId)
                .continueOnSuccessWith { user in
                    // old value should exists
                    XCTAssert(user != nil)
                    expectation.fulfill()
            }
        }
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: newUserId)
                .continueOnSuccessWith { user in
                    // new value shouldn't
                    XCTAssert(user == nil)
                    expectation.fulfill()
            }
        }

    }
    
    func testBulkUpdates() {
        // sort users by id to be sure that each arrays contains the same user at the same index
        let randomUsers: [User] = createRandomUsers(100).sorted()
        let userNames: [String] = randomUsers.map { "awesome \($0.name)" }
        
        // fetch and update them
        execute { expectation in
            let task: Task<[User]> = self.dbClient.fetchAll()
            task
                .continueOnSuccessWithTask { users -> Task<[User]> in
                    let sortedUsers = users.sorted()
                    let updatedUsers = (0..<users.count).map { index -> User in
                        let user = sortedUsers[index]
                        user.name = userNames[index]
                        return user
                    }
                    
                    return self.dbClient.update(updatedUsers)
                }
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        // check
        execute { expectation in
            let task: Task<[User]> = self.dbClient.fetchAll()
            task
                .continueOnSuccessWith { users in
                    let fetchedUserNames = users
                        .sorted()
                        .map { $0.name }
                    XCTAssertEqual(userNames, fetchedUserNames)
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
}
