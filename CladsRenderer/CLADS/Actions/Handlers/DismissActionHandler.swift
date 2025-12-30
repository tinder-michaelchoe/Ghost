//
//  DismissActionHandler.swift
//  CladsRendererFramework
//

import Foundation

/// Handler for the "dismiss" action
/// Dismisses the current view
public struct DismissActionHandler: ActionHandler, Initializable {
    public static let actionType = "dismiss"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        context.dismiss()
    }
}
