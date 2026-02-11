//
//  SwiftUIView.swift
//  Dependency
//
//  Created by 김학철 on 2/10/26.
//

import SwiftUI

// MARK: - UserDefaultKey Protocol
public protocol UserDefaultKey: RawRepresentable, Hashable, Sendable where RawValue == String {}

// MARK: - UserDefaultClient
public struct UserDefaultClient: Sendable {
    public var bool: @Sendable (_ forKey: any UserDefaultKey) -> Bool = { _ in false }
    public var string: @Sendable (_ forKey: any UserDefaultKey) -> String = { _ in "" }
    public var object: @Sendable (_ forKey: any UserDefaultKey) -> Any? = { _ in nil }
    public var int: @Sendable (_ forKey: any UserDefaultKey) -> Int = { _ in 0 }
    public var float: @Sendable (_ forKey: any UserDefaultKey) -> Float = { _ in 0.0 }
    public var data: @Sendable (_ forKey: any UserDefaultKey) -> Data? = { _ in nil }
    public var remove: @Sendable (_ forKey: any UserDefaultKey) -> Void
    
    public var setValue: @Sendable (Any, _ forKey: any UserDefaultKey) -> Void
}

extension UserDefaultClient: DependencyKey {
    public static let liveValue: UserDefaultClient = Self.live()
    public static let testValue: UserDefaultClient = Self.live()
    
    nonisolated(unsafe) private static let storage: UserDefaults = {
        // Bundle ID를 그대로 사용하여 App Group suite name 생성
        // 예: kr.co.company.appname → group.kr.co.company.appname
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            let suiteName = "group.\(bundleIdentifier)"
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }()
    
    public static func live(storage: UserDefaults? = nil) -> Self {
        nonisolated(unsafe) let userDefaults = storage ?? Self.storage
        
        return Self(
            bool: { userDefaults.bool(forKey: $0.rawValue) },
            string: { userDefaults.string(forKey: $0.rawValue) ?? "" },
            object: { userDefaults.object(forKey: $0.rawValue) },
            int: { userDefaults.integer(forKey: $0.rawValue) },
            float: { userDefaults.float(forKey: $0.rawValue) },
            data: { userDefaults.data(forKey: $0.rawValue) },
            remove: { key in
                userDefaults.removeObject(forKey: key.rawValue)
            },
            setValue: { value, key in
                userDefaults.set(value, forKey: key.rawValue)
            }
        )
    }
}

extension DependencyValues {
    public var userDefaults: UserDefaultClient {
        get { self[UserDefaultClient.self] }
        set { self[UserDefaultClient.self] = newValue }
    }
}
