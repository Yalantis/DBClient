//
//  CoreDataObservableTests.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/13/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import DBClient
@testable import Example

final class CoreDataObservableTests: DBClientCoreDataTest {
    
    func test_InsertionObservation_WhenSuccessful_InvokesChnages() {
        let request = FetchRequest<User>()
        let observable = dbClient.observable(for: request)
        let objectsToCreate: [User] = (0...100).map { _ in User.createRandom() }
        let expectationObject = expectation(description: "Object")
        var expectedInsertedObjects = [User]()
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
            case .change(let change):
                expectedInsertedObjects = change.insertions.map { $0.element }
                expectationObject.fulfill()
            default: break
            }
        }
        
        dbClient.insert(objectsToCreate) { _ in }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedInsertedObjects.sorted(), objectsToCreate.sorted())
        }
    }
    
    func test_UpdationObservation_WhenSuccessful_InvokesChnages() {
        let request = FetchRequest<User>()
        let observable = dbClient.observable(for: request)
        let objectsToCreate: [User] = (0...100).map { _ in User.createRandom() }
        let expectationObject = expectation(description: "Changes observe")
        var expectedUpdatedObjects = [User]()
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
            case .change(let change):
                if !change.modifications.isEmpty {
                    expectedUpdatedObjects = change.modifications.map { $0.element }
                    expectationObject.fulfill()
                }
            default: break
            }
        }
        
        let updateExpectation = expectation(description: "Insert and update")
        dbClient.insert(objectsToCreate) { _ in
            objectsToCreate.forEach { $0.mutate() }
            self.dbClient.update(objectsToCreate) { _ in
                updateExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedUpdatedObjects.sorted(), objectsToCreate.sorted())
        }
    }
    
    func test_DeletionObservation_WhenSuccessful_InvokesChnages() {
        let request = FetchRequest<User>()
        let observable = dbClient.observable(for: request)
        let objectsToCreate: [User] = (0...100).map { _ in User.createRandom() }
        let expectationObject = expectation(description: "Object")
        var expectedDeletedObjectsCount = 0
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
            case .change(let change):
                if !change.deletions.isEmpty {
                    expectedDeletedObjectsCount = change.deletions.count
                    expectationObject.fulfill()
                }
            default: break
            }
        }
        
        dbClient.insert(objectsToCreate) { _ in
            self.dbClient.delete(objectsToCreate) { _ in }
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(expectedDeletedObjectsCount, objectsToCreate.count)
        }
    }
}
