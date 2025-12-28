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
    private let actionDefinitions: [String: Document.Action]
    private let registry: ActionRegistry

    /// Callback to dismiss the current view
    public var dismissHandler: (() -> Void)?

    /// Callback to present an alert
    public var alertHandler: ((AlertConfiguration) -> Void)?

    /// Callback for navigation
    public var navigationHandler: ((String, Document.NavigationPresentation?) -> Void)?

    public init(
        stateStore: StateStore,
        actionDefinitions: [String: Document.Action],
        registry: ActionRegistry = .shared
    ) {
        self.stateStore = stateStore
        self.actionDefinitions = actionDefinitions
        self.registry = registry
    }

    // MARK: - ActionExecutionContext

    /// Execute an action by its ID (looks up in document's action definitions)
    public func executeAction(id actionId: String) async {
        guard let action = actionDefinitions[actionId] else {
            print("ActionContext: Unknown action '\(actionId)'")
            return
        }

        await executeAction(action)
    }

    /// Execute a typed Action directly
    public func executeAction(_ action: Document.Action) async {
        switch action {
        case .dismiss:
            dismiss()

        case .setState(let setStateAction):
            executeSetState(setStateAction)

        case .showAlert(let showAlertAction):
            executeShowAlert(showAlertAction)

        case .navigate(let navigateAction):
            navigate(to: navigateAction.destination, presentation: navigateAction.presentation)

        case .sequence(let sequenceAction):
            for step in sequenceAction.steps {
                await executeAction(step)
            }

        case .custom(let customAction):
            // Fall back to registry-based handling for custom actions
            let parameters = ActionParameters(raw: customAction.parameters.mapValues { stateValueToAny($0) })
            await executeAction(type: customAction.type, parameters: parameters)
        }
    }

    /// Execute an action directly by type and parameters (for custom actions and legacy support)
    public func executeAction(type actionType: String, parameters: ActionParameters) async {
        guard let handler = registry.handler(for: actionType) else {
            print("ActionContext: No handler registered for action type '\(actionType)'")
            return
        }

        await handler.execute(parameters: parameters, context: self)
    }

    // MARK: - Action Execution Helpers

    private func executeSetState(_ action: Document.SetStateAction) {
        let value: Any
        switch action.value {
        case .literal(let stateValue):
            value = stateValueToAny(stateValue)
        case .expression(let expr):
            // For now, just store the expression string - expression evaluation is separate
            value = expr
        }
        stateStore.set(action.path, value: value)
    }

    private func executeShowAlert(_ action: Document.ShowAlertAction) {
        let message: String?
        if let msgContent = action.message {
            switch msgContent {
            case .static(let str):
                message = str
            case .template(let template):
                // Template interpolation would happen here
                message = template
            }
        } else {
            message = nil
        }

        let buttons = (action.buttons ?? []).map { button in
            AlertConfiguration.Button(
                label: button.label,
                style: button.style ?? .default,
                action: button.action
            )
        }

        let config = AlertConfiguration(
            title: action.title,
            message: message,
            buttons: buttons.isEmpty ? [AlertConfiguration.Button(label: "OK", style: .default, action: nil)] : buttons,
            onButtonTap: { [weak self] actionId in
                if let actionId = actionId {
                    self?.execute(actionId)
                }
            }
        )

        presentAlert(config)
    }

    private func stateValueToAny(_ value: Document.StateValue) -> Any {
        switch value {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        }
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
    public func navigate(to destination: String, presentation: Document.NavigationPresentation?) {
        navigationHandler?(destination, presentation)
    }

    // MARK: - Convenience Execution

    /// Execute an action binding (either reference or inline)
    public func execute(_ binding: Document.Component.ActionBinding) {
        Task {
            switch binding {
            case .reference(let actionId):
                await executeAction(id: actionId)
            case .inline(let action):
                await executeAction(action)
            }
        }
    }

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
        public let style: Document.AlertButtonStyle
        public let action: String?

        public init(label: String, style: Document.AlertButtonStyle, action: String?) {
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
