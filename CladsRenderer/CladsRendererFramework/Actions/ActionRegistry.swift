//
//  ActionRegistry.swift
//  CladsRendererFramework
//

import Foundation

/// Registry for action handlers
/// Allows registering custom action types that can be executed by the renderer
public final class ActionRegistry: @unchecked Sendable {

    /// Shared default registry with built-in actions
    public static let shared = ActionRegistry.createDefault()

    private var handlers: [String: any ActionHandler] = [:]
    private let queue = DispatchQueue(label: "com.cladsrenderer.actionregistry")

    public init() {}

    /// Register an action handler
    /// - Parameter handler: The handler instance to register
    public func register(_ handler: any ActionHandler) {
        queue.sync {
            handlers[type(of: handler).actionType] = handler
        }
    }

    /// Get a handler for the given action type
    /// - Parameter actionType: The action type identifier
    /// - Returns: The registered handler, or nil if not found
    public func handler(for actionType: String) -> (any ActionHandler)? {
        queue.sync {
            handlers[actionType]
        }
    }

    /// Check if a handler is registered for the given action type
    public func hasHandler(for actionType: String) -> Bool {
        queue.sync {
            handlers[actionType] != nil
        }
    }

    /// Create a registry with all built-in actions registered
    public static func createDefault() -> ActionRegistry {
        let registry = ActionRegistry()
        registry.registerBuiltInActions()
        return registry
    }

    /// Register all built-in action handlers
    public func registerBuiltInActions() {
        register(DismissActionHandler())
        register(SetStateActionHandler())
        register(ShowAlertActionHandler())
        register(SequenceActionHandler())
        register(NavigateActionHandler())
    }
}
