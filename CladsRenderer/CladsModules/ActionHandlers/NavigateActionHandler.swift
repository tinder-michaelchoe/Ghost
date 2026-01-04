//
//  NavigateActionHandler.swift
//  CladsModules
//

import CLADS
import Foundation

/// Handler for the "navigate" action
/// Navigates to another view
public struct NavigateActionHandler: ActionHandler, Initializable {
    public static let actionType = "navigate"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let destination = parameters.string("to") else {
            print("NavigateActionHandler: Missing 'to' parameter")
            return
        }

        let presentation: Document.NavigationPresentation?
        if let presentationString = parameters.string("presentation") {
            presentation = Document.NavigationPresentation(rawValue: presentationString)
        } else {
            presentation = nil
        }

        context.navigate(to: destination, presentation: presentation)
    }
}
