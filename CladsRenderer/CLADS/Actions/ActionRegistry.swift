//
//  ActionRegistry.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Closure Action Handler

/// An ActionHandler that wraps a closure.
/// This allows closures to be stored uniformly with other ActionHandler types.
public struct ClosureActionHandler: ActionHandler {
    public let actionType: String
    private let closure: ActionClosure

    public static var actionType: String { "" } // Not used, instance property is used instead

    public init(actionType: String, closure: @escaping ActionClosure) {
        self.actionType = actionType
        self.closure = closure
    }

    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        await closure(parameters, context)
    }
}

// MARK: - Action Registry

/// Registry for action handlers
/// Allows registering custom action types that can be executed by the renderer
public final class ActionRegistry: @unchecked Sendable {

    private var handlers: [String: any ActionHandler] = [:]
    private let queue = DispatchQueue(label: "com.cladsrenderer.actionregistry")

    public init() {}

    /// Create a copy of this registry with additional custom action closures merged in.
    ///
    /// - Parameter customActions: Dictionary of action closures keyed by action type
    /// - Returns: A new ActionRegistry containing all handlers from this registry plus the custom actions
    public func merging(customActions: [String: ActionClosure]) -> ActionRegistry {
        let merged = ActionRegistry()
        queue.sync {
            // Copy existing handlers
            merged.handlers = self.handlers

            // Wrap closures as ClosureActionHandler and add them
            for (actionType, closure) in customActions {
                merged.handlers[actionType] = ClosureActionHandler(actionType: actionType, closure: closure)
            }
        }
        return merged
    }

    /// Register an action handler
    /// - Parameter handler: The handler instance to register
    public func register(_ handler: any ActionHandler) {
        queue.sync {
            handlers[type(of: handler).actionType] = handler
        }
    }


    /// Register an action closure directly
    /// - Parameters:
    ///   - actionType: The action type identifier
    ///   - closure: The closure to execute for this action
    public func registerClosure(_ actionType: String, closure: @escaping ActionClosure) {
        queue.sync {
            handlers[actionType] = ClosureActionHandler(actionType: actionType, closure: closure)
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

}

