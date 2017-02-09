//
//  User+Equtable.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/8/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

import Foundation
@testable import Example

extension User: Equatable {
    
    public static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }

}
