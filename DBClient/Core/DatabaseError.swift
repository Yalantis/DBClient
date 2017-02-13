//
//  DatabaseError.swift
//  DBClient
//
//  Created by Serhii Butenko on 19/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

/// Transaction error type.
///
/// - write: For write transactions.
/// - read: For read transactions.
public enum DatabaseError: Error {
    
    case write, read
    
}
