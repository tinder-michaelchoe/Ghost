//
//  KeypathAccessor.swift
//  CLADS
//
//  Handles keypath parsing and nested value access for state storage.
//  Extracted from StateStore for clarity and testability.
//

import Foundation

// MARK: - Keypath Accessor

/// Parses and accesses nested values using keypath notation.
///
/// Supports:
/// - Simple keys: `"count"`
/// - Nested keys: `"user.name"`
/// - Array indices: `"items[0]"` or `"items.0"`
/// - Mixed: `"users[0].name"`, `"data.items[2].value"`
///
/// Example:
/// ```swift
/// let accessor = KeypathAccessor()
/// var values: [String: Any] = ["user": ["name": "John"]]
///
/// // Reading
/// let name = accessor.get("user.name", from: values) // "John"
///
/// // Writing
/// accessor.set("user.age", value: 30, in: &values)
/// ```
public struct KeypathAccessor {

    public init() {}

    // MARK: - Path Components

    enum PathComponent: Equatable {
        case key(String)
        case index(Int)
    }

    // MARK: - Reading

    /// Get a value at the given keypath from a dictionary.
    ///
    /// - Parameters:
    ///   - keypath: The path to the value (e.g., "user.name", "items[0]")
    ///   - values: The dictionary to read from
    /// - Returns: The value at the keypath, or nil if not found
    public func get(_ keypath: String, from values: [String: Any]) -> Any? {
        let components = parseKeypath(keypath)
        var current: Any? = values

        for component in components {
            guard current != nil else { return nil }

            switch component {
            case .key(let key):
                if let dict = current as? [String: Any] {
                    current = dict[key]
                } else {
                    return nil
                }
            case .index(let idx):
                if let array = current as? [Any], idx >= 0, idx < array.count {
                    current = array[idx]
                } else {
                    return nil
                }
            }
        }
        return current
    }

    // MARK: - Writing

    /// Set a value at the given keypath in a dictionary.
    ///
    /// Creates intermediate dictionaries/arrays as needed.
    ///
    /// - Parameters:
    ///   - keypath: The path to set (e.g., "user.name", "items[0]")
    ///   - value: The value to set (nil to remove)
    ///   - values: The dictionary to modify
    public func set(_ keypath: String, value: Any?, in values: inout [String: Any]) {
        let components = parseKeypath(keypath)

        if components.count == 1 {
            // Simple key
            if case .key(let key) = components[0] {
                values[key] = value
            }
        } else {
            // Handle nested keypaths with array support
            setNestedValue(components: components, value: value, in: &values)
        }
    }

    // MARK: - Keypath Parsing

    /// Parse a keypath like "users[0].name" into components.
    ///
    /// - Parameter keypath: The keypath string
    /// - Returns: Array of path components (keys and indices)
    func parseKeypath(_ keypath: String) -> [PathComponent] {
        var components: [PathComponent] = []
        var current = keypath[...]

        while !current.isEmpty {
            // Skip leading dots
            if current.first == "." {
                current = current.dropFirst()
                continue
            }

            // Check for array index [n]
            if current.first == "[" {
                if let closeBracket = current.firstIndex(of: "]") {
                    let indexStr = current[current.index(after: current.startIndex)..<closeBracket]
                    if let index = Int(indexStr) {
                        components.append(.index(index))
                    }
                    current = current[current.index(after: closeBracket)...]
                    continue
                }
            }

            // Otherwise it's a key - read until . or [
            var keyEnd = current.startIndex
            while keyEnd < current.endIndex && current[keyEnd] != "." && current[keyEnd] != "[" {
                keyEnd = current.index(after: keyEnd)
            }

            let key = String(current[..<keyEnd])
            if !key.isEmpty {
                // Check if key is a pure integer (for items.0 syntax)
                if let index = Int(key) {
                    components.append(.index(index))
                } else {
                    components.append(.key(key))
                }
            }
            current = current[keyEnd...]
        }

        return components
    }

    // MARK: - Nested Value Setting

    /// Recursively sets a value at a nested path with array support.
    private func setNestedValue(components: [PathComponent], value: Any?, in container: inout [String: Any]) {
        guard let first = components.first else { return }
        let remaining = Array(components.dropFirst())

        switch first {
        case .key(let key):
            if remaining.isEmpty {
                // Final component - set the value
                container[key] = value
            } else {
                // Need to recurse
                if case .index = remaining.first {
                    // Next is an array index
                    var array = container[key] as? [Any] ?? []
                    setNestedArrayValue(components: remaining, value: value, in: &array)
                    container[key] = array
                } else {
                    // Next is a key
                    var nested = container[key] as? [String: Any] ?? [:]
                    setNestedValue(components: remaining, value: value, in: &nested)
                    container[key] = nested
                }
            }

        case .index:
            // This shouldn't happen at top level of dict, but handle gracefully
            break
        }
    }

    /// Recursively sets a value within an array.
    private func setNestedArrayValue(components: [PathComponent], value: Any?, in array: inout [Any]) {
        guard let first = components.first else { return }
        let remaining = Array(components.dropFirst())

        guard case .index(let idx) = first else { return }

        // Ensure array is large enough
        while array.count <= idx {
            array.append(NSNull())
        }

        if remaining.isEmpty {
            // Final component - set the value
            array[idx] = value ?? NSNull()
        } else {
            // Need to recurse
            if case .index = remaining.first {
                // Next is also an array index
                var nested = array[idx] as? [Any] ?? []
                setNestedArrayValue(components: remaining, value: value, in: &nested)
                array[idx] = nested
            } else {
                // Next is a key
                var nested = array[idx] as? [String: Any] ?? [:]
                setNestedValue(components: remaining, value: value, in: &nested)
                array[idx] = nested
            }
        }
    }
}

// MARK: - Convenience Extensions

extension KeypathAccessor {
    /// Get a value as a specific type.
    public func get<T>(_ keypath: String, from values: [String: Any], as type: T.Type = T.self) -> T? {
        return get(keypath, from: values) as? T
    }

    /// Get an array at the given keypath.
    public func getArray(_ keypath: String, from values: [String: Any]) -> [Any]? {
        return get(keypath, from: values) as? [Any]
    }

    /// Extract the root key from a keypath.
    ///
    /// - Parameter keypath: The full keypath
    /// - Returns: The first key component, or nil if keypath starts with an index
    public func rootKey(of keypath: String) -> String? {
        let components = parseKeypath(keypath)
        if case .key(let key) = components.first {
            return key
        }
        return nil
    }

    /// Get parent path components for dirty tracking.
    ///
    /// For "user.profile.name", returns ["user", "user.profile"]
    public func parentPaths(of keypath: String) -> [String] {
        let parts = keypath.split(separator: ".").map(String.init)
        var parents: [String] = []
        var current = ""

        for part in parts.dropLast() {
            if !current.isEmpty {
                current += "."
            }
            current += part
            parents.append(current)
        }

        return parents
    }
}
