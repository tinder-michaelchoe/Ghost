//
//  CladsRendererView+Convenience.swift
//  CladsModules
//
//  Convenience initializers for CladsRendererView that use default registries.
//

import CLADS
import SwiftUI

extension CladsRendererView {
    /// Initialize with a document using default registries.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - actionDelegate: Delegate for handling custom actions
    ///
    /// Example:
    /// ```swift
    /// CladsRendererView(document: document)
    ///
    /// // With custom actions
    /// CladsRendererView(
    ///     document: document,
    ///     customActions: [
    ///         "submitOrder": { params, context in
    ///             await OrderService.submit(orderId)
    ///         }
    ///     ]
    /// )
    /// ```
    public init(
        document: Document.Definition,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil
    ) {
        self.init(
            document: document,
            actionRegistry: .default,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customActions: customActions,
            actionDelegate: actionDelegate
        )
    }

    /// Initialize from a JSON string using default registries.
    public init?(
        jsonString: String,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        self.init(
            jsonString: jsonString,
            actionRegistry: .default,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customActions: customActions,
            actionDelegate: actionDelegate,
            debugMode: debugMode
        )
    }

    /// Initialize from a Document with optional debug output using default registries.
    public init(
        document: Document.Definition,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool
    ) {
        self.init(
            document: document,
            actionRegistry: .default,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customActions: customActions,
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
        actionDelegate: CladsActionDelegate? = nil,
        debugMode: Bool = false
    ) {
        self.init(
            initialState: initialState,
            onStateChange: onStateChange,
            onAction: onAction,
            actionRegistry: .default,
            componentRegistry: .default,
            swiftuiRendererRegistry: .default,
            customActions: customActions,
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
