# DBClient

[![cocoapods](https://img.shields.io/cocoapods/v/DBClient.svg)](https://img.shields.io/cocoapods/v/DBClient.svg) ![swift](https://img.shields.io/badge/Swift-4.2-orange.svg) ![Platform](http://img.shields.io/badge/platform-iOS-blue.svg?style=flat) [![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/Yalantis/DBClient/blob/master/LICENSE)

## Integration (Cocoapods)

There're three podspecs:

- `DBClient/Core` contains pure (CoreData/Realm-free) interface / types used to abstract from implementation. Use it only in case you're about to provide custom implementation of any available storage types.
- `DBClient/CoreData` contains CoreData implementation.
- `DBClient/Realm` contains Realm implementation.

## Usage

Depending on DataBase type you need to create a client:
`let client: DBClient = RealmDBClient(realm: realm)`
or
`let client: DBClient = CoreDataDBClient(forModel: "Users")`

Base methods (`CRUD`,  `observe`) are the same for each type and could be found documented in [`DBClient.swift`](https://github.com/Yalantis/DBClient/blob/master/DBClient/Core/DBClient.swift)

Each model you create required to conform `Stored` protocol with two properties:
```
extension User: Stored {

    public static var primaryKeyName: String? {
        return "id"
    }

    public var valueOfPrimaryKey: CVarArg? {
        return id
    }
}
```

For each model you create you need to define associated database model described below.

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

To adopt CoreData, you need to create your model and provide appropriate file name to client's constructor (bundle could also be specified) and for each your model provide implementation of the `CoreDataModelConvertible` protocol.
`extension User: CoreDataModelConvertible`

The protocol requires four methods and one field to be implemented. Documentation for each method/field could be found in [`CoreDataDBClient.swift`](https://github.com/Yalantis/DBClient/blob/master/DBClient/CoreData/CoreDataDBClient.swift)

In the field `entityName` you should provide entity name (equal to one specified in your model):
```
public static var entityName: String {
    return String(describing: self)
}
```

The next method used to determine associated `NSManagedObject` ancestor to your model:
```
public static func managedObjectClass() -> NSManagedObject.Type {
    return ManagedUser.self
}
```

The next method determines whether given object equal to current: 
```
func isPrimaryValueEqualTo(value: Any) -> Bool {
    if let value = value as? String {
        return value == id
    }

    return false
}
```

Next method used to convert `NSManagedObject` to your model. Feel free to fail with `fatalError` here since it's developer's issue. 
```
public static func from(_ managedObject: NSManagedObject) -> Stored {
    guard let managedUser = managedObject as? ManagedUser else {
        fatalError("can't create User object from object \(managedObject)")
    }
    guard let id = managedUser.id,
        let name = managedUser.name else {
        fatalError("can't get required properties for user \(managedObject)")
    }

    return User(id: id, name: name)
}
```

The last method used to create/update `NSManagedObject` in given context based on your model:
```
public func upsertManagedObject(in context: NSManagedObjectContext, existedInstance: NSManagedObject?) -> NSManagedObject {
    var user: ManagedUser
    if let result = existedInstance as? ManagedUser { // fetch existing
        user = result
    } else { // or create new
        user = NSEntityDescription.insertNewObject(
            forEntityName: User.entityName,
            into: context
            ) as! ManagedUser
    }
    user.id = id
    user.name = name

    return user
}

```

## Version history


| Version | Swift | Dependencies                                | iOS  |
|----------|-------|----------------------------------------|------|
| `1.4`     | 5       | RealmSwift 3.15.0, YALResult 1.4  | 10   |
| `1.3`     | 4.2    | RealmSwift 3.11.1, YALResult 1.1  | 10   |
| `1.0`     | 4.2    | RealmSwift 2.10.1, YALResult 1.0  | 10   |
| `0.7`     | 4.0    | RealmSwift 2.10.1, BoltsSwift 1.4  | 9     |
| `0.6`     |  4      | RealmSwift 2.10.1, BoltsSwift 1.3  | 9     |
| `0.4.2` |  3.2   | RealmSwift 2.1.1,  BoltsSwift 1.3   | 9     |
