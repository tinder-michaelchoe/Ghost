//
//  ShowAlertActionHandler.swift
//  CladsModules
//

import CLADS
import Foundation

/// Handler for the "showAlert" action
/// Presents a UIAlertController with the specified configuration
public struct ShowAlertActionHandler: ActionHandler, Initializable {
    public static let actionType = "showAlert"

    public init() {}

    @MainActor
    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        let title = resolveText(parameters.raw["title"], context: context) ?? "Alert"
        let message = resolveText(parameters.raw["message"], context: context)

        var buttons: [AlertConfiguration.Button] = []

        if let buttonArray = parameters.array("buttons") {
            for buttonDict in buttonArray {
                let label = buttonDict["label"] as? String ?? "OK"
                let styleString = buttonDict["style"] as? String ?? "default"
                let style: Document.AlertButtonStyle
                switch styleString {
                case "cancel": style = .cancel
                case "destructive": style = .destructive
                default: style = .default
                }
                let action = buttonDict["action"] as? String

                buttons.append(AlertConfiguration.Button(
                    label: label,
                    style: style,
                    action: action
                ))
            }
        }

        if buttons.isEmpty {
            buttons = [AlertConfiguration.Button(label: "OK", style: Document.AlertButtonStyle.default, action: nil)]
        }

        let config = AlertConfiguration(
            title: title,
            message: message,
            buttons: buttons,
            onButtonTap: { actionId in
                if let actionId = actionId {
                    Task { @MainActor in
                        await context.executeAction(id: actionId)
                    }
                }
            }
        )

        context.presentAlert(config)
    }

    @MainActor
    private func resolveText(_ value: Any?, context: ActionExecutionContext) -> String? {
        guard let value = value else { return nil }

        // If it's a simple string, return it
        if let string = value as? String {
            return string
        }

        // If it's a dictionary with type "binding" and template
        if let dict = value as? [String: Any],
           let type = dict["type"] as? String,
           type == "binding",
           let template = dict["template"] as? String {
            return context.stateStore.interpolate(template)
        }

        return nil
    }
}
