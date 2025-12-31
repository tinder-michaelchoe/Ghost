//
//  PersistenceService.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation

// MARK: - Persistence Key

/// A type-safe key for persisted values.
///
/// Use this to define keys with their associated value types and defaults:
/// ```swift
/// extension PersistenceKey where Value == Int {
///     static let selectedLocationIndex = PersistenceKey("weather.selectedLocationIndex", default: 0)
/// }
/// ```
public struct PersistenceKey<Value: Codable>: Sendable where Value: Sendable {

    /// The string identifier for this key
    public let name: String

    /// The default value returned when no value is stored
    public let defaultValue: Value

    /// Creates a persistence key.
    /// - Parameters:
    ///   - name: The string identifier (use dot notation for namespacing, e.g., "weather.location")
    ///   - default: The default value when no value exists
    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

// MARK: - Persistence Service

/// A protocol for persisting and retrieving values.
///
/// The implementation is opaque - it could use UserDefaults, CoreData, file storage,
/// or any other persistence mechanism. Consumers should not assume any particular
/// storage backend.
///
/// All operations are synchronous. For large data or slow storage backends,
/// implementations should handle any necessary threading internally.
public protocol PersistenceService: Sendable {

    /// Retrieves a value for the given key.
    /// - Parameter key: The key identifying the value
    /// - Returns: The stored value, or the key's default value if none exists
    func get<T: Codable & Sendable>(_ key: PersistenceKey<T>) -> T

    /// Stores a value for the given key.
    /// - Parameters:
    ///   - key: The key identifying where to store the value
    ///   - value: The value to store
    func set<T: Codable & Sendable>(_ key: PersistenceKey<T>, value: T)

    /// Removes the value for the given key.
    /// - Parameter key: The key whose value should be removed
    func remove<T: Codable & Sendable>(_ key: PersistenceKey<T>)

    /// Checks if a value exists for the given key.
    /// - Parameter key: The key to check
    /// - Returns: true if a value is stored, false otherwise
    func exists<T: Codable & Sendable>(_ key: PersistenceKey<T>) -> Bool

    /// Creates a scoped persistence service with a namespace prefix.
    ///
    /// All keys used with the returned service will be prefixed with the namespace.
    /// This is useful for isolating storage between features.
    ///
    /// - Parameter namespace: The prefix to apply to all keys
    /// - Returns: A new persistence service scoped to the namespace
    func scoped(namespace: String) -> PersistenceService
}

// MARK: - Persistence Error

/// Errors that can occur during persistence operations.
public enum PersistenceError: Error, Sendable {
    case encodingFailed(String)
    case decodingFailed(String)
    case storageUnavailable

    public var localizedDescription: String {
        switch self {
        case .encodingFailed(let message):
            return "Failed to encode value: \(message)"
        case .decodingFailed(let message):
            return "Failed to decode value: \(message)"
        case .storageUnavailable:
            return "Storage is unavailable"
        }
    }
}
