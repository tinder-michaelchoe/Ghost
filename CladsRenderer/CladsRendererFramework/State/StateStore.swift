//
//  StateStore.swift
//  CladsRendererFramework
//

import Foundation
import Combine
import SwiftUI

/// Observable state store for documents
@MainActor
public final class StateStore: ObservableObject {
    @Published private var values: [String: Any] = [:]

    public init() {}

    /// Initialize with state from a document
    public func initialize(from state: [String: StateValue]?) {
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
        let components = keypath.split(separator: ".").map(String.init)

        if components.count == 1 {
            values[keypath] = value
        } else {
            // Handle nested keypaths
            setNested(components: components, value: value, in: &values)
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
    /// Supports expressions like "${count} + 1" or "Hello ${name}"
    public func evaluate(expression: String) -> Any {
        // Check if it's a simple arithmetic expression
        if expression.contains("+") || expression.contains("-") {
            return evaluateArithmetic(expression)
        }

        // Otherwise, just interpolate
        return interpolate(expression)
    }

    /// Interpolate template strings like "You pressed ${count} times"
    public func interpolate(_ template: String) -> String {
        var result = template
        let pattern = #"\$\{([^}]+)\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return template
        }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        // Process matches in reverse to maintain string indices
        for match in matches.reversed() {
            guard let range = Range(match.range, in: template),
                  let keypathRange = Range(match.range(at: 1), in: template) else {
                continue
            }

            let keypath = String(template[keypathRange])
            let value = get(keypath)
            let replacement = stringValue(from: value)
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }

    private func evaluateArithmetic(_ expression: String) -> Any {
        // Simple arithmetic: "${count} + 1"
        let interpolated = interpolate(expression)

        // Try to evaluate as simple addition/subtraction
        let components = interpolated.components(separatedBy: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        if components.count == 2,
           let left = Int(components[0]),
           let right = Int(components[1]) {
            return left + right
        }

        let subComponents = interpolated.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        if subComponents.count == 2,
           let left = Int(subComponents[0]),
           let right = Int(subComponents[1]) {
            return left - right
        }

        return interpolated
    }

    private func stringValue(from value: Any?) -> String {
        switch value {
        case let int as Int: return String(int)
        case let double as Double: return String(double)
        case let string as String: return string
        case let bool as Bool: return String(bool)
        case nil: return ""
        default: return String(describing: value)
        }
    }

    private func unwrap(_ stateValue: StateValue) -> Any {
        switch stateValue {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        }
    }
}
