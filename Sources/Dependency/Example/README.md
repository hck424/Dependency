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

#### 1. Define Your Service

```swift
import Dependency

// Create your service
protocol MyServiceProtocol {
    func doSomething() -> String
}

struct MyService: MyServiceProtocol {
    func doSomething() -> String {
        return "Hello from MyService"
    }
}
```

#### 2. Conform to DependencyKey

```swift
extension MyService: DependencyKey {
    public static let liveValue: MyService = MyService()
    public static let testValue: MyService = MyService()
}
```

#### 3. Add to DependencyValues

```swift
extension DependencyValues {
    var myService: MyService {
        get { self[MyService.self] }
        set { self[MyService.self] = newValue }
    }
}
```

#### 4. Use in Your ViewModel

```swift
class MyViewModel: ObservableObject {
    @Dependency(\.myService) var myService
    
    func performAction() {
        let result = myService.doSomething()
        print(result) // "Hello from MyService"
    }
}
```


### Event Publisher

The Event Publisher provides a powerful way to communicate between different parts of your app using events.

#### 1. Define Your Events

```swift
import Dependency

// Define custom events
struct NavigationEvent: AppEvent {
    let id: Int
}

struct ToastItem: AppEvent {
    var message: String
    var position: Alignment = .bottom
    var duration: Double = 2.5
}

struct AppLoading: AppEvent {
    var isLoading: Bool
}

struct UserInfo: Codable, AppEvent {
    var name: String
    var age: Int
}
```

#### 2. Send Events

```swift
class ViewModel: ObservableObject {
    @Dependency(\.eventPublisher) var eventPublisher
    
    func sendNavigationEvent() {
        eventPublisher.send(NavigationEvent(id: 1))
    }
    
    func showToast() {
        eventPublisher.send(ToastItem(message: "Hello World!"))
    }
    
    func showLoading() {
        eventPublisher.send(AppLoading(isLoading: true))
    }
}
```

#### 3. Extend EventPublisher (Optional)

```swift
extension EventPublisher {
    func showToast(_ message: String, position: Alignment = .bottom) {
        self.send(ToastItem(message: message, position: position))
    }
    
    func showLoading(_ isLoading: Bool) {
        self.send(AppLoading(isLoading: isLoading))
    }
}

// Usage
eventPublisher.showToast("Success!")
eventPublisher.showLoading(true)
```

#### 4. Observe Events

```swift
@MainActor
class AppViewModel: ObservableObject {
    @Dependency(\.eventPublisher) var eventPublisher
    
    @Published var toastItem: ToastItem?
    @Published var isLoading: Bool = false
    
    func observeEvents() async {
        for await event in eventPublisher.values() {
            await handleEvent(event)
        }
    }
    
    func handleEvent(_ event: AppEvent) async {
        if let toast = event as? ToastItem {
            self.toastItem = toast
            try? await Task.sleep(for: .seconds(toast.duration))
            self.toastItem = nil
        }
        else if let loading = event as? AppLoading {
            self.isLoading = loading.isLoading
        }
    }
}

struct AppView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        VStack {
            // Your content
        }
        .task {
            await viewModel.observeEvents()
        }
        .overlay {
            if let toast = viewModel.toastItem {
                Text(toast.message)
                    .padding()
                    .background(.black.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
```


### UserDefaults Client

Type-safe UserDefaults storage with key-based access.

#### 1. Define Your Keys

```swift
import Dependency

enum UserKeys: String, UserDefaultKey {
    case userName
    case userAge
    case isLoggedIn
    case lastLoginDate
    case pushToken
}
```

#### 2. Use in ViewModel

```swift
final class UserViewModel: ObservableObject {
    @Dependency(\.userDefaults) var userDefaults
    
    // String values
    func getUserName() -> String {
        userDefaults.string(UserKeys.userName)
    }
    
    func setUserName(_ value: String) {
        userDefaults.setValue(value, UserKeys.userName)
    }
    
    // Int values
    func getUserAge() -> Int {
        userDefaults.int(UserKeys.userAge)
    }
    
    func setUserAge(_ value: Int) {
        userDefaults.setValue(value, UserKeys.userAge)
    }
    
    // Bool values
    func getIsLoggedIn() -> Bool {
        userDefaults.bool(UserKeys.isLoggedIn)
    }
    
    func setIsLoggedIn(_ value: Bool) {
        userDefaults.setValue(value, UserKeys.isLoggedIn)
    }
    
    // Data values (for Codable types)
    func saveLastLoginDate() {
        let data = try? JSONEncoder().encode(Date())
        if let data = data {
            userDefaults.setValue(data, UserKeys.lastLoginDate)
        }
    }
    
    func getLastLoginDate() -> Date? {
        guard let data = userDefaults.data(UserKeys.lastLoginDate) else { return nil }
        return try? JSONDecoder().decode(Date.self, from: data)
    }
    
    // Remove values
    func logout() {
        userDefaults.remove(UserKeys.userName)
        userDefaults.remove(UserKeys.userAge)
        userDefaults.remove(UserKeys.isLoggedIn)
    }
}
```

#### 3. Use in SwiftUI View

```swift
struct UserProfileView: View {
    @State private var viewModel = UserViewModel()
    @State private var nameInput = ""
    @State private var ageInput = ""
    
    var body: some View {
        Form {
            Section("User Info") {
                TextField("Name", text: $nameInput)
                    .onSubmit {
                        viewModel.setUserName(nameInput)
                    }
                
                TextField("Age", text: $ageInput)
                    .keyboardType(.numberPad)
                    .onSubmit {
                        if let age = Int(ageInput) {
                            viewModel.setUserAge(age)
                        }
                    }
            }
            
            Section("Saved Info") {
                LabeledContent("Name", value: viewModel.getUserName())
                LabeledContent("Age", value: "\(viewModel.getUserAge())")
                LabeledContent("Logged In", value: viewModel.getIsLoggedIn() ? "Yes" : "No")
            }
            
            Section {
                Button("Login") {
                    viewModel.setIsLoggedIn(true)
                    viewModel.saveLastLoginDate()
                }
                
                Button("Logout") {
                    viewModel.logout()
                }
            }
        }
        .onAppear {
            nameInput = viewModel.getUserName()
            ageInput = "\(viewModel.getUserAge())"
        }
    }
}
```

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Swift 6.2+
- Xcode 16.0+

## License

MIT License - See LICENSE file for details

## Author

Your Name - [@your-twitter](https://twitter.com/your-twitter)
