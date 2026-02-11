# Dependency

A lightweight dependency injection and event publishing framework for Swift.

## Features

- ✅ Simple dependency injection using property wrappers
- ✅ Global event publishing system
- ✅ UserDefaults client with type-safe storage
- ✅ Support for iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+
- ✅ Swift 6.2 compatible

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/Dependency.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version you want to use

## Usage

### Dependency Injection

```swift
import Dependency

// Define a dependency
extension DependencyValues {
    var myService: MyService {
        get { self[MyServiceKey.self] }
        set { self[MyServiceKey.self] = newValue }
    }
}

// Use in your view model
class MyViewModel: ObservableObject {
    @Dependency(\.myService) var myService
}
```

### Event Publisher

```swift
import Dependency

// Define an event
struct MyEvent: AppEvent {
    let data: String
}

// Send events
@Dependency(\.eventPublisher) var eventPublisher
eventPublisher.send(MyEvent(data: "Hello"))

// Observe events
for await event in eventPublisher.values() {
    if let myEvent = event as? MyEvent {
        print(myEvent.data)
    }
}
```

### UserDefaults Client

```swift
import Dependency

@Dependency(\.userDefaultClient) var userDefaults

// Save
userDefaults.set("John", forKey: "userName")

// Retrieve
let name: String? = userDefaults.get("userName")

// Remove
userDefaults.remove("userName")
```

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Swift 6.2+
- Xcode 16.0+

## License

MIT License - See LICENSE file for details

## Author

Your Name - [@your-twitter](https://twitter.com/your-twitter)
