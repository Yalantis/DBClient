//
//  User+Equtable.swift
//  DBClient-Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

@testable import Example

// allows us to use `XCAssertEqual` on `User` objects
extension User: Equatable {
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

}
