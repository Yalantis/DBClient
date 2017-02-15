//
//  ObservableTests.swift
//  DBClient-Example
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
                XCTFail("\(error)")
            }
        }
        
        createRandomUsers(objectsToCreate)
    }
    
    func testUpdationObservations() {
        let request = FetchRequest<User>()
        let observable = dbClient.observable(for: request)
        
        let numberOfUsers = 50
        createRandomUsers(numberOfUsers)
        let numberOfUsersToUpdate = 10
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
                
            case .change(let change):
                XCTAssertEqual(change.objects.count, numberOfUsers)
                XCTAssertEqual(change.modifications.count, numberOfUsersToUpdate)
                
            case .initial(let objects):
                XCTAssertEqual(objects.count, numberOfUsers)
                
            case .error(let error):
                XCTFail("\(error)")
            }
        }
        
        execute { expectation in
            let request = FetchRequest<User>(fetchLimit: numberOfUsersToUpdate)
            self.dbClient.execute(request)
                .continueOnSuccessWithTask { users -> Task<[User]> in
                    return self.dbClient.update(users)
                }
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
            }
        }
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
                XCTFail("\(error)")
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
    
    func testComplexRequestObservations() {
        let users = createRandomUsers(100)
        let offset = 5
        let suffix = "1"
        let numberOfMatchedUsers = users.filter { $0.id.hasSuffix(suffix) }.count
        
        let request = FetchRequest<User>(
            predicate: NSPredicate(format: "SELF.id ENDSWITH %@", suffix),
            fetchOffset: offset
        )
        let observable = dbClient.observable(for: request)
        
        observable.observe { (change: ObservableChange<User>) in
            switch change {
                
            case .change(let change):
                XCTAssertEqual(numberOfMatchedUsers - offset, change.objects.count)
                
            case .initial(let objects):
                XCTAssertEqual(objects.count, numberOfMatchedUsers - offset)
                
            case .error(let error):
                XCTFail("\(error)")
            }
        }
    }
    
}
