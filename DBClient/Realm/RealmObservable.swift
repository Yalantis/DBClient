//
//  RealmObservable.swift
//  DBClient
//
//  Created by Serhii Butenko on 15/12/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation
import RealmSwift

extension Object: Stored {

    public static var primaryKeyName: String? { return nil }
    
    public var valueOfPrimaryKey: CVarArg? { return nil }

}

internal class RealmObservable<T: Stored>: RequestObservable<T> {
    
    internal let realm: Realm
    internal var notificationToken: NotificationToken?
    
    internal init(request: FetchRequest<T>, realm: Realm) {
        self.realm = realm
        super.init(request: request)
    }
    
    open override func observe(_ closure: @escaping (ObservableChange<T>) -> Void) {
        precondition(notificationToken == nil, "Observable can be observed only once")

        guard let realmModelType = T.self as? RealmModelConvertible.Type else {
            fatalError("RealmDBClient can manage only types which conform to RealmModelConvertible")
        }
        
        let realmObjects = request.applyTo(realmObjects: realm.objects(realmModelType.realmClass()))
        notificationToken = realmObjects.observe { changes in
            switch changes {
            case .initial(let initial):
                let mapped = initial.map { realmModelType.from($0) as! T }
                closure(.initial(Array(mapped)))
                
            case .update(let objects, let deletions, let insertions, let modifications):
                let mappedObjects = objects.map { realmModelType.from($0) as! T }
                let insertions = insertions.map { (index: $0, element: mappedObjects[$0]) }
                let modifications = modifications.map { (index: $0, element: mappedObjects[$0]) }
                let mappedChange: ObservableChange<T>.ModelChange = (
                    objects: Array(mappedObjects),
                    deletions: deletions,
                    insertions: insertions,
                    modifications: modifications
                )
                closure(.change(mappedChange))
                
            case .error(let error):
                closure(.error(error))
            }
        }
    }
    
    public func stopObserving() {
        notificationToken = nil
    }
}
