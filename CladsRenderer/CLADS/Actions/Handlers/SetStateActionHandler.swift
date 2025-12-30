//
//  SetStateActionHandler.swift
//  CladsRendererFramework
//

import Foundation

/// Handler for the "setState" action
/// Updates a value in the state store
public struct SetStateActionHandler: ActionHandler, Initializable {
    public static let actionType = "setState"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let path = parameters.string("path") else {
            print("SetStateActionHandler: Missing 'path' parameter")
            return
        }

        let newValue: Any

        // Check if value is an expression
        if let valueDict = parameters.dictionary("value"),
           let expr = valueDict["$expr"] as? String {
            newValue = context.stateStore.evaluate(expression: expr)
        } else if let value = parameters.raw["value"] {
            newValue = value
        } else {
            print("SetStateActionHandler: Missing 'value' parameter")
            return
        }

        context.stateStore.set(path, value: newValue)
    }
}
