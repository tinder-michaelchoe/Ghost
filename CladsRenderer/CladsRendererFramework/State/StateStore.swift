//
//  StateStore.swift
//  CladsRendererFramework
//

import Foundation
import Combine
import SwiftUI

// MARK: - State Reading Protocol

/// Protocol for reading state values, used by ExpressionEvaluator.
/// This allows the evaluator to work with any state source.
public protocol StateValueReading {
    /// Get a value at the given keypath
    func getValue(_ keypath: String) -> Any?

    /// Get an array at the given keypath
    func getArray(_ keypath: String) -> [Any]?

    /// Check if an array contains a value
    func arrayContains(_ keypath: String, value: Any) -> Bool

    /// Get the count of an array
    func getArrayCount(_ keypath: String) -> Int
}

// MARK: - State Change Callback

/// Callback invoked when state changes
public typealias StateChangeCallback = (_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void

// MARK: - State Store

/// Observable state store for documents with dirty tracking
@MainActor
public final class StateStore: ObservableObject {
    @Published private var values: [String: Any] = [:]

    // MARK: - Dirty Tracking

    /// Paths that have been modified since last sync
    private var dirtyPaths: Set<String> = []

    /// Whether any paths are dirty
    public var hasDirtyPaths: Bool { !dirtyPaths.isEmpty }

    // MARK: - Callbacks

    /// Registered callbacks for state changes
    private var changeCallbacks: [UUID: StateChangeCallback] = [:]

    public init() {}

    /// Initialize with state from a document
    public func initialize(from state: [String: Document.StateValue]?) {
        guard let state = state else { return }
        for (key, value) in state {
            values[key] = unwrap(value)
        }
    }

    /// Get a value at the given keypath
    public func get(_ keypath: String) -> Any? {
        // Support nested keypaths like "user.name"
        let components = keypath.split(separator: ".").map(String.init)
        var current: Any? = values

        for component in components {
            if let dict = current as? [String: Any] {
                current = dict[component]
            } else if components.count == 1 {
                return values[keypath]
            } else {
                return nil
            }
        }
        return current
    }

    /// Get a value as a specific type
    public func get<T>(_ keypath: String, as type: T.Type = T.self) -> T? {
        return get(keypath) as? T
    }

    /// Set a value at the given keypath
    public func set(_ keypath: String, value: Any?) {
        let oldValue = get(keypath)
        let components = keypath.split(separator: ".").map(String.init)

        if components.count == 1 {
            values[keypath] = value
        } else {
            // Handle nested keypaths
            setNested(components: components, value: value, in: &values)
        }

        // Track dirty paths
        markDirty(keypath)

        // Notify callbacks
        notifyCallbacks(path: keypath, oldValue: oldValue, newValue: value)
    }

    // MARK: - Dirty Path Tracking

    /// Mark a path as dirty (modified)
    private func markDirty(_ path: String) {
        dirtyPaths.insert(path)

        // Also mark parent paths as dirty
        // e.g., if "user.profile.name" changes, "user.profile" and "user" are also affected
        let components = path.split(separator: ".").map(String.init)
        var parentPath = ""
        for component in components.dropLast() {
            if !parentPath.isEmpty {
                parentPath += "."
            }
            parentPath += component
            dirtyPaths.insert(parentPath)
        }
    }

    /// Consume and return all dirty paths, clearing the dirty set
    public func consumeDirtyPaths() -> Set<String> {
        let paths = dirtyPaths
        dirtyPaths = []
        return paths
    }

    /// Check if a specific path is dirty
    public func isDirty(_ path: String) -> Bool {
        // Direct match
        if dirtyPaths.contains(path) { return true }

        // Check if any child path is dirty
        for dirtyPath in dirtyPaths {
            if dirtyPath.hasPrefix(path + ".") { return true }
        }

        return false
    }

    /// Clear all dirty paths without consuming
    public func clearDirtyPaths() {
        dirtyPaths = []
    }

    // MARK: - Callbacks

    /// Register a callback for state changes
    /// Returns an ID that can be used to unregister
    @discardableResult
    public func onStateChange(_ callback: @escaping StateChangeCallback) -> UUID {
        let id = UUID()
        changeCallbacks[id] = callback
        return id
    }

    /// Unregister a callback
    public func removeStateChangeCallback(_ id: UUID) {
        changeCallbacks.removeValue(forKey: id)
    }

    /// Remove all callbacks
    public func removeAllCallbacks() {
        changeCallbacks.removeAll()
    }

    private func notifyCallbacks(path: String, oldValue: Any?, newValue: Any?) {
        for callback in changeCallbacks.values {
            callback(path, oldValue, newValue)
        }
    }

    // MARK: - State Snapshot

    /// Get a snapshot of the current state
    public func snapshot() -> [String: Any] {
        return values
    }

    /// Restore state from a snapshot
    public func restore(from snapshot: [String: Any]) {
        values = snapshot
        // Mark all paths as dirty after restore
        for key in snapshot.keys {
            markDirty(key)
        }
    }

    // MARK: - Typed State Support

    /// Get state as a typed Codable object
    public func getTyped<T: Decodable>(_ type: T.Type = T.self) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: values, options: [])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    /// Get a nested value as a typed Codable object
    public func getTyped<T: Decodable>(_ keypath: String, as type: T.Type = T.self) -> T? {
        guard let value = get(keypath) else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    /// Set state from a typed Codable object
    public func setTyped<T: Encodable>(_ value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for (key, val) in dict {
                    set(key, value: val)
                }
            }
        } catch {
            // Silently fail if encoding fails
        }
    }

    /// Set a nested value from a typed Codable object
    public func setTyped<T: Encodable>(_ keypath: String, value: T) {
        do {
            let data = try JSONEncoder().encode(value)
            let jsonValue = try JSONSerialization.jsonObject(with: data, options: [])
            set(keypath, value: jsonValue)
        } catch {
            // Silently fail if encoding fails
        }
    }

    private func setNested(components: [String], value: Any?, in dict: inout [String: Any]) {
        guard !components.isEmpty else { return }

        if components.count == 1 {
            dict[components[0]] = value
        } else {
            let key = components[0]
            var nested = dict[key] as? [String: Any] ?? [:]
            setNested(components: Array(components.dropFirst()), value: value, in: &nested)
            dict[key] = nested
        }
    }

    /// Get a binding for two-way data binding
    public func binding(for keypath: String) -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.get(keypath) as? String ?? ""
            },
            set: { [weak self] newValue in
                self?.set(keypath, value: newValue)
            }
        )
    }

    /// Evaluate an expression with state interpolation
    /// Supports expressions like "${count} + 1", "Hello ${name}", or ternary expressions
    public func evaluate(expression: String) -> Any {
        let evaluator = ExpressionEvaluator()
        return evaluator.evaluate(expression, using: self)
    }

    /// Interpolate template strings like "You pressed ${count} times"
    /// Also handles ternary expressions like "${isOn ? 'ON' : 'OFF'}"
    public func interpolate(_ template: String) -> String {
        let evaluator = ExpressionEvaluator()
        return evaluator.interpolate(template, using: self)
    }

    private func unwrap(_ stateValue: Document.StateValue) -> Any {
        switch stateValue {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        }
    }
}

// MARK: - StateValueReading Conformance

extension StateStore: StateValueReading {
    public func getValue(_ keypath: String) -> Any? {
        get(keypath)
    }

    public func getArray(_ keypath: String) -> [Any]? {
        get(keypath) as? [Any]
    }

    public func arrayContains(_ keypath: String, value: Any) -> Bool {
        guard let array = getArray(keypath) else { return false }
        return array.contains { item in
            if let itemStr = item as? String, let valueStr = value as? String {
                return itemStr == valueStr
            }
            if let itemInt = item as? Int, let valueInt = value as? Int {
                return itemInt == valueInt
            }
            return false
        }
    }

    public func getArrayCount(_ keypath: String) -> Int {
        getArray(keypath)?.count ?? 0
    }
}
