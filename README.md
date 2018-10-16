# DBClient

[![cocoapods](https://img.shields.io/badge/pod-1.1-blue.svg)](https://cocoapods.org/pods/DBClient) ![swift](https://img.shields.io/badge/Swift-4.2-orange.svg) ![Platform](http://img.shields.io/badge/platform-iOS-blue.svg?style=flat) [![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/Yalantis/DBClient/blob/master/LICENSE)

## Integration (Cocoapods)

There're three podspecs:

- `DBClient/Core` contain pure (CoreData/Realm-free) interface / types used to abstract from implementation. Use it only in case you're about to provide custom implementation of any available storage types.
- `DBClient/CoreData` contain CoreData implementation.
- `DBClient/Realm` contain Realm implementation.

## Usage

Depending on DataBase type you need to create a client:

`let client: DBClient = RealmDBClient(realm: realm)`
or
`let client: DBClient = CoreDataDBClient(forModel: "Users")`

Base methods (`CRUD`,  `observe`) are the same for each type and could be found documented in [`DBClient.swift`](https://github.com/Yalantis/DBClient/blob/master/DBClient/Core/DBClient.swift)

### Realm

To adopt Realm, you need to provide `RealmModelConvertible` protocol implementation for each model you want to support.
`extension User: RealmModelConvertible`

The protocol contains three required methods.

The first one provides a  class (decendant of realm's `Object`) to be associated with your model:
```
static func realmClass() -> Object.Type {
    return ObjectUser.self
}
```

The second one converts abstract realm's `Object` to your model:  
```
static func from(_ realmObject: Object) -> Stored {
    guard let objectUser = realmObject as? ObjectUser else {
        fatalError("Can't create `User` from \(realmObject)")
    }

    return User(id: objectUser.id, name: objectUser.name)
}
```

The last one converts your model to realm's object:
```
func toRealmObject() -> Object {
    let user = ObjectUser()
    user.id = id
    user.name = name

    return user
}
```

### CoreData

TBD

## Version history

- `1.1` Swift 4.2 support
- `0.7` Swift 4.0 support
- `0.4.2`Swift 3.2 support
