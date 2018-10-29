//
//  CoreDataCreateTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
@testable import Example

final class CoreDataCreateTests: DBClientCoreDataTest {
    
    func test_SyncSingleInsertion_WhenSuccessful_ReturnsObject() {
        let randomUser = User.createRandom()
        let result = dbClient.insert(randomUser)
        switch result {
        case .failure(let error): XCTFail(error.localizedDescription)
        case .success(let user): XCTAssertEqual(randomUser, user)
        }
    }
    
    func test_SyncBulkInsertion_WhenSuccessful_ReturnsObjects() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }

        let result = dbClient.insert(randomUsers)
        
        switch result {
        case .failure(let error): XCTFail(error.localizedDescription)
        case .success(let users): XCTAssertEqual(users.sorted(), randomUsers.sorted())
        }
    }
    
    func test_SingleInsertion_WhenSuccessful_ReturnsObject() {
        let randomUser = User.createRandom()
        let expectationObject = expectation(description: "Object")
        var expectedObject: User?
        
        dbClient.insert(randomUser) { result in
            expectedObject = result.value
            expectationObject.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertNotNil(expectedObject)
        }
    }
    
    func test_BulkInsertion_WhenSuccessful_ReturnsBulk() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }

        let expectationObjects = expectation(description: "Objects")
        var expectedObjectsCount = 0

        dbClient.insert(randomUsers) { result in
            expectedObjectsCount = result.value?.count ?? 0
            expectationObjects.fulfill()
        }

        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedObjectsCount, randomUsers.count)
        }
    }
}
