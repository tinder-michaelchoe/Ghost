//
//  ActionExecutor.swift
//  CladsRendererFramework
//

import Foundation
import Combine
import SwiftUI
import UIKit

/// Context for action execution, providing access to state and navigation
@MainActor
public final class ActionContext: ObservableObject, ActionExecutionContext {
    public let stateStore: StateStore
    private let actionDefinitions: [String: [String: Any]]
    private let registry: ActionRegistry

    /// Callback to dismiss the current view
    public var dismissHandler: (() -> Void)?

    /// Callback to present an alert
    public var alertHandler: ((AlertConfiguration) -> Void)?

    /// Callback for navigation
    public var navigationHandler: ((String, NavigationPresentation?) -> Void)?

    public init(
        stateStore: StateStore,
        actionDefinitions: [String: [String: Any]],
        registry: ActionRegistry = .shared
    ) {
        self.stateStore = stateStore
        self.actionDefinitions = actionDefinitions
        self.registry = registry
    }

    // MARK: - ActionExecutionContext

    /// Execute an action by its ID (looks up in document's action definitions)
    public func executeAction(id actionId: String) async {
        guard let actionDef = actionDefinitions[actionId] else {
            print("ActionContext: Unknown action '\(actionId)'")
            return
        }

        guard let actionType = actionDef["type"] as? String else {
            print("ActionContext: Action '\(actionId)' missing 'type'")
            return
        }

        let parameters = ActionParameters(raw: actionDef)
        await executeAction(type: actionType, parameters: parameters)
    }

    /// Execute an action directly by type and parameters
    public func executeAction(type actionType: String, parameters: ActionParameters) async {
        guard let handler = registry.handler(for: actionType) else {
            print("ActionContext: No handler registered for action type '\(actionType)'")
            return
        }

        await handler.execute(parameters: parameters, context: self)
    }

    /// Dismiss the current view
    public func dismiss() {
        dismissHandler?()
    }

    /// Present an alert
    public func presentAlert(_ config: AlertConfiguration) {
        alertHandler?(config)
    }

    /// Navigate to another view
    public func navigate(to destination: String, presentation: NavigationPresentation?) {
        navigationHandler?(destination, presentation)
    }

    // MARK: - Legacy Support

    /// Execute an action by its ID (convenience for button taps, etc.)
    public func execute(_ actionId: String) {
        Task {
            await executeAction(id: actionId)
        }
    }
}

/// Configuration for presenting an alert
public struct AlertConfiguration {
    public let title: String
    public let message: String?
    public let buttons: [Button]
    public let onButtonTap: ((String?) -> Void)?

    public struct Button {
        public let label: String
        public let style: AlertButtonStyle
        public let action: String?

        public init(label: String, style: AlertButtonStyle, action: String?) {
            self.label = label
            self.style = style
            self.action = action
        }
    }

    public init(
        title: String,
        message: String?,
        buttons: [Button],
        onButtonTap: ((String?) -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
        self.onButtonTap = onButtonTap
    }
}

// MARK: - UIKit Alert Presenter

/// Helper to present UIAlertController from SwiftUI
public struct AlertPresenter {

    @MainActor
    public static func present(_ config: AlertConfiguration) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        let alert = UIAlertController(
            title: config.title,
            message: config.message,
            preferredStyle: .alert
        )

        for button in config.buttons {
            let style: UIAlertAction.Style
            switch button.style {
            case .default: style = .default
            case .cancel: style = .cancel
            case .destructive: style = .destructive
            }

            let action = UIAlertAction(title: button.label, style: style) { _ in
                config.onButtonTap?(button.action)
            }
            alert.addAction(action)
        }

        topController.present(alert, animated: true)
    }
}
