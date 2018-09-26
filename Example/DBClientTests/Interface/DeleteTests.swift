//
//  DeleteTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
@testable import Example

final class DeleteTests: DBClientTest {
    
    func test_SingleDeletion_WhenSuccessful_ReturnsNil() {
        let randomUser = User.createRandom()
        let expectationHit = expectation(description: "Object")
        var isDeleted = false
        
        self.dbClient.insert(randomUser, completion: { result in
            if let object = result.value {
                self.dbClient.delete(object, completion: { result in
                    isDeleted = result.value != nil
                    expectationHit.fulfill()
                })
            }
        })
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(isDeleted)
        }
    }
    
    func test_BulkDeletion_WhenSuccessful_ReturnsNil() {
        let randomUsers: [User] = (0...100).map { _ in User.createRandom() }
        let expectationHit = expectation(description: "Object")
        var isDeleted = false
        
        self.dbClient.insert(randomUsers, completion: { result in
            if let objects = result.value {
                self.dbClient.delete(objects, completion: { result in
                    isDeleted = result.value != nil
                    expectationHit.fulfill()
                })
            }
        })
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(isDeleted)
        }
    }
    
}
