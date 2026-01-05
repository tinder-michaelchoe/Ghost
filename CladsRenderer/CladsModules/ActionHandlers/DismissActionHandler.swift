//
//  DismissActionHandler.swift
//  CladsModules
//

import CLADS
import Foundation

/// Handler for the "dismiss" action
/// Dismisses the current view
public struct DismissActionHandler: ActionHandler {
    public static let actionType = "dismiss"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        context.dismiss()
    }
}
