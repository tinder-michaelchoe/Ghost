//
//  ActionResolver.swift
//  CladsRendererFramework
//
//  Maps Schema Action types to IR ActionDefinition types.
//

import Foundation

/// Maps Schema `Action` types to IR `ActionDefinition` types.
///
/// This resolver performs a simple 1:1 mapping from the Schema layer (decoded from JSON)
/// to the IR layer (used for execution).
public struct ActionResolver {

    public init() {}

    // MARK: - Public API

    /// Resolves all actions from the document
    /// - Parameter actions: Dictionary of action ID to Action
    /// - Returns: Dictionary of action ID to resolved ActionDefinition
    public func resolveAll(_ actions: [String: Document.Action]?) -> [String: ActionDefinition] {
        guard let actions = actions else { return [:] }

        var resolved: [String: ActionDefinition] = [:]
        for (id, action) in actions {
            resolved[id] = resolve(action)
        }
        return resolved
    }

    /// Resolves a single Action to ActionDefinition
    /// - Parameter action: The schema Action
    /// - Returns: The resolved ActionDefinition
    public func resolve(_ action: Document.Action) -> ActionDefinition {
        switch action {
        case .dismiss:
            return .dismiss

        case .setState(let setStateAction):
            return .setState(
                path: setStateAction.path,
                value: resolveSetValue(setStateAction.value)
            )

        case .toggleState(let toggleStateAction):
            return .toggleState(path: toggleStateAction.path)

        case .showAlert(let showAlertAction):
            return .showAlert(config: AlertActionConfig(
                title: showAlertAction.title,
                message: showAlertAction.message.map(resolveAlertMessage),
                buttons: showAlertAction.buttons?.map(resolveAlertButton) ?? []
            ))

        case .navigate(let navigateAction):
            return .navigate(
                destination: navigateAction.destination,
                presentation: navigateAction.presentation ?? .push
            )

        case .sequence(let sequenceAction):
            return .sequence(steps: sequenceAction.steps.map(resolve))

        case .custom(let customAction):
            return .custom(
                type: customAction.type,
                parameters: customAction.parameters
            )
        }
    }

    // MARK: - Private Helpers

    private func resolveSetValue(_ value: Document.SetValue) -> StateSetValue {
        switch value {
        case .literal(let stateValue):
            return .literal(stateValue)
        case .expression(let expr):
            return .expression(expr)
        }
    }

    private func resolveAlertMessage(_ content: Document.AlertMessageContent) -> AlertMessage {
        switch content {
        case .static(let string):
            return .static(string)
        case .template(let template):
            return .template(template)
        }
    }

    private func resolveAlertButton(_ button: Document.AlertButton) -> AlertButtonConfig {
        AlertButtonConfig(
            label: button.label,
            style: button.style ?? .default,
            action: button.action
        )
    }
}
