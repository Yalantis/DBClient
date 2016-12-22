//
//  RealmObservable.swift
//  ArchitectureGuideTemplate
//
//  Created by Serhii Butenko on 15/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import RealmSwift

extension Object: Stored {}

public class RealmObservable<T: Object>: RequestObservable<T> {
  
  internal let realm: Realm
  internal var notificationToken: NotificationToken?
  
  internal init(request: FetchRequest<T>, realm: Realm) {
    self.realm = realm
    super.init(request: request)
  }
  
  open override func observe(_ closure: @escaping (ObservableChange<T>) -> Void) {
    precondition(notificationToken == nil, "Observable can be observed only once")
    
    var realmObjects = realm.objects(T.self)
    if let predicate = request.predicate {
      realmObjects = realmObjects.filter(predicate)
    }
    if let sortDescriptor = request.sortDescriptor, let key = sortDescriptor.key {
      realmObjects = realmObjects.sorted(byProperty: key, ascending: sortDescriptor.ascending)
    }
    
    notificationToken = realmObjects.addNotificationBlock { [unowned self] changes in
      closure(self.map(changes))
    }
  }
  
  public override func stopObserving() {
    notificationToken = nil
  }
  
  fileprivate func map(_ realmChange: RealmCollectionChange<Results<T>>) -> ObservableChange<T> {
    switch realmChange {
    case .initial(let initial):
      return .initial(Array(initial))
      
    case .update(let objects, let deletions, let insertions, let modifications):
      let deletions = deletions.map { $0 }
      let insertions = insertions.map { (index: $0, element: objects[$0]) }
      let modifications = modifications.map { (index: $0, element: objects[$0]) }
      return .update(deletions: deletions, insertions: insertions, modifications: modifications)
      
    case .error(let error):
      return .error(error)
    }
  }
  
}
