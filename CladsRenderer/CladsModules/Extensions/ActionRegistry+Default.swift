//
//  ActionRegistry+Default.swift
//  CladsModules
//
//  Provides the default ActionRegistry with all built-in actions registered.
//

import CLADS

extension ActionRegistry {
    /// A registry with all built-in actions registered
    public static var `default`: ActionRegistry {
        let registry = ActionRegistry()
        registry.registerBuiltInActions()
        return registry
    }

    /// Register all built-in action handlers
    public func registerBuiltInActions() {
        register(DismissActionHandler())
        register(SetStateActionHandler())
        register(ShowAlertActionHandler())
        register(SequenceActionHandler())
        register(NavigateActionHandler())

        // Array action handlers
        register(AppendToArrayActionHandler())
        register(RemoveFromArrayActionHandler())
        register(ToggleInArrayActionHandler())
        register(SetArrayItemActionHandler())
        register(ClearArrayActionHandler())
    }
}
