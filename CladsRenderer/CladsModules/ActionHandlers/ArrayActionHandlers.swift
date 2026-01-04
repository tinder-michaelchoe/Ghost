//
//  ArrayActionHandlers.swift
//  CladsModules
//
//  Action handlers for array manipulation in state.
//

import CLADS
import Foundation

// MARK: - Append To Array

/// Handler for the "appendToArray" action
/// Appends a value to an array in the state store
///
/// Parameters:
/// - `path`: The keypath to the array
/// - `value`: The value to append (can be literal or expression)
///
/// Example JSON:
/// ```json
/// { "type": "appendToArray", "path": "items", "value": "New Item" }
/// { "type": "appendToArray", "path": "items", "value": { "$expr": "${currentItem}" } }
/// ```
public struct AppendToArrayActionHandler: ActionHandler, Initializable {
    public static let actionType = "appendToArray"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let path = parameters.string("path") else {
            print("AppendToArrayActionHandler: Missing 'path' parameter")
            return
        }

        let newValue: Any
        if let valueDict = parameters.dictionary("value"),
           let expr = valueDict["$expr"] as? String {
            newValue = context.stateStore.evaluate(expression: expr)
        } else if let value = parameters.raw["value"] {
            newValue = value
        } else {
            print("AppendToArrayActionHandler: Missing 'value' parameter")
            return
        }

        context.stateStore.appendToArray(path, value: newValue)
    }
}

// MARK: - Remove From Array

/// Handler for the "removeFromArray" action
/// Removes a value or item at index from an array in the state store
///
/// Parameters:
/// - `path`: The keypath to the array
/// - `value`: The value to remove (removes all matching)
/// - `index`: The index to remove at (alternative to value)
///
/// Example JSON:
/// ```json
/// { "type": "removeFromArray", "path": "items", "value": "Item to Remove" }
/// { "type": "removeFromArray", "path": "items", "index": 0 }
/// ```
public struct RemoveFromArrayActionHandler: ActionHandler, Initializable {
    public static let actionType = "removeFromArray"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let path = parameters.string("path") else {
            print("RemoveFromArrayActionHandler: Missing 'path' parameter")
            return
        }

        // Check for index-based removal first
        if let index = parameters.int("index") {
            context.stateStore.removeFromArray(path, at: index)
            return
        }

        // Otherwise, value-based removal
        let valueToRemove: Any
        if let valueDict = parameters.dictionary("value"),
           let expr = valueDict["$expr"] as? String {
            valueToRemove = context.stateStore.evaluate(expression: expr)
        } else if let value = parameters.raw["value"] {
            valueToRemove = value
        } else {
            print("RemoveFromArrayActionHandler: Missing 'value' or 'index' parameter")
            return
        }

        context.stateStore.removeFromArray(path, value: valueToRemove)
    }
}

// MARK: - Toggle In Array

/// Handler for the "toggleInArray" action
/// Adds a value to an array if not present, removes it if present
///
/// Parameters:
/// - `path`: The keypath to the array
/// - `value`: The value to toggle
///
/// Example JSON:
/// ```json
/// { "type": "toggleInArray", "path": "selectedItems", "value": "Item1" }
/// { "type": "toggleInArray", "path": "selectedIds", "value": { "$expr": "${currentId}" } }
/// ```
public struct ToggleInArrayActionHandler: ActionHandler, Initializable {
    public static let actionType = "toggleInArray"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let path = parameters.string("path") else {
            print("ToggleInArrayActionHandler: Missing 'path' parameter")
            return
        }

        let valueToToggle: Any
        if let valueDict = parameters.dictionary("value"),
           let expr = valueDict["$expr"] as? String {
            valueToToggle = context.stateStore.evaluate(expression: expr)
        } else if let value = parameters.raw["value"] {
            valueToToggle = value
        } else {
            print("ToggleInArrayActionHandler: Missing 'value' parameter")
            return
        }

        context.stateStore.toggleInArray(path, value: valueToToggle)
    }
}

// MARK: - Set Array Item

/// Handler for the "setArrayItem" action
/// Sets a value at a specific index in an array
///
/// Parameters:
/// - `path`: The keypath to the array
/// - `index`: The index to set
/// - `value`: The new value
///
/// Example JSON:
/// ```json
/// { "type": "setArrayItem", "path": "items", "index": 0, "value": "Updated Item" }
/// ```
public struct SetArrayItemActionHandler: ActionHandler, Initializable {
    public static let actionType = "setArrayItem"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let path = parameters.string("path") else {
            print("SetArrayItemActionHandler: Missing 'path' parameter")
            return
        }

        guard let index = parameters.int("index") else {
            print("SetArrayItemActionHandler: Missing 'index' parameter")
            return
        }

        let newValue: Any
        if let valueDict = parameters.dictionary("value"),
           let expr = valueDict["$expr"] as? String {
            newValue = context.stateStore.evaluate(expression: expr)
        } else if let value = parameters.raw["value"] {
            newValue = value
        } else {
            print("SetArrayItemActionHandler: Missing 'value' parameter")
            return
        }

        // Use the array index keypath syntax
        context.stateStore.set("\(path)[\(index)]", value: newValue)
    }
}

// MARK: - Clear Array

/// Handler for the "clearArray" action
/// Removes all items from an array
///
/// Parameters:
/// - `path`: The keypath to the array
///
/// Example JSON:
/// ```json
/// { "type": "clearArray", "path": "selectedItems" }
/// ```
public struct ClearArrayActionHandler: ActionHandler, Initializable {
    public static let actionType = "clearArray"

    public init() {}

    public func execute(parameters: ActionParameters, context: ActionExecutionContext) async {
        guard let path = parameters.string("path") else {
            print("ClearArrayActionHandler: Missing 'path' parameter")
            return
        }

        context.stateStore.set(path, value: [Any]())
    }
}
