# Dependency

A lightweight, Swift 6.2 compatible dependency injection and event system for Apple platforms.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- ✅ **Simple Dependency Injection** - Property wrapper-based DI system
- ✅ **Global Event Publisher** - Type-safe async event streaming
- ✅ **UserDefaults Client** - Type-safe UserDefaults wrapper with App Group support
- ✅ **Swift Concurrency** - Built with async/await and actors
- ✅ **Sendable** - Thread-safe by design
- ✅ **Test Support** - Automatic test/preview mode detection
- ✅ **Cross-Platform** - iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/Dependency.git", from: "1.0.0")
]
```

Or in Xcode:
1. **File → Add Package Dependencies**
2. Enter the repository URL
3. Select version `1.0.0` or later

## Usage

### 🔧 Dependency Injection

#### 1. Define a Dependency Key

```swift
import Dependency

// Define your service
struct APIService: Sendable {
    func fetchData() async -> String {
        "Hello, World!"
    }
}

// Create a dependency key
private enum APIServiceKey: DependencyKey {
    static var liveValue: APIService {
        APIService()
    }
    
    static var testValue: APIService {
        APIService() // Return mock for tests
    }
}

// Extend DependencyValues
extension DependencyValues {
    var apiService: APIService {
        get { self[APIServiceKey.self] }
        set { self[APIServiceKey.self] = newValue }
    }
}
```

#### 2. Use in Your Code

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Dependency(\.apiService) var apiService
    @Published var data: String = ""
    
    func loadData() async {
        data = await apiService.fetchData()
    }
}
```

### 📡 Event Publisher

Send and receive type-safe events across your app.

#### 1. Define Events

```swift
import Dependency

struct UserLoggedInEvent: AppEvent {
    let userId: String
}

struct ToastEvent: AppEvent {
    let message: String
}
```

#### 2. Send Events

```swift
class LoginViewModel: ObservableObject {
    @Dependency(\.eventPublisher) var eventPublisher
    
    func login() {
        // Login logic...
        eventPublisher.send(UserLoggedInEvent(userId: "12345"))
    }
}
```

#### 3. Observe Events

```swift
@MainActor
class AppViewModel: ObservableObject {
    @Dependency(\.eventPublisher) var eventPublisher
    @Published var currentUserId: String?
    
    func observeEvents() async {
        for await event in eventPublisher.values() {
            if let loginEvent = event as? UserLoggedInEvent {
                currentUserId = loginEvent.userId
            }
        }
    }
}

// In your view
struct AppView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        Text("User ID: \(viewModel.currentUserId ?? "None")")
            .task {
                await viewModel.observeEvents()
            }
    }
}
```

#### 4. Extension Pattern (Recommended)

```swift
extension EventPublisher {
    func showToast(_ message: String) {
        send(ToastEvent(message: message))
    }
    
    func userLoggedIn(_ userId: String) {
        send(UserLoggedInEvent(userId: userId))
    }
}

// Usage
eventPublisher.showToast("Welcome!")
eventPublisher.userLoggedIn("12345")
```

### 💾 UserDefaults Client

Type-safe UserDefaults with automatic App Group support.

#### 1. Define Keys

```swift
import Dependency

enum UserDefaultsKey: String, UserDefaultKey {
    case userName
    case isLoggedIn
    case lastLoginDate
}
```

#### 2. Use in Your Code

```swift
class SettingsViewModel: ObservableObject {
    @Dependency(\.userDefaults) var userDefaults
    
    func saveUser(name: String) {
        userDefaults.setValue(name, forKey: UserDefaultsKey.userName)
    }
    
    func loadUserName() -> String {
        userDefaults.string(forKey: UserDefaultsKey.userName)
    }
    
    func saveLoginState(_ isLoggedIn: Bool) {
        userDefaults.setValue(isLoggedIn, forKey: UserDefaultsKey.isLoggedIn)
    }
    
    func isUserLoggedIn() -> Bool {
        userDefaults.bool(forKey: UserDefaultsKey.isLoggedIn)
    }
    
    func clearUserData() {
        userDefaults.remove(forKey: UserDefaultsKey.userName)
        userDefaults.remove(forKey: UserDefaultsKey.isLoggedIn)
    }
}
```

#### Available Methods

```swift
// Read
userDefaults.bool(forKey: .isLoggedIn) -> Bool
userDefaults.string(forKey: .userName) -> String
userDefaults.int(forKey: .age) -> Int
userDefaults.float(forKey: .score) -> Float
userDefaults.data(forKey: .profileData) -> Data?
userDefaults.object(forKey: .settings) -> Any?

// Write
userDefaults.setValue(value, forKey: key)

// Delete
userDefaults.remove(forKey: key)
```

## Advanced Examples

### Complete App Example

```swift
import SwiftUI
import Dependency

// Events
struct NavigationEvent: AppEvent {
    let screenId: Int
}

struct ToastEvent: AppEvent {
    let message: String
}

// App ViewModel
@MainActor
class AppViewModel: ObservableObject {
    @Dependency(\.eventPublisher) var eventPublisher
    
    @Published var toastMessage: String?
    @Published var navigationId: Int?
    
    func observeEvents() async {
        for await event in eventPublisher.values() {
            if let toast = event as? ToastEvent {
                toastMessage = toast.message
                try? await Task.sleep(for: .seconds(2))
                toastMessage = nil
            } else if let nav = event as? NavigationEvent {
                navigationId = nav.screenId
            }
        }
    }
}

// App View
struct MyApp: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        NavigationStack {
            ContentView()
        }
        .overlay {
            if let message = viewModel.toastMessage {
                ToastView(message: message)
            }
        }
        .task {
            await viewModel.observeEvents()
        }
    }
}

// Child View
struct ContentView: View {
    @Dependency(\.eventPublisher) var eventPublisher
    
    var body: some View {
        Button("Show Toast") {
            eventPublisher.send(ToastEvent(message: "Hello!"))
        }
    }
}
```

## Testing

The framework automatically detects test and preview environments:

```swift
// In tests or previews, testValue is used automatically
private enum MockAPIKey: DependencyKey {
    static var liveValue: APIService {
        RealAPIService()
    }
    
    static var testValue: APIService {
        MockAPIService() // Automatically used in tests
    }
}
```

### Manual Dependency Override

```swift
// For specific tests
var customDependencies = DependencyValues()
customDependencies.apiService = CustomMockService()
```

## Architecture

### Dependency Injection
- Uses `@TaskLocal` for Swift Concurrency propagation
- Automatically switches between live/test values
- Thread-safe with `Sendable` conformance

### Event Publisher
- Built on `AsyncStream` for backpressure handling
- Actor-based `EventCenter` for thread safety
- Buffering policy: newest 10 events
- Automatic cleanup on stream termination

### UserDefaults Client
- Automatic App Group support via Bundle ID
- Falls back to `.standard` if App Group unavailable
- Type-safe keys via `UserDefaultKey` protocol

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Swift 6.2+
- Xcode 16.0+

## App Group Configuration

For App Group support (extensions, widgets), ensure your app has:

1. **Capabilities** → **App Groups** enabled
2. App Group ID: `group.{your.bundle.identifier}`

Example:
- Bundle ID: `com.example.myapp`
- App Group: `group.com.example.myapp`

## Examples

Check the `/Examples` folder for complete working examples:
- `EventPublisherExample.swift` - Event system with toast and loading
- `UserDefaultClientExample.swift` - UserDefaults usage

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Author

김학철 - [GitHub](https://github.com/your-username)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

---

**Made with ❤️ using Swift 6.2**
