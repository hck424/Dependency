//
//  EventPublisher.swift
//  Dependency
//
//  Created on 2/10/26.
//

import Foundation

// MARK: - AppEvent Protocol
public protocol AppEvent: Sendable { }

// MARK: - EventPublisher
public struct EventPublisher: Sendable {
    public let values: @Sendable () -> AsyncStream<any AppEvent>
    public let send: @Sendable (any AppEvent) -> Void
    
    public init(
        values: @Sendable @escaping () -> AsyncStream<any AppEvent>,
        send: @Sendable @escaping (any AppEvent) -> Void
    ) {
        self.values = values
        self.send = send
    }
}

// MARK: - EventCenter
public actor EventCenter {
    public static let shared = EventCenter()
    
    private var continuations: [UUID: AsyncStream<any AppEvent>.Continuation] = [:]
    
    public init() {}
    
    public func stream() -> AsyncStream<any AppEvent> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
            continuations[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.remove(id)
                }
            }
        }
    }
    
    public func send(_ event: any AppEvent) {
        for (_, c) in continuations {
            c.yield(event)
        }
    }
    
    private func remove(_ id: UUID) {
        continuations[id] = nil
    }
}

// MARK: - Factory methods
public extension EventPublisher {
    static func live(center: EventCenter) -> Self {
        .init(
            values: {
                AsyncStream { continuation in
                    let task = Task {
                        for await event in await center.stream() {
                            continuation.yield(event)
                        }
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            send: { event in
                Task { await center.send(event) }
            }
        )
    }
    
    static func noop() -> Self {
        .init(values: { AsyncStream { $0.finish() } }, send: { _ in })
    }
}

// MARK: - Dependency Integration
private enum EventPublisherDependencyKey: DependencyKey {
    static var liveValue: EventPublisher {
        .live(center: .shared)
    }
    
    static var testValue: EventPublisher {
        .live(center: .shared)
    }
    
    typealias Value = EventPublisher
}

extension DependencyValues {
    public var eventPublisher: EventPublisher {
        get { self[EventPublisherDependencyKey.self] }
        set { self[EventPublisherDependencyKey.self] = newValue }
    }
}

