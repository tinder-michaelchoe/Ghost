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

    /// Custom action closures injected at view creation time
    private let customActions: [String: ActionClosure]

    /// Alert presenter for showing alerts (injectable for testing)
    private let alertPresenter: AlertPresenting

    /// Delegate for handling custom actions
    public weak var actionDelegate: CladsActionDelegate?

    /// Callback to dismiss the current view
    public var dismissHandler: (() -> Void)?

    /// Callback to present an alert (legacy - prefer alertPresenter)
    public var alertHandler: ((AlertConfiguration) -> Void)?

    /// Callback for navigation
    public var navigationHandler: ((String, Document.NavigationPresentation?) -> Void)?

    public init(
        stateStore: StateStore,
        actionDefinitions: [String: Document.Action],
        registry: ActionRegistry,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil,
        alertPresenter: AlertPresenting = UIKitAlertPresenter()
    ) {
        self.stateStore = stateStore
        self.actionDefinitions = actionDefinitions
        self.registry = registry
        self.customActions = customActions
        self.actionDelegate = actionDelegate
        self.alertPresenter = alertPresenter
    }

    // MARK: - ActionExecutionContext

    /// Execute an action by its ID.
    ///
    /// Resolution order:
    /// 1. Custom action closures (injected at view creation)
    /// 2. Action delegate
    /// 3. Document action definitions
    public func executeAction(id actionId: String) async {
        // 1. Check custom action closures first
        if let closure = customActions[actionId] {
            await closure(ActionParameters(raw: [:]), self)
            return
        }

        // 2. Check delegate
        if let delegate = actionDelegate {
            let handled = await delegate.cladsRenderer(
                handleAction: actionId,
                parameters: ActionParameters(raw: [:]),
                context: self
            )
            if handled { return }
        }

        // 3. Fall back to document action definitions
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

        case .toggleState(let toggleStateAction):
            executeToggleState(toggleStateAction)

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

    /// Execute an action directly by type and parameters.
    ///
    /// Resolution order:
    /// 1. Custom action closures (injected at view creation)
    /// 2. Action delegate
    /// 3. Action registry (global handlers)
    public func executeAction(type actionType: String, parameters: ActionParameters) async {
        // 1. Check custom action closures first
        if let closure = customActions[actionType] {
            await closure(parameters, self)
            return
        }

        // 2. Check delegate
        if let delegate = actionDelegate {
            let handled = await delegate.cladsRenderer(
                handleAction: actionType,
                parameters: parameters,
                context: self
            )
            if handled { return }
        }

        // 3. Fall back to registry
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
            value = stateStore.evaluate(expression: expr)
        }
        stateStore.set(action.path, value: value)
    }

    private func executeToggleState(_ action: Document.ToggleStateAction) {
        let currentValue = stateStore.get(action.path) as? Bool ?? false
        stateStore.set(action.path, value: !currentValue)
    }

    private func executeShowAlert(_ action: Document.ShowAlertAction) {
        let message: String?
        if let msgContent = action.message {
            switch msgContent {
            case .static(let str):
                message = str
            case .template(let template):
                message = stateStore.interpolate(template)
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
        case .arrayValue(let arr): return arr.map { stateValueToAny($0) }
        case .objectValue(let obj): return obj.mapValues { stateValueToAny($0) }
        }
    }

    /// Dismiss the current view
    public func dismiss() {
        dismissHandler?()
    }

    /// Present an alert using the injected alert presenter
    public func presentAlert(_ config: AlertConfiguration) {
        // Use legacy handler if set, otherwise use injected presenter
        if let handler = alertHandler {
            handler(config)
        } else {
            alertPresenter.present(config)
        }
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

// MARK: - Alert Presenting Protocol

/// Protocol for presenting alerts, enabling dependency injection for testing.
///
/// Example test usage:
/// ```swift
/// class MockAlertPresenter: AlertPresenting {
///     var presentedAlerts: [AlertConfiguration] = []
///     func present(_ config: AlertConfiguration) {
///         presentedAlerts.append(config)
///     }
/// }
///
/// let mockPresenter = MockAlertPresenter()
/// let context = ActionContext(stateStore: store, alertPresenter: mockPresenter, ...)
/// // ... trigger action ...
/// XCTAssertEqual(mockPresenter.presentedAlerts.count, 1)
/// ```
public protocol AlertPresenting: Sendable {
    @MainActor
    func present(_ config: AlertConfiguration)
}

// MARK: - UIKit Alert Presenter

/// Default UIKit implementation of AlertPresenting.
/// Uses UIAlertController to present alerts.
public struct UIKitAlertPresenter: AlertPresenting {

    public init() {}

    @MainActor
    public func present(_ config: AlertConfiguration) {
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

// MARK: - Legacy Support

/// Legacy static interface for backward compatibility.
/// Prefer using UIKitAlertPresenter instance for new code.
public enum AlertPresenter {
    @MainActor
    public static func present(_ config: AlertConfiguration) {
        UIKitAlertPresenter().present(config)
    }
}
