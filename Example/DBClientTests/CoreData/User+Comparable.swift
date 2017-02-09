//
//  User+Comparable.swift
//  Example
//
//  Created by Roman Kyrylenko on 2/9/17.
//  Copyright © 2017 Yalantis. All rights reserved.
//

@testable import Example

extension User: Comparable {

    public static func <(lhs: Self, rhs: Self) -> Bool
    
    public static func <=(lhs: Self, rhs: Self) -> Bool
    
    public static func >=(lhs: Self, rhs: Self) -> Bool
    
    public static func >(lhs: Self, rhs: Self) -> Bool

}
