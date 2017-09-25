# DBClient

## Requirements

- Xcode 9
- Swift 4
- iOS 9+

## Installation

### Cocoapods

There're 3 podspecs:

Core, common classes for any database:

```ruby
pod 'DBClient', :git => 'https://github.com/Yalantis/DBClient.git'
```

Wrapper for CoreData:

```ruby
pod 'DBClient/CoreData', :git => 'https://github.com/Yalantis/DBClient.git'
```

Wrapper for Realm:

```ruby
pod 'DBClient/Realm', :git => 'https://github.com/Yalantis/DBClient.git'
```

## Xcode 8 and Swift 3.2 support

To support old version of DBClient for Xcode 8 and Swift 3.2 need add previous version tag ```ruby 0.4.2 ```:

```ruby
pod 'DBClient', :git => 'https://github.com/Yalantis/DBClient.git', :tag => '0.4.2'
```
