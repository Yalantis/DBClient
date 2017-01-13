# DBClient

## Requirements

- Xcode 8
- Swift 3
- iOS 9+

## Installation

### Cocoapods

There're 3 podspecs:

Core, common classes for any database:

```ruby
pod 'DBClient', '~> 1.0'
```

Wrapper for CoreData:

```ruby
pod 'DBClient/CoreData', '~> 1.0'
```

Wrapper for Realm:

```ruby
pod 'DBClient/Realm', '~> 1.0'
```
⚠️ It's not ready yet (there're problems with deletion and observation)