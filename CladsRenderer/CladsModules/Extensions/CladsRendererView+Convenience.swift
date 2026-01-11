//
//  CladsRendererView+Convenience.swift
//  CladsModules
//
//  Convenience initializers for CladsRendererView that use default registries.
//  Custom actions and custom components are merged/registered internally.
//

import CLADS
import SwiftUI

extension CladsRendererView {
    /// Initialize with a document using default registries.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - customComponents: Custom component types to register
    ///   - actionDelegate: Delegate for handling custom actions
    ///
    /// Example:
    /// ```swift
    /// CladsRendererView(document: document)
    ///
    /// // With custom actions and components
    /// CladsRendererView(
    ///     document: document,
    ///     customActions: [
    ///         "submitOrder": { params, context in
    ///             await OrderService.submit(orderId)
    ///         }
    ///     ],
    ///     customComponents: [MyCustomComponent.self]
    /// )
    /// ```
    public init(
        document: Document.Definition,
        customActions: [String: ActionClosure] = [:],
        customComponents: [any CustomComponent.Type] = [],
        actionDelegate: CladsActionDelegate? = nil
    ) {
        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            document: document,
            actionRegistry: registry,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customComponents: customComponents,
            actionDelegate: actionDelegate
        )
    }

    /// Initialize from a JSON string using default registries.
    ///
    /// - Parameters:
    ///   - jsonString: JSON string defining the document
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - customComponents: Custom component types to register
    ///   - actionDelegate: Delegate for handling custom actions
    ///   - debugMode: Enable debug output
    ///
    /// Example:
    /// ```swift
    /// CladsRendererView(
    ///     jsonString: myJSON,
    ///     customActions: ["refresh": { _, _ in await refresh() }],
    ///     customComponents: [PhotoComparisonComponent.self]
    /// )
    /// ```
    public init?(
        jsonString: String,
        customActions: [String: ActionClosure] = [:],
        customComponents: [any CustomComponent.Type] = [],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }

        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            document: document,
            actionRegistry: registry,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customComponents: customComponents,
            actionDelegate: actionDelegate,
            debugMode: debugMode
        )
    }

    /// Initialize from a Document with optional debug output using default registries.
    public init(
        document: Document.Definition,
        customActions: [String: ActionClosure] = [:],
        customComponents: [any CustomComponent.Type] = [],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool
    ) {
        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            document: document,
            actionRegistry: registry,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customComponents: customComponents,
            actionDelegate: actionDelegate,
            debugMode: debugMode
        )
    }
}

// MARK: - Binding Configuration Convenience

extension CladsRendererBindingConfiguration {
    /// Initialize with default registries
    public init(
        initialState: State? = nil,
        onStateChange: ((_ path: String, _ oldValue: Any?, _ newValue: Any?) -> Void)? = nil,
        onAction: ((_ actionId: String, _ parameters: [String: Any]) -> Void)? = nil,
        customActions: [String: ActionClosure] = [:],
        customComponents: [any CustomComponent.Type] = [],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            initialState: initialState,
            onStateChange: onStateChange,
            onAction: onAction,
            actionRegistry: registry,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customComponents: customComponents,
            actionDelegate: actionDelegate,
            debugMode: debugMode
        )
    }
}

// MARK: - Binding View Convenience

extension CladsRendererBindingView where State: Codable & Equatable {
    /// Initialize with a document and state binding using default registries.
    public init(
        document: Document.Definition,
        state: Binding<State>
    ) {
        self.init(
            document: document,
            state: state,
            configuration: CladsRendererBindingConfiguration()
        )
    }

    /// Initialize from a JSON string with state binding using default registries.
    public init?(
        jsonString: String,
        state: Binding<State>
    ) {
        guard let document = try? Document.Definition(jsonString: jsonString) else {
            return nil
        }
        self.init(document: document, state: state)
    }
}
