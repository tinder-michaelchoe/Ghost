//
//  CladsUIKitView+Convenience.swift
//  CladsModules
//
//  Convenience initializers for CladsUIKitView and CladsViewController that use default registries.
//  Custom actions are merged into the action registry internally.
//

import CLADS
import UIKit

extension CladsUIKitView {
    /// Initialize with a document using default registries.
    ///
    /// - Parameters:
    ///   - document: The document definition to render
    ///   - customActions: View-specific action closures, keyed by action ID
    ///   - actionDelegate: Delegate for handling custom actions
    ///
    /// Example:
    /// ```swift
    /// let view = CladsUIKitView(document: document)
    ///
    /// // With custom actions
    /// let view = CladsUIKitView(
    ///     document: document,
    ///     customActions: [
    ///         "submitOrder": { params, context in
    ///             await OrderService.submit(orderId)
    ///         }
    ///     ]
    /// )
    /// ```
    public convenience init(
        document: Document.Definition,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil
    ) {
        // Merge custom actions into the registry
        let registry = ActionRegistry.default.merging(customActions: customActions)

        self.init(
            document: document,
            actionRegistry: registry,
            componentRegistry: .default,
            rendererRegistry: .default,
            actionDelegate: actionDelegate
        )
    }

    /// Initialize from a JSON string using default registries.
    public convenience init?(
        jsonString: String,
        customActions: [String: ActionClosure] = [:],
        actionDelegate: CladsActionDelegate? = nil
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
            rendererRegistry: .default,
            actionDelegate: actionDelegate
        )
    }
}

// MARK: - CladsViewController Convenience

extension CladsViewController {
    /// Initialize with a document using default registries.
    public convenience init(document: Document.Definition) {
        self.init(
            document: document,
            actionRegistry: .default,
            componentRegistry: .default,
            rendererRegistry: .default
        )
    }

    /// Initialize from a JSON string using default registries.
    public convenience init?(jsonString: String) {
        self.init(
            jsonString: jsonString,
            actionRegistry: .default,
            componentRegistry: .default,
            rendererRegistry: .default
        )
    }
}
