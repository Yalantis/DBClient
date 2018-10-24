//
//  CoreDataExecuteTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import DBClient
@testable import Example

final class CoreDataExecuteTests: DBClientCoreDataTest {
    
    func test_SingleSyncExecute_WhenSuccessful_ReturnsCount() {
        let randomUser = User.createRandom()
        
        dbClient.insert(randomUser)
        let request = FetchRequest<User>()
        let executionResult = dbClient.execute(request)
        
        XCTAssertEqual(executionResult.require().first!, randomUser)
    }
    
    func test_SingleExecute_WhenSuccessful_ReturnsCount() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Object")
        var expectedCount = 0
        
        self.dbClient.insert(randomUser) { result in
            if result.value != nil {
                let request = FetchRequest<User>()
                self.dbClient.execute(request) { result in
                    expectedCount = result.value?.count ?? 0
                    expectationObject.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedCount, 1)
        }
    }
    
    func test_ExecuteWithOffset_WhenSuccessful_ReturnsCount() {
        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }
        let offset = 5
        let shiftedUsers = Array(randomUsers[offset..<randomUsers.count])
        let expectationObjects = expectation(description: "Object")
        var expectedCount = 0
        
        self.dbClient.insert(randomUsers) { result in
            if result.value != nil {
                let request = FetchRequest<User>(fetchOffset: offset)
                self.dbClient.execute(request) { result in
                    expectedCount = result.value?.count ?? 0
                    expectationObjects.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedCount, shiftedUsers.count)
        }
    }
    
    func test_ExecuteWithLimit_WhenSuccessful_ReturnsCount() {
        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }
        let limit = 3

        let expectationObjects = expectation(description: "Object")
        var expectedCount = 0
        
        self.dbClient.insert(randomUsers) { result in
            if result.value != nil {
                let request = FetchRequest<User>(fetchLimit: limit)
                self.dbClient.execute(request) { result in
                    expectedCount = result.value?.count ?? 0
                    expectationObjects.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedCount, limit)
        }
    }
    
    func test_ExecuteWithSortDescriptor_WhenSuccessful_ReturnsCount() {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let order: ComparisonResult = sortDescriptor.ascending ? .orderedAscending : .orderedDescending
        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }
        let sortedUsers = randomUsers.sorted { $0.name.compare($1.name) == order }
        let expectationObjects = expectation(description: "Object")
        var expectedUsers = [User]()
        
        self.dbClient.insert(randomUsers) { result in
            if result.value != nil {
                let request = FetchRequest<User>(sortDescriptor: sortDescriptor)
                
                self.dbClient.execute(request) { result in
                    expectedUsers = result.value ?? []
                    expectationObjects.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedUsers, sortedUsers)
        }
    }
    
    func test_ExecuteWithPredicate_WhenSuccessful_ReturnsCount() {
        let arg = "1"
        let predicate = NSPredicate(format: "SELF.id ENDSWITH %@", arg)
        let randomUsers: [User] = (0...10).map { _ in User.createRandom() }
        let preicatedUsers = randomUsers.filter { $0.id.hasSuffix(arg) }
        let expectationObjects = expectation(description: "Object")
        var expectedUsers = [User]()
        
        self.dbClient.insert(randomUsers) { result in
            guard result.value != nil else {
                expectationObjects.fulfill()
                return
            }
            let request = FetchRequest<User>(predicate: predicate)
            
            self.dbClient.execute(request) { result in
                expectedUsers = result.value ?? []
                expectationObjects.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedUsers.sorted(), preicatedUsers.sorted())
        }
    }
}
