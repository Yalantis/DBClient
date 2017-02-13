//
//  ObservableTests.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/13/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import BoltsSwift
import XCTest
import DBClient
@testable import Example

final class ObservableTests: DBClientTest {
    
    func testInsertionObservations() {
        let request = FetchRequest<User>()
        let observable = dbClient.observable(for: request)
        
        let objectsToCreate = 50
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
                
            case .change(let change):
                XCTAssertEqual(change.insertions.count, objectsToCreate)
                XCTAssertEqual(change.objects.count, objectsToCreate)
                
            case .initial(let objects):
                XCTAssert(objects.isEmpty)
                
            case .error(let error):
                XCTAssert(false, "\(error)")
            }
        }
        
        createRandomUsers(objectsToCreate)
    }
    
    func testUpdationObservations() {
        
    }
    
    func testDeletionObservations() {
        let request = FetchRequest<User>()
        let observable = dbClient.observable(for: request)
        
        let numberOfUsers = 50
        createRandomUsers(numberOfUsers)
        let numberOfUsersToDelete = 10
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
                
            case .change(let change):
                XCTAssertEqual(change.objects.count, numberOfUsers - numberOfUsersToDelete)
                XCTAssertEqual(change.deletions.count, numberOfUsersToDelete)
                
            case .initial(let objects):
                XCTAssertEqual(objects.count, numberOfUsers)
                
            case .error(let error):
                XCTAssert(false, "\(error)")
            }
        }
        
        execute { expectation in
            let request = FetchRequest<User>(fetchLimit: numberOfUsersToDelete)
            self.dbClient.execute(request)
                .continueOnSuccessWithTask { users -> Task<Void> in
                    return self.dbClient.delete(users)
                }
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
            }
        }
    }
    
    func testCombinedObservations() {
    }
    
    func testComplexRequestObservations() {
    }
    
}
