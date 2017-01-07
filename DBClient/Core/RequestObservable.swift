//
//  RequestObservable.swift
//  ArchitectureGuideTemplate
//
//  Created by Serhii Butenko on 15/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

/// Describes changes in database:
///
/// - initial: initial storred entities.
/// - update: deletions, insertions, modifications.
/// - error: an error occurred during fetch.
public enum ObservableChange<T: Stored> {
  
  case initial([T])
  case update(deletions: [Int], insertions: [(index: Int, element: T)], modifications: [(index: Int, element: T)])
  case error(Error)
  
}

public class RequestObservable<T: Stored> {
  
  let request: FetchRequest<T>

  init(request: FetchRequest<T>) {
    self.request = request
  }

  /// Starts observing with a given fetch request.
  ///
  /// - Parameter closure: gets called once any changes in database are occurred.
  /// - Warning: You cannot call the method only if you don't observe it now.
  public func observe(_ closure: @escaping (ObservableChange<T>) -> Void) {
    assertionFailure("The observe method must be overriden")
  }
  
}
