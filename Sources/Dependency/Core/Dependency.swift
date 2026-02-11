// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftUI
import Combine

// 1. 의존성 키 프로토콜
public protocol DependencyKey {
    associatedtype Value: Sendable
    static var liveValue: Value { get }
    static var testValue: Value { get }
}

// 2. 의존성 저장소
public struct DependencyValues: Sendable {
    nonisolated(unsafe) private static var current = DependencyValues()
    
    // Task-local 저장소 (Swift Concurrency 전파 핵심)
    @TaskLocal public static var localValues: DependencyValues?

    private var storage: [ObjectIdentifier: any Sendable] = [:]

    public static var currentValues: DependencyValues {
        localValues ?? current
    }
    
    public init() {}

    public subscript<K: DependencyKey>(key: K.Type) -> K.Value {
        //get { storage[ObjectIdentifier(key)] as? K.Value ?? K.liveValue }
        get {
            if let value = storage[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return Self.useTestDefaults ? K.testValue : K.liveValue
        }
        set { storage[ObjectIdentifier(key)] = newValue }
    }
}

extension DependencyValues {
    public static var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    public static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    public static var useTestDefaults: Bool {
        return isRunningForPreviews || isRunningTests
    }
}

@propertyWrapper
public struct Dependency<Value>: @unchecked Sendable {
    private let keyPath: KeyPath<DependencyValues, Value>
    
    public var wrappedValue: Value {
        DependencyValues.currentValues[keyPath: keyPath]
    }
    
    public init(_ keyPath: KeyPath<DependencyValues, Value>) {
        self.keyPath = keyPath
    }
}
