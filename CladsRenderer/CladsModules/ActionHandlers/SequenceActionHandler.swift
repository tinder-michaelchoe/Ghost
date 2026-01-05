//
//  SequenceActionHandler.swift
//  CladsModules
//

import CLADS
import Foundation

/// Handler for the "sequence" action
/// Executes multiple actions in order
public struct SequenceActionHandler: ActionHandler {
    public static let actionType = "sequence"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let steps = parameters.array("steps") else {
            print("SequenceActionHandler: Missing 'steps' parameter")
            return
        }

        for step in steps {
            guard let actionType = step["type"] as? String else {
                print("SequenceActionHandler: Step missing 'type'")
                continue
            }

            let stepParams = ActionParameters(raw: step)
            await context.executeAction(type: actionType, parameters: stepParams)
        }
    }
}
