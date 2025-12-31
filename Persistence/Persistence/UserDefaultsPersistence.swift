//
//  UserDefaultsPersistence.swift
//  Persistence
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - UserDefaults Persistence

/// A PersistenceService implementation backed by UserDefaults.
///
/// This implementation:
/// - Uses JSON encoding for Codable values
/// - Optimizes primitive types (Int, String, Bool, Double) to use native UserDefaults storage
/// - Is thread-safe through UserDefaults' internal synchronization
/// - Supports namespacing through key prefixes
public final class UserDefaultsPersistence: PersistenceService, @unchecked Sendable {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let namespace: String?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    /// Creates a UserDefaults-backed persistence service.
    /// - Parameter defaults: The UserDefaults instance to use. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.namespace = nil
    }

    /// Creates a namespaced persistence service.
    private init(defaults: UserDefaults, namespace: String) {
        self.defaults = defaults
        self.namespace = namespace
    }

    // MARK: - PersistenceService

    public func get<T: Codable & Sendable>(_ key: PersistenceKey<T>) -> T {
        let fullKey = prefixedKey(key.name)

        // Optimize for primitive types
        if T.self == Int.self {
            guard defaults.object(forKey: fullKey) != nil else {
                return key.defaultValue
            }
            return defaults.integer(forKey: fullKey) as! T
        }

        if T.self == String.self {
            guard let value = defaults.string(forKey: fullKey) else {
                return key.defaultValue
            }
            return value as! T
        }

        if T.self == Bool.self {
            guard defaults.object(forKey: fullKey) != nil else {
                return key.defaultValue
            }
            return defaults.bool(forKey: fullKey) as! T
        }

        if T.self == Double.self {
            guard defaults.object(forKey: fullKey) != nil else {
                return key.defaultValue
            }
            return defaults.double(forKey: fullKey) as! T
        }

        if T.self == Data.self {
            guard let value = defaults.data(forKey: fullKey) else {
                return key.defaultValue
            }
            return value as! T
        }

        // For all other Codable types, use JSON encoding
        guard let data = defaults.data(forKey: fullKey) else {
            return key.defaultValue
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return key.defaultValue
        }
    }

    public func set<T: Codable & Sendable>(_ key: PersistenceKey<T>, value: T) {
        let fullKey = prefixedKey(key.name)

        // Optimize for primitive types
        if let intValue = value as? Int {
            defaults.set(intValue, forKey: fullKey)
            return
        }

        if let stringValue = value as? String {
            defaults.set(stringValue, forKey: fullKey)
            return
        }

        if let boolValue = value as? Bool {
            defaults.set(boolValue, forKey: fullKey)
            return
        }

        if let doubleValue = value as? Double {
            defaults.set(doubleValue, forKey: fullKey)
            return
        }

        if let dataValue = value as? Data {
            defaults.set(dataValue, forKey: fullKey)
            return
        }

        // For all other Codable types, use JSON encoding
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: fullKey)
        } catch {
            // Silently fail - in production you might want to log this
        }
    }

    public func remove<T: Codable & Sendable>(_ key: PersistenceKey<T>) {
        let fullKey = prefixedKey(key.name)
        defaults.removeObject(forKey: fullKey)
    }

    public func exists<T: Codable & Sendable>(_ key: PersistenceKey<T>) -> Bool {
        let fullKey = prefixedKey(key.name)
        return defaults.object(forKey: fullKey) != nil
    }

    public func scoped(namespace: String) -> PersistenceService {
        let newNamespace: String
        if let existing = self.namespace {
            newNamespace = "\(existing).\(namespace)"
        } else {
            newNamespace = namespace
        }
        return UserDefaultsPersistence(defaults: defaults, namespace: newNamespace)
    }

    // MARK: - Private

    private func prefixedKey(_ key: String) -> String {
        if let namespace = namespace {
            return "\(namespace).\(key)"
        }
        return key
    }
}
