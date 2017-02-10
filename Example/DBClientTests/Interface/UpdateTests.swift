//
//  UpdateTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import BoltsSwift
@testable import Example

final class UpdateTests: DBClientTest {
    
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
        let randomUser = User.createRandom()
        let userId = randomUser.id
        let newUserId = "n\(userId)"
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
        // update user's id
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: userId)
                .continueOnSuccessWithTask { user -> Task<User> in
                    XCTAssert(user != nil)
                    user?.id = newUserId
                    return self.dbClient.update(user!)
                }
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        // check if it exists
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: userId)
                .continueOnSuccessWith { user in
                    // the user exists because when we try to update user with new primaryId 
                    // it doesn't exist in db so we create a new one
                    XCTAssert(user != nil)
                    expectation.fulfill()
            }
        }
        execute { expectation in
            self.dbClient
                .findFirst(User.self, primaryValue: newUserId)
                .continueOnSuccessWith { user in
                    XCTAssert(user != nil)
                    expectation.fulfill()
            }
        }

    }
    
    func testBulkUpdates() {
        // sort users by id to be sure that each arrays contains the same user at the same index
        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }.sorted()
        let userNames: [String] = randomUsers.map { "awesome \($0.name)" }
        
        // save users
        execute { expectation in
            self.dbClient
                .save(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
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
                    
                    return self.dbClient.save(updatedUsers)
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
