//
//  ActionHandler.swift
//  CladsRendererFramework
//

import Foundation

/// Protocol for action handlers that can execute actions
public protocol ActionHandler {
    /// The action type identifier (e.g., "dismiss", "setState", "showAlert")
    static var actionType: String { get }

    /// Execute the action with the given parameters
    /// - Parameters:
    ///   - parameters: The raw parameters from JSON for this action
    ///   - context: The execution context providing access to state and callbacks
    @MainActor
    func execute(parameters: ActionParameters, context: ActionExecutionContext) async
}

/// Parameters passed to an action handler
public struct ActionParameters {
    /// Raw dictionary of parameters from JSON
    public let raw: [String: Any]

    public init(raw: [String: Any]) {
        self.raw = raw
    }

    /// Get a string value
    public func string(_ key: String) -> String? {
        raw[key] as? String
    }

    /// Get an int value
    public func int(_ key: String) -> Int? {
        raw[key] as? Int
    }

    /// Get a bool value
    public func bool(_ key: String) -> Bool? {
        raw[key] as? Bool
    }

    /// Get a nested dictionary
    public func dictionary(_ key: String) -> [String: Any]? {
        raw[key] as? [String: Any]
    }

    /// Get an array of dictionaries
    public func array(_ key: String) -> [[String: Any]]? {
        raw[key] as? [[String: Any]]
    }
}

/// Context provided to action handlers during execution
@MainActor
public protocol ActionExecutionContext: AnyObject {
    /// The state store for reading/writing state
    var stateStore: StateStore { get }

    /// Execute another action by its ID
    func executeAction(id: String) async

    /// Execute an action directly from parameters
    func executeAction(type: String, parameters: ActionParameters) async

    /// Dismiss the current view
    func dismiss()

    /// Present an alert
    func presentAlert(_ config: AlertConfiguration)

    /// Navigate to another view
    func navigate(to destination: String, presentation: Document.NavigationPresentation?)
}
