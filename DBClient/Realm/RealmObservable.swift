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

public class RealmObservable<T: Stored>: RequestObservable<T> {
  
  internal let realm: Realm
  internal var notificationToken: NotificationToken?
  
  internal init(request: FetchRequest<T>, realm: Realm) {
    self.realm = realm
    super.init(request: request)
  }
  
  open override func observe(_ closure: @escaping (ObservableChange<T>) -> Void) {
    precondition(notificationToken == nil, "Observable can be observed only once")
    
    guard let realmModelType = T.self as? RealmModelConvertible.Type else  {
      fatalError("RealmDBClient can manage only types which conform to RealmModelConvertible")
    }
    
    var realmObjects = realm.objects(realmModelType.realmClass())
    if let predicate = request.predicate {
      realmObjects = realmObjects.filter(predicate)
    }
    if let sortDescriptor = request.sortDescriptor, let key = sortDescriptor.key {
      realmObjects = realmObjects.sorted(byProperty: key, ascending: sortDescriptor.ascending)
    }
    
    notificationToken = realmObjects.addNotificationBlock { changes in
      switch changes {
      case .initial(let initial):
        let mapped = initial.map { realmModelType.from($0) as! T }
        closure(.initial(Array(mapped)))
      
      case .change(let objects, let deletions, let insertions, let modifications):
        let mappedObjects = objects.map { realmModelType.from($0) as! T }
        let insertions = insertions.map { (index: $0, element: mappedObjects[$0]) }
        let modifications = modifications.map { (index: $0, element: mappedObjects[$0]) }
        closure(.change(objects: mappedObjects, deletions: deletions, insertions: insertions, modifications: modifications))
        
      case .error(let error):
        closure(.error(error))
      }
    }
  }
  
  public func stopObserving() {
    notificationToken = nil
  }
  
}
