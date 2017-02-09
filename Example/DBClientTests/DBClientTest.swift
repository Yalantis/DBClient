//
//  DBClientTest.swift
//  DBClientTests
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import XCTest

class DBClientTest: XCTestCase {

    var expectationTimeout: TimeInterval {
        return 25
    }
    
    // execute given closure asynchronously with expectation
    func execute(_ closure: @escaping (XCTestExpectation) -> ()) {
        let exp = expectation(description: "DBClientTestExpectation")
        DispatchQueue.global(qos: .background).async {
            closure(exp)
        }
        waitForExpectations(timeout: expectationTimeout) { (error) in
            XCTAssert(error == nil, "\(error)")
        }
    }
    
}
