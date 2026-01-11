//
//  CustomComponent.swift
//  CLADS
//
//  Protocol and types for custom components that integrate with CLADS.
//  Custom components use the same styling, data binding, and actions as built-in components.
//

import Foundation
import SwiftUI

// MARK: - Custom Component Protocol

/// Protocol for custom components that integrate with CLADS styling and actions.
///
/// Custom components behave identically to built-in components in JSON:
/// - Use `styleId` for styling
/// - Use `data` dictionary for state binding
/// - Use `actions` for interactions
///
/// Example:
/// ```swift
/// struct WeatherCardComponent: CustomComponent {
///     static let typeName = "weatherCard"
///
///     static func makeView(context: CustomComponentContext) -> AnyView {
///         let temp = context.resolveDouble(forKey: "temperature") ?? 0
///         let condition = context.resolveString(forKey: "condition") ?? "Unknown"
///
///         return AnyView(
///             MyWeatherView(temperature: temp, condition: condition)
///                 .applyCladsStyle(context.style)
///                 .applyCladsActions(context.component.actions, context: context)
///         )
///     }
/// }
/// ```
///
/// JSON usage:
/// ```json
/// {
///   "type": "weatherCard",
///   "styleId": "cardStyle",
///   "data": {
///     "temperature": { "type": "binding", "path": "weather.temp" },
///     "condition": { "type": "static", "value": "Sunny" }
///   },
///   "actions": {
///     "onTap": "refreshWeather"
///   }
/// }
/// ```
public protocol CustomComponent {
    /// The component type name used in JSON "type" field
    static var typeName: String { get }

    /// Build the SwiftUI view for this component
    /// - Parameter context: Context providing style, state, and action execution
    /// - Returns: The rendered SwiftUI view wrapped in AnyView
    @MainActor
    static func makeView(context: CustomComponentContext) -> AnyView
}

// MARK: - Custom Component Context

/// Context provided to custom components during rendering.
///
/// Provides access to:
/// - Resolved style (from `styleId`)
/// - State store for data binding
/// - Action execution
/// - Helper methods for resolving data references
@MainActor
public struct CustomComponentContext {
    /// Resolved style for this component
    public let style: IR.Style

    /// State store for reading/writing state
    public let stateStore: StateStore

    /// Action context for executing actions
    public let actionContext: ActionContext

    /// Render tree reference
    public let tree: RenderTree

    /// The original component from the document
    public let component: Document.Component

    // MARK: - Initialization

    public init(
        style: IR.Style,
        stateStore: StateStore,
        actionContext: ActionContext,
        tree: RenderTree,
        component: Document.Component
    ) {
        self.style = style
        self.stateStore = stateStore
        self.actionContext = actionContext
        self.tree = tree
        self.component = component
    }

    // MARK: - Data Resolution

    /// Resolve a data reference to its actual value
    @MainActor
    public func resolveData(_ ref: Document.DataReference?) -> Any? {
        guard let ref = ref else { return nil }

        switch ref.type {
        case .static:
            return ref.value
        case .binding:
            if let template = ref.template {
                return stateStore.interpolate(template)
            } else if let path = ref.path {
                return stateStore.get(path)
            }
            return nil
        case .localBinding:
            // Local bindings use "local." prefix internally
            if let path = ref.path {
                return stateStore.get("local.\(path)")
            }
            return nil
        }
    }

    /// Resolve a data reference to a String
    @MainActor
    public func resolveString(_ ref: Document.DataReference?) -> String? {
        guard let value = resolveData(ref) else { return nil }
        if let string = value as? String { return string }
        return String(describing: value)
    }

    /// Resolve a data reference to a Double
    @MainActor
    public func resolveDouble(_ ref: Document.DataReference?) -> Double? {
        guard let value = resolveData(ref) else { return nil }
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let string = value as? String { return Double(string) }
        return nil
    }

    /// Resolve a data reference to an Int
    @MainActor
    public func resolveInt(_ ref: Document.DataReference?) -> Int? {
        guard let value = resolveData(ref) else { return nil }
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let string = value as? String { return Int(string) }
        return nil
    }

    /// Resolve a data reference to a Bool
    @MainActor
    public func resolveBool(_ ref: Document.DataReference?) -> Bool? {
        guard let value = resolveData(ref) else { return nil }
        if let bool = value as? Bool { return bool }
        if let int = value as? Int { return int != 0 }
        if let string = value as? String { return string.lowercased() == "true" }
        return nil
    }

    /// Get a data reference from the data dictionary by key
    public func dataRef(forKey key: String) -> Document.DataReference? {
        component.data?[key]
    }

    /// Resolve a value from the customData dictionary by key
    @MainActor
    public func resolveData(forKey key: String) -> Any? {
        resolveData(dataRef(forKey: key))
    }

    /// Resolve a String from the customData dictionary by key
    @MainActor
    public func resolveString(forKey key: String) -> String? {
        resolveString(dataRef(forKey: key))
    }

    /// Resolve a Double from the customData dictionary by key
    @MainActor
    public func resolveDouble(forKey key: String) -> Double? {
        resolveDouble(dataRef(forKey: key))
    }

    /// Resolve an Int from the customData dictionary by key
    @MainActor
    public func resolveInt(forKey key: String) -> Int? {
        resolveInt(dataRef(forKey: key))
    }

    /// Resolve a Bool from the customData dictionary by key
    @MainActor
    public func resolveBool(forKey key: String) -> Bool? {
        resolveBool(dataRef(forKey: key))
    }

    // MARK: - Action Execution

    /// Execute an action by reference
    @MainActor
    public func executeAction(_ actionBinding: Document.Component.ActionBinding?) async {
        guard let binding = actionBinding else { return }

        switch binding {
        case .reference(let actionId):
            await actionContext.executeAction(id: actionId)
        case .inline(let action):
            // Execute inline action directly
            await actionContext.executeAction(action)
        }
    }
}

// MARK: - Custom Component Registry

/// Registry for custom components.
///
/// Maps component type names to their implementations for resolution.
public final class CustomComponentRegistry: @unchecked Sendable {
    private var components: [String: any CustomComponent.Type] = [:]
    private let queue = DispatchQueue(label: "com.clads.customComponentRegistry", attributes: .concurrent)

    public init() {}

    /// Register a custom component type
    public func register<T: CustomComponent>(_ componentType: T.Type) {
        queue.sync(flags: .barrier) {
            self.components[T.typeName] = componentType
        }
    }

    /// Register multiple custom component types
    public func register(_ componentTypes: [any CustomComponent.Type]) {
        queue.sync(flags: .barrier) {
            for type in componentTypes {
                self.components[type.typeName] = type
            }
        }
    }

    /// Check if a component type is registered
    public func isRegistered(_ typeName: String) -> Bool {
        var result = false
        queue.sync {
            result = components[typeName] != nil
        }
        return result
    }

    /// Get a registered component type
    public func componentType(for typeName: String) -> (any CustomComponent.Type)? {
        var result: (any CustomComponent.Type)?
        queue.sync {
            result = components[typeName]
        }
        return result
    }

    /// Get all registered type names
    public var registeredTypeNames: [String] {
        var result: [String] = []
        queue.sync {
            result = Array(components.keys)
        }
        return result
    }
}

