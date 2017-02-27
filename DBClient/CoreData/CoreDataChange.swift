//
//  CoreDataChange.swift
//  DBClient
//
//  Created by Serhii Butenko on 19/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

enum CoreDataChange<T> {
    
    case update(Int, T)
    case delete(Int, T)
    case insert(Int, T)
    
    func object() -> T {
        switch self {
        case .update(_, let object): return object
        case .delete(_, let object): return object
        case .insert(_, let object): return object
        }
    }
    
    func index() -> Int {
        switch self {
        case .update(let index, _): return index
        case .delete(let index, _): return index
        case .insert(let index, _): return index
        }
    }
    
    var isDeletion: Bool {
        switch self {
        case .delete(_): return true
        default: return false
        }
    }
    
    var isUpdate: Bool {
        switch self {
        case .update(_): return true
        default: return false
        }
    }
    
    var isInsertion: Bool {
        switch self {
        case .insert(_): return true
        default: return false
        }
    }
    
}
