//
//  DBClientTest.swift
//  DBClientTests
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest
import DBClient
import BoltsSwift
import RealmSwift
@testable import Example

enum StorageType {
    
    case realm
    case coreData
    
}

let storageType: StorageType = .realm

class DBClientTest: XCTestCase {
    
    lazy var dbClient: DBClient = {
        switch storageType {
        case .realm:
            let realm = try! Realm()
            return RealmDBClient(realm: realm)
            
        case .coreData:
            return CoreDataDBClient(forModel: "Users")
        }
    }()
    
    var expectationTimeout: TimeInterval {
        return 25
    }
    
    // execute given closure asynchronously with expectation
    func execute(_ closure: @escaping (XCTestExpectation) -> ()) {
        let exp = expectation(description: "DBClientTestExpectation")
        switch storageType {
        // because realm transactions should be perfomrmed in the same thread where realm created
        case .realm:
            closure(exp)
            
        default:
            DispatchQueue.global(qos: .background).async {
                closure(exp)
            }
        }
        waitForExpectations(timeout: expectationTimeout) { (error) in
            XCTAssert(error == nil, "\(error)")
        }
    }
    
    override func setUp() {
        super.setUp()
        
        cleanUpDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
        
        cleanUpDatabase()
    }
    
    // removes all objects from the database
    func cleanUpDatabase() {
        print("[DBClientTest]: Cleaning database")
        var count = 0
        let request: Task<[User]> = dbClient.findAll()
        execute { (expectation) in
            request
                .continueOnSuccessWithTask { users -> Task<Void> in
                    count = users.count
                    return self.dbClient.delete(users)
                }
                .continueOnSuccessWith { objects in
                    print("[DBClientTest]: Removed \(count) objects")
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
    }
    
    @discardableResult func createRandomUser() -> User {
        let randomUser = User.createRandom()
        execute { expectation in
            self.dbClient
                .insert(randomUser)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        return randomUser
    }
    
    @discardableResult func createRandomUsers(_ count: Int) -> [User] {
        let randomUsers = (0..<count).map { _ in User.createRandom() }
        execute { expectation in
            self.dbClient
                .insert(randomUsers)
                .continueOnSuccessWith { _ in
                    expectation.fulfill()
                }
                .waitUntilCompleted()
        }
        
        return randomUsers
    }
    
}
