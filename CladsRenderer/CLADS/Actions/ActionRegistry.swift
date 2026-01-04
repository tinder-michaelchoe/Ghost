//
//  ActionRegistry.swift
//  CladsRendererFramework
//

import Foundation

/// Registry for action handlers
/// Allows registering custom action types that can be executed by the renderer
public final class ActionRegistry: @unchecked Sendable {

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

    /// Register an action handler by type
    /// - Parameter handlerType: The handler type to instantiate and register
    public func register<T: ActionHandler>(_ handlerType: T.Type) where T: ActionHandler & Initializable {
        register(handlerType.init())
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

}

/// Protocol for types that can be initialized with no arguments
public protocol Initializable {
    init()
}
